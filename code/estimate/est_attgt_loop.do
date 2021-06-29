clear all
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_loop", text replace

use "`here'/temp/analysis_sample.dta"

rename ever_foreign ef
rename ever_foreign_hire efh
rename has_expat_ceo has_expat
rename exporter exp

gen lnIK = ln(immat_18)
gen lnIK_0=lnIK
replace lnIK_0=0 if immat_18==0
gen lnEx=ln(export_18)
gen Qh=sales_18-export_18
gen lnQh=ln(Qh)
gen Qh_ratio = Qh/sales_18
gen lnQhr = ln(Qh_ratio)

foreach depvar in lnQL TFP_cd lnK lnIK_0 lnL exp lnQ lnQh lnEx lnQhr {
	foreach sample in ef efh {
		foreach var in foreign foreign_hire has_expat {
			attgt `depvar' if `sample', treatment(`var') aggregate(e) pre(4) post(4) reps(20) notyet
			count if e(sample) == 1
			eststo model_`sample'`var'`depvar', title("`depvar' `sample' `var'")
		}
	}
}

esttab model* using "`here'/output/table_attgt_loop.tex", mtitle b(3) se(3) replace
esttab model* using "`here'/output/table_attgt_loop.txt", mtitle b(3) se(3) replace

log close
