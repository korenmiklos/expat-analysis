clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_missing", text replace

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
gen Qh_ratio = Qh/sales_18
gen lnQhr = ln(Qh_ratio)

clonevar immat_18_imputed = immat_18
clonevar export_18_imputed = export_18

mvencode immat_18_imputed export_18_imputed, mv(0) override

gen lnEx_imputed=ln(export_18_imputed)
gen Qh_imputed=sales_18-export_18_imputed
gen lnQh_imputed=ln(Qh_imputed)
gen Qh_ratio_imputed = Qh_imputed/sales_18
gen lnQhr_imputed = ln(Qh_ratio_imputed)


count
foreach var in sales_18 export_18 immat_18 emp_add tanass_18 lnQL TFP_cd lnK lnIK_0 lnL exporter lnQ lnQh lnEx lnQhr immat_18_imputed export_18_imputed lnEx_imputed lnQh_imputed lnQhr_imputed {
	di "=`var'"
	count if `var' == .
	count if `var' == 0
	count if `var' != . & `var' != 0
}

foreach var in immat_18 export_18 TFP_cd immat_18_imputed export_18_imputed {
	quietly gen zero_missing_positive = 0 if `var' == 0
	quietly replace zero_missing_positive = 1 if missing(`var')
	quietly replace zero_missing_positive = 2 if `var' > 0 & !missing(`var')
	*tab zero_missing_positive l1.zero_missing_positive, missing
	quietly gen zero_missing_positive_lag = l1.zero_missing_positive
	di "`var'"
	tab zero_missing_positive zero_missing_positive_lag, missing
	drop zero*
}

log close
