clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_lnK", text replace

use "`here'/temp/analysis_sample.dta"

*attgt exporter lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(has_expat_ceo ) aggregate(e) pre(2) post(3) reps(20)
*matrix list e(b)
*esttab

*foreach var in exporter lnQL {
*	attgt `var' if inrange(year, 1992, 2004) & ever_foreign, treatment(has_expat_ceo ) aggregate(e) pre(2) post(3) reps(20)
*	matrix list e(b)
*	esttab
*}

rename ever_foreign ef
rename ever_foreign_hire efh
rename has_expat_ceo has_expat

foreach sample in ef efh {
	foreach var in foreign foreign_hire has_expat {
		*eststo: attgt exporter lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(`var') aggregate(e) pre(2) post(3) reps(20)
		*attgt exporter lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(`var') aggregate(e) pre(2) post(3) reps(20)
		attgt lnK if `sample', treatment(`var') aggregate(att) reps(20) notyet
		count if e(sample) == 1
		eststo model_`sample'`var', title("`sample' `var'")
		*matrix list e(b)
	}

	*esttab model_`sample'* using "`here'/output/table_`sample'_attgt.tex", mtitle title("`sample'") b(3) se(3) replace
	*esttab model_`sample'* using "`here'/output/table_`sample'_attgt.txt", mtitle title("`sample'") b(3) se(3) replace
}

esttab model* using "`here'/output/table_attgt_lnK.tex", mtitle b(3) se(3) replace
esttab model* using "`here'/output/table_attgt_lnK.txt", mtitle b(3) se(3) replace

log close
