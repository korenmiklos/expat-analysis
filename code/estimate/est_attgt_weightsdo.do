clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_weightsdo", text replace

use "/`here'/external/pscore_docontrol.dta", clear
drop treat_match year_match
*mvencode weight_match, mv(0)
reshape wide weight_match, i(frame_id_numeric) j(year)
*mvencode weight_match*, mv(0)
duplicates report frame_id_numeric
tempfile weights
save `weights'

use "`here'/temp/analysis_sample.dta", clear

rename ever_foreign ef
rename ever_foreign_hire efh
rename has_expat_ceo has_expat

count
count if ef & time_foreign <= 5

merge m:1 frame_id_numeric using `weights', keep (1 3) nogen

drop if year > 2013

*duplicates tag frame_id_numeric weight_match1989, gen(dup)
*replace dup = 1 if dup >=1 & dup != .
*tab dup, miss

mvencode weight_match*, mv(0)

foreach var in foreign_only foreign_hire_only has_expat {
		attgt lnQL lnK lnL exporter lnQ, treatment(`var') aggregate(e) pre(5) post(5) reps(20) notyet limitcontrol(foreign == 0) weightprefix(weight_match)
		count if e(sample) == 1
		eststo m`var', title("`var'")
}

foreach var in foreign_hire_only has_expat {
		attgt lnQL lnK lnL exporter lnQ if efh, treatment(`var') aggregate(e) pre(5) post(5) reps(20) notyet limitcontrol(foreign == 0) weightprefix(weight_match)
		count if e(sample) == 1
		eststo mh`var', title("efh `var'")
}

esttab m* using "`here'/output/table_attgt_weightsdo.tex", mtitle b(3) se(3) replace
esttab m* using "`here'/output/table_attgt_weightsdo.txt", mtitle b(3) se(3) replace

log close
