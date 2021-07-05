clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt", text replace

use "`here'/temp/analysis_sample.dta", clear

rename ever_foreign ef
rename ever_foreign_hire efh
rename has_expat_ceo has_expat

foreach sample in ef efh {
	foreach var in foreign foreign_hire has_expat {
		attgt lnQL TFP_cd lnK lnL exporter lnQ if `sample', treatment(`var') aggregate(e) pre(4) post(4) reps(20) notyet
		count if e(sample) == 1
		eststo model_`sample'`var', title("`sample' `var'")
	}
}

esttab model* using "`here'/output/table_attgt.tex", mtitle b(3) se(3) replace
esttab model* using "`here'/output/table_attgt.txt", mtitle b(3) se(3) replace

log close
