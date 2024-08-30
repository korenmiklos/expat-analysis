*Tables and figures for expat study

use "temp/analysis_sample.dta", clear
which xt2treatments
which e2frame
which reghdfe
which estout

*Descriptive statistics
format tradable_sector TFP lnKL export_share %5.3f
format lnL lnK lnQ lnQd %6.2f

*Desciptives table
eststo clear

quietly estpost sum tradable_sector emp lnK lnQ lnKL TFP export_share if ever_local==1 & (time_foreign==-1)
est store local

quietly estpost sum tradable_sector emp lnK lnQ lnKL TFP export_share if ever_expat==1 & (time_foreign==-1)
est store expat

esttab local expat using "output/table/desc_firmvars.tex", main(mean) aux(sd) mtitle("Local CEO" "Expatriate CEO") label pare nolegend nonote replace

*Selection regression
reghdfe ever_expat lnL lnKL TFP export_share tradable_sector time_treat_1990s if time_foreign==-1, noabsorb cluster(frame_id_numeric)
sum ever_expat if e(sample)
estadd scalar mean2 = r(mean)
est store est1

reghdfe ever_expat lnL lnKL TFP export_share if time_foreign==-1, absorb(year##teaor08_2d_pre) cluster(frame_id_numeric)
sum ever_expat if e(sample)
estadd scalar mean2 = r(mean)
est store est2

esttab est1 est2  using "output/table/selection_reg.tex", nostar b(3) scalar("mean2 Mean dep.var.") noconstant nonote se replace label r2 nolegend nonote


*Regressions
global varlist_rhs "TFP lnQd"

local estab_options nostar b(3) se style(tex) replace nolegend label nonote coeflabels(ATET "Expatriate CEO")
local xt2treatments_options treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet) weighting(optimal)
local lnQd_condition "lnQd_exist_post=="
*Full sample

eststo clear
foreach Y in $varlist_rhs {
	xt2treatments `Y' if ``Y'_condition' 1, `xt2treatments_options'
	sum `Y' if e(sample)
	estadd scalar mean2 = r(mean)
	eststo 
}

esttab using "output/table/reg_full_sample.tex", `estab_options' 

*Tradable/nontradable


forvalues i=0/1 {
	eststo clear
	foreach Y in $varlist_rhs {
		xt2treatments `Y' if ``Y'_condition' 1 & tradable_sector==`i', `xt2treatments_options'
		sum `Y' if e(sample)
		estadd scalar mean2 = r(mean)
		eststo 
	}
	esttab using "output/table/reg_tradable`i'_sample.tex", `estab_options'
}


*Export, export entry
eststo clear
xt2treatments exporter, `xt2treatments_options'
sum exporter if e(sample)
estadd scalar mean2 = r(mean)
eststo 
xt2treatments exporter if tradable_sector==0, `xt2treatments_options'
sum exporter if e(sample)
estadd scalar mean2 = r(mean)
eststo 
xt2treatments exporter if tradable_sector==1, `xt2treatments_options'
sum exporter if e(sample)
estadd scalar mean2 = r(mean)
eststo 
esttab using "output/table/reg_exporter.tex", `estab_options' mtitle("Full sample" "Nontradable" "Tradable")

