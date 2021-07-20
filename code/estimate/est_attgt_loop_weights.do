clear all
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_loop_weights", text replace

use "/`here'/external/pscore.dta", clear
drop treat_match
*mvencode weight_match, mv(0)
reshape wide weight_match, i(frame_id_numeric) j(year)
*mvencode weight_match*, mv(0)
duplicates report frame_id_numeric
tempfile weights
save `weights'

use "`here'/temp/analysis_sample.dta"

rename ever_foreign ef
rename ever_foreign_hire efh
rename has_expat_ceo has_expat

gen lnIK = ln(immat_18)
gen lnIK_0 = lnIK
replace lnIK_0 = 0 if immat_18 == 0

replace export_18 = 0 if export_18 == .
gen Qh = sales_18 - export_18
gen lnQh = ln(Qh)
gen lnQhr = lnQ - lnQh

merge m:1 frame_id_numeric using `weights', keep (1 3) nogen
drop if year > 2013
mvencode weight_match*, mv(0)

foreach depvar in TFP_cd lnIK_0 lnQh lnQhr {
	foreach var in foreign_only foreign_hire_only has_expat {
		attgt `depvar', treatment(`var') aggregate(e) pre(5) post(5) reps(20) notyet limitcontrol(foreign == 0) weightprefix(weight_match)
		count if e(sample) == 1
		eststo m`var'`depvar', title("`depvar' `var'")
	}
	
	foreach var in foreign_hire_only has_expat {
		attgt `depvar' if efh, treatment(`var') aggregate(e) pre(5) post(5) reps(20) notyet limitcontrol(foreign == 0) weightprefix(weight_match)
		count if e(sample) == 1
		eststo mh`var'`depvar', title("efh `depvar' `var'")
	}
}

esttab m* using "`here'/output/table_attgt_loop_weights.tex", mtitle b(3) se(3) replace
esttab m* using "`here'/output/table_attgt_loop_weights.txt", mtitle b(3) se(3) replace

log close
