clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_2002", text replace

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

gen lnIK = ln(immat_18)
gen lnIK_0=lnIK
replace lnIK_0=0 if immat_18==0
gen lnEx=ln(export_18)
gen Qh=sales_18-export_18
gen lnQh=ln(Qh)

foreach sample in ef efh {
	foreach var in foreign foreign_hire has_expat {
		*eststo: attgt exporter lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(`var') aggregate(e) pre(2) post(3) reps(20)
		*attgt exporter lnQL if inrange(year, 1992, 2004) & ever_foreign, treatment(`var') aggregate(e) pre(2) post(3) reps(20)
		attgt lnQL TFP_cd lnK lnIK_0 lnL exporter lnQ lnQh lnEx if `sample' & year >= 2002, treatment(`var') aggregate(e) pre(4) post(4) reps(20) notyet
		count if e(sample) == 1
		eststo model_`sample'`var', title("`sample' `var'")
		*matrix list e(b)
	}

	*esttab model_`sample'* using "`here'/output/table_`sample'_attgt.tex", mtitle title("`sample'") b(3) se(3) replace
	*esttab model_`sample'* using "`here'/output/table_`sample'_attgt.txt", mtitle title("`sample'") b(3) se(3) replace
}

esttab model* using "`here'/output/table_attgt_2002.tex", mtitle b(3) se(3) replace
esttab model* using "`here'/output/table_attgt_2002.txt", mtitle b(3) se(3) replace

log close
