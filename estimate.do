clear all
capture log close
log using output/estimate, text replace

use temp/analysis_sample

*Dinamika
scalar Tbefore = 4
scalar Tduring = 6
scalar Tafter = 4

gen byte analysis_window = (tenure>=-Tbefore-1)&(year-first_exit_year<=Tafter)

local sample_baseline (analysis_window==1)
local sample_manufacturing `sample_baseline' & (manufacturing==1)
local sample_acquisitions `sample_baseline' & (greenfield==0)

local samples baseline manufacturing acquisitions

local outcomes lnL lnKL lnQL exporter
label var lnL "Employment (log)"
label var lnKL "Capital per worker (log)"
label var lnQL "Revenue per worker (log)"
label var exporter "Firm is an exporter (dummy)"

egen person_tag = tag(frame_id manager_id)
egen N = sum(person_tag), by(frame_id)
gen inverse_weight = 1/N

* verify founders are not in analysis sample
foreach X of var during* after* {
	replace `X'=0 if founder==1
}

xtset firm_person year
local i = 1
foreach X of var `outcomes' {
	foreach sample in `samples' {
		* simple, descriptive regressions first, including founders, but not before/after years
		reg `X' foreign expat i.ind_year i.age_cat if `sample_`sample'' & year>=enter_year & year<=first_exit_year [aw=inverse_weight], vce(cluster id)
		do regram output/regression/`sample'_OLS `i' `X'

		xtreg `X' foreign expat i.ind_year i.age_cat if `sample_`sample'' & year>=enter_year & year<=first_exit_year [aw=inverse_weight], i(id) fe vce(cluster id)
		local r2_w = `e(r2_w)'
		do regram output/regression/`sample'_FE `i' `X' R2_within "`r2_w'"

		xtreg `X' foreign during after during_expat after_expat i.ind_year i.age_cat if `sample_`sample'' [aw=inverse_weight], i(firm_person ) fe vce(cluster id)
		local r2_w = `e(r2_w)'
		do regram output/regression/`sample' `i' `X' R2_within "`r2_w'"

		local fname = e(depvar)
		local title : variable label `fname'

		slopegraph, ///
			from(0 0 1 _b[during] 0 0 1 _b[during]+_b[during_expat]) ///
			to(1 _b[during] 2 _b[after] 1 _b[during]+_b[during_expat] 2 _b[after]+_b[after_expat]) ///
			style(p1 p1 p2 p2) ///
			label("Local-during" "Local-after" "Expat-during" "Expat-after" ) ///
			width_test(during after==during during_expat after_expat==during_expat) ///
			star_test(1==1 1==1 during_expat after_expat) ///
			connect(stepstair) ///
			format(scheme(538w) xlabel(none) xtitle("") ytitle("") title(`title') legend(off) aspect(0.67))

		graph export output/figure/`sample'_`fname'_slope.png, width(800) replace
	}
	xtreg `X' foreign during_?? after_?? i.ind_year i.age_cat if `sample_acquisitions' [aw=inverse_weight], i(firm_person ) fe vce(cluster id)
	local r2_w = `e(r2_w)'
	do regram output/regression/acquisitions_change `i' `X' R2_within "`r2_w'"
	do tree_graph

	local i = `i' + 1
}
foreach X of var exporter lnQL {
	local i = 1
	foreach Z of var H_* {
		xtreg `X' foreign during_domestic after_domestic during_expat after_expat during_domestic_`Z' after_domestic_`Z' during_expat_`Z' after_expat_`Z' i.ind_year i.age_cat if `sample_acquisitions' [aw=inverse_weight], i(firm_person ) fe vce(cluster id)
		local r2_w = `e(r2_w)'
		test during_expat_`Z'==during_domestic_`Z'
		local p = `r(p)'	
		do regram output/regression/`X'_heterogeneity `i' `Z' R2_within "`r2_w'" p_value "`p'"
		local i = `i'+1
	}
}

*Szelekció az akvicíziós mintában
xtset firm_person year
areg f1.expat `outcomes' if ever_foreign==1&greenfield!=1, a(industry_year) cluster(frame_id)
do regram output/regression/selection 1 1

keep if ever_foreign==1

foreach X in outcomes sample_acquisitions {
	global `X' ``X''
}
do event_study

log close
