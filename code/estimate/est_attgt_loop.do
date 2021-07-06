clear all
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_loop", text replace

use "`here'/temp/analysis_sample.dta"

replace foreign_hire = 1 if ever_foreign_hire == 1 & foreign == 1
replace has_expat_ceo = 1 if ever_expat_ceo == 1 & foreign == 1

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

foreach depvar in TFP_cd lnIK_0 lnQh lnQhr {
	foreach sample in ef efh {
		foreach var in foreign foreign_hire has_expat {
			attgt `depvar' if `sample' & time_foreign <= 5, treatment(`var') aggregate(e) pre(5) post(5) reps(20) notyet
			count if e(sample) == 1
			eststo model_`sample'`var'`depvar', title("`depvar' `sample' `var'")
		}
	}
}

esttab model* using "`here'/output/table_attgt_loop.tex", mtitle b(3) se(3) replace
esttab model* using "`here'/output/table_attgt_loop.txt", mtitle b(3) se(3) replace

log close
