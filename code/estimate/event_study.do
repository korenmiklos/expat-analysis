clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
drop if country == "XX"

local T1 95
local T2 105

foreach X of var only_owner only_manager both {
	egen byte ever_`X' = max(`X'), by(frame_id_numeric cc)
	egen int ft_`X' = min(cond(`X', year, .)), by(originalid cc)
	generate et_`X' = 100 + year - ft_`X'
	forvalues t = `T1'/`T2' {
		generate byte `X'_`t' = (et_`X'==`t')
	}
	* drop t-5 as reference period
	drop `X'_95
	* winsorize
	replace `X'_`T2' = 1 if (time_foreign+100 > `T2') & !missing(time_foreign+100) & ever_`X'
	drop ft_* et_*
}

local dummies frame_id_numeric##year cc##year frame_id_numeric##cc
local treatments only_owner_* only_manager_* both_*
local outcomes export import_capital import_material
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addstat(Mean, r(mean)) addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

local fmode replace

local treatment_type only_owner only_manager both
tempname graph
postfile `graph' b se str20(outcome treatment) t using "`here'/temp/event_study_graph.dta", replace

foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(frame_id_numeric)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/event_study.tex", `fmode' `options' ctitle(`title`sample'')
	local fmode append
	foreach X of var `treatment_type' {
		forval t = `T1' / `T2' {
			capture scalar b_`X'_`t' =  _b[`X'_`t']
			capture scalar se_`X'_`t' =  _se[`X'_`t']
			if _rc {
				scalar b_`X'_`t' = 0
				scalar se_`X'_`t' = 0
			}
			di b_`X'_`t'
			di se_`X'_`t'
			post `graph' (b_`X'_`t') (se_`X'_`t') ("`Y'") ("`X'") (`t')
		}
	}
}

postclose `graph'

use "`here'/temp/event_study_graph.dta", clear

replace t = t - 100

gen lower = b - 1.96 * se
gen upper = b + 1.96 * se

levelsof outcome, local(levels)
foreach outcome of local levels { 
	twoway (rarea lower upper t if outcome == "`outcome'" & treatment == "only_owner", color(red%30)) (line b t if outcome == "`outcome'" & treatment == "only_owner", color(red)) ///
	(rarea lower upper t if outcome == "`outcome'" & treatment == "only_manager", color(blue%30)) (line b t if outcome == "`outcome'" & treatment == "only_manager", color(blue)) ///
	(rarea lower upper t if outcome == "`outcome'" & treatment == "both", color(green%30)) (line b t if outcome == "`outcome'" & treatment == "both", color(green)), ///
	yline(0, lcolor(black) lpattern(dash)) graphregion(color(white)) xtitle("year") legend(order(2 "Only owner" 4 "Only manager" 6 "Both")) title("`outcome'")
	graph export "`here'/output/figure/event_study_`outcome'.png", replace
}
