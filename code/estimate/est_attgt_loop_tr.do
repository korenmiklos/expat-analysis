clear all
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_loop_tr", text replace

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

foreach type in e att gt {
	foreach depvar in TFP_cd lnIK_0 lnQh lnQhr {
		attgt `depvar', treatment(has_expat) treatment2(foreign_hire_only) aggregate(`type') pre(5) post(5) reps(20)
		count if e(sample) == 1
		eststo m`depvar', title("`depvar'")
	}
	
esttab m* using "`here'/output/table_attgt_loop_tr_`type'.tex", mtitle b(3) se(3) replace
esttab m* using "`here'/output/table_attgt_loop_tr_`type'.txt", mtitle b(3) se(3) replace

}

log close
