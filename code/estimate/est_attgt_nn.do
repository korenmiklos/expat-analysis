clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_nn", text replace

use "`here'/temp/analysis_sample.dta", clear

*replace foreign_hire = 1 if ever_foreign_hire == 1 & foreign == 1
*replace has_expat_ceo = 1 if ever_expat_ceo == 1 & foreign == 1

rename ever_foreign ef
rename ever_foreign_hire efh
rename has_expat_ceo has_expat

foreach sample in ef efh {
	foreach var in foreign foreign_hire has_expat {
		attgt lnQL lnK lnL exporter lnQ if `sample' & time_foreign <= 5, treatment(`var') aggregate(e) pre(5) post(5) reps(20) notyet
		count if e(sample) == 1
		eststo model_`sample'`var', title("`sample' `var'")
	}
}

esttab model* using "`here'/output/table_attgt_nn.tex", mtitle b(3) se(3) replace
esttab model* using "`here'/output/table_attgt_nn.txt", mtitle b(3) se(3) replace

log close
