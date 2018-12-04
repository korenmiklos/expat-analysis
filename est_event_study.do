local N = Tbefore+Tduring+2

local T1 = Tbefore 
local T2 = Tduring

foreach X in domestic expat {
	* founders do not enter event study sample, only as controls
	replace `X' = 0 if founder==1
	gen byte `X'_p_0 = tenure==0 & (`X'==1)
	forval t=1/`T1' {
		gen byte `X'_m_`t' = tenure== -`t' & (`X'==1)
	}
	forval t=1/`T2' {
		gen byte `X'_p_`t' = tenure== `t' & (`X'==1)
	}
}
local X foreign
gen byte `X'_p_0 = tenure_`X'==0
forval t=1/`T1' {
	gen byte `X'_m_`t' = tenure_`X'== -`t'
}
forval t=1/`T2' {
	gen byte `X'_p_`t' = tenure_`X'== `t'
}
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

	gen expat_lower = 0
	gen expat_upper = 0
	label var expat_upper "95% CI of difference"
	label var expat_lower "95% CI of difference"
	foreach X in foreign domestic expat  {
		gen `X'_beta=0
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
			if ("`X'"=="expat") {
				matrix V = e(V)
				matrix V_diff = V["expat`tag'", "expat`tag'"] + V["domestic`tag'", "domestic`tag'"] - 2*V["expat`tag'", "domestic`tag'"]
				scalar se_diff = sqrt(V_diff[1,1])
				replace expat_lower = expat_beta-1.96*se_diff if t==`t'
				replace expat_upper = expat_beta+1.96*se_diff if t==`t'
			}
		}
		label var `X'_beta "`Y'"

	}
	label var foreign_beta "Foreign owner"
	label var expat_beta "Expat manager"
	label var domestic_beta "Domestic manager"

	tw 	(rarea expat_lower expat_upper  t if t>=-Tbefore-1 & t<=Tduring, fintensity(inten10) pstyle(p2)) ///
		(line domestic_beta  t if t>=-Tbefore-1 & t<=Tduring, sort pstyle(p1) lwidth(thick)) ///
		(line expat_beta  t if t>=-Tbefore-1 & t<=Tduring, sort pstyle(p2) lwidth(thick)) ///
		, scheme(538w) title(`title') xline(-0.5) aspect(.5) plotregion(style(none)) xsize(16) ysize(8)
	graph export output/figure/`Y'_event_study.png, replace width(1600)
	
	restore

}
