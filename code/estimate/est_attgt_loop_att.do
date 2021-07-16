clear all
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_loop_att", text replace

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

foreach depvar in TFP_cd lnIK_0 lnQh lnQhr {
	foreach var in foreign_only foreign_hire_only has_expat {
		attgt `depvar', treatment(`var') aggregate(att) reps(20) notyet limitcontrol(foreign == 0)
		count if e(sample) == 1
		eststo m`var'`depvar', title("`depvar' `var'")
	}
	
	foreach var in foreign_hire_only has_expat {
		attgt `depvar' if efh, treatment(`var') aggregate(att) reps(20) notyet limitcontrol(foreign == 0)
		count if e(sample) == 1
		eststo mh`var'`depvar', title("efh `depvar' `var'")
	}
}

esttab m* using "`here'/output/table_attgt_loop_att.tex", mtitle b(3) se(3) replace
esttab m* using "`here'/output/table_attgt_loop_att.txt", mtitle b(3) se(3) replace

log close
