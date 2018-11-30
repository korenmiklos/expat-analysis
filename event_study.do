local N = Tbefore+Tduring+2

local T1 = Tbefore 
local T2 = Tduring

foreach X in domestic expat {
	gen byte `X'_p_0 = tenure==0 & (`X'==1)
	forval t=1/`T1' {
		gen byte `X'_m_`t' = tenure== -`t' & (`X'==1)
	}
	forval t=1/`T2' {
		gen byte `X'_p_`t' = tenure== `t' & (`X'==1)
	}
	*replace `X'_p_`T2' = tenure>= `T2' & (`X'==1)
}
local X foreign
gen byte `X'_p_0 = tenure_`X'==0
forval t=1/`T1' {
	gen byte `X'_m_`t' = tenure_`X'== -`t'
}
forval t=1/`T2' {
	gen byte `X'_p_`t' = tenure_`X'== `t'
}
*replace `X'_p_`T2' = tenure_`X'>= `T2' 
sort frame_id year

* illustrate window overlap and recoding
l manager_id expat year tenure* if frame_id=="ft10072219"


local Tbefore = Tbefore
local Tafter = Tduring

* keep post event and after observations for estimation of fixed effects, but dummy these out
gen byte post = (after==0) & tenure>Tduring
gen byte post_expat = post & expat

foreach Y of var $outcomes {
	* with firm FE, controls are years more than Tbefore before any event happens
	xtreg `Y' *_m_* *_p_* i.ind_year i.age_cat if $sample_acquisitions & tenure<=Tduring [aw=inverse_weight], i(firm_person) fe vce(cluster id)
	local title : variable label `e(depvar)'

	preserve
	clear
	set obs `N'
	gen t = _n-2-`Tbefore'
	label var t "Time since new manager (year)"

	foreach X in foreign domestic expat  {
		gen `X'_beta=0
		gen `X'_lower=0
		gen `X'_upper=0
		forval t=-`Tbefore'/`Tafter' {
			local tag "`t'"
			if (`t'<0) {
				local tag = -`t'
				local tag  _m_`tag'
			}
			else {
				local tag  _p_`t'
			}
			replace `X'_beta = _b[`X'`tag'] if t==`t'
			replace `X'_lower = `X'_beta-1.69*_se[`X'`tag'] if t==`t'
			replace `X'_upper = `X'_beta+1.69*_se[`X'`tag'] if t==`t'
		}
		label var `X'_beta "`Y'"
		label var `X'_upper "90% CI"
		label var `X'_lower "90% CI"

	}
	label var foreign_beta "Foreign owner"
	label var expat_beta "Expat manager"
	label var domestic_beta "Domestic manager"

	tw (line domestic_beta expat_beta  t if t>=-Tbefore-1 & t<=Tduring, sort), scheme(538w) title(`title') aspect(0.67)
	graph export output/figure/`Y'_event_study.png, replace width(800)
	
	restore

}
