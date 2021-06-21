clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt", text replace

use "`here'/temp/analysis_sample.dta"

*attgt exporter lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(has_expat_ceo ) aggregate(e) pre(2) post(3) reps(20)
*matrix list e(b)
*esttab

*foreach var in exporter lnQL {
*	attgt `var' if inrange(year, 1992, 2004) & ever_foreign, treatment(has_expat_ceo ) aggregate(e) pre(2) post(3) reps(20)
*	matrix list e(b)
*	esttab
*}

foreach var in foreign foreign_hire has_expat_ceo {
	*eststo: attgt exporter lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(`var') aggregate(e) pre(2) post(3) reps(20)
	*attgt exporter lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(`var') aggregate(e) pre(2) post(3) reps(20)
	attgt lnQ lnQL TFP_cd lnK lnL lnKL exporter if ever_foreign, treatment(`var') aggregate(e) pre(4) post(4) reps(20) notyet
	count if e(sample) == 1
	eststo model_`var', title("`var'")
	*matrix list e(b)
}

esttab model* using "`here'/output/table_attgt.tex", mtitle b(3) se(3) replace
esttab model* using "`here'/output/table_attgt.txt", mtitle b(3) se(3) replace

log close
