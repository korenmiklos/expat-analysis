clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_att5", text replace

use "`here'/temp/analysis_sample.dta", clear

rename ever_foreign ef
rename ever_foreign_hire efh
rename has_expat_ceo has_expat

foreach var in foreign foreign_hire has_expat {
	attgt lnQL lnK lnL exporter lnQ, treatment(`var') aggregate(att) pre(5) post(5) reps(20) notyet limitcontrol(foreign == 0)
	count if e(sample) == 1
	eststo model_`sample'`var', title("`sample' `var'")
}

esttab model* using "`here'/output/table_attgt_att5.tex", mtitle b(3) se(3) replace
esttab model* using "`here'/output/table_attgt_att5.txt", mtitle b(3) se(3) replace

log close
