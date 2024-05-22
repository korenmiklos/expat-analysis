*Tables and figures for expat study

use "temp/analysis_sample.dta", clear
which xt2treatments
which e2frame
which reghdfe
which estout

*Industrial firms
generate industrial_pre = inrange(teaor08_2d_pre, 5, 39)

*Tradable sectors (up to TEAOR 75)
generate tradable_nonservice = inrange(teaor08_2d_pre, 1, 35)
generate tradable_service = inlist(teaor08_2d_pre, 50, 51, 52, 58, 59, 60, 61, 62, 63, 69, 70, 71, 72, 73, 74) 
drop tradable_sector
generate tradable_sector = (tradable_nonservice==1 | tradable_service==1)

*Time of treatment
egen time_treat = min(cond(time_foreign==0, year, .)), by(frame_id_numeric)

*Variables for descriptives
egen time_treat_1990s = max(time_treat<2000), by(frame_id_numeric)
generate time_tradable_int = time_treat_1990s*tradable_sector

*Missing Qd before and after treatment
foreach Y in lnQd {
	egen `Y'_exist_pre = max(cond(!missing(`Y') & time_foreign<0, 1, 0)), by(frame_id_numeric)
	egen `Y'_exist_post = max(cond(!missing(`Y') & time_foreign>=0, 1, 0)), by(frame_id_numeric)
}

egen lnQd_missing = max(cond(missing(lnQd), 1, 0)), by(frame_id_numeric)
count if missing(lnQd) & lnQd_exist_pre==1 & lnQd_exist_post==1
*74 cases, 0.57%

*Variable labels
label var industrial_pre "Industrial Firm"
label var emp "Employment"
label var TFP "TFP"
label var tradable_sector "Tradable Sector"
label var time_treat_1990s "Early Acquisition"
label var export_share "Export Share"
label var local_ceo "Local CEO"
label var has_expat_ceo "Expatriate CEO"
label var lnK "Capital"
label var lnL "Labor"
label var lnQ "Sales"
label var lnQd "Domestic Sales"
label var lnKL "Capital-Labor Ratio"
label var ever_expat "Expatriate CEO"


*Descriptive statistics

*Desciptives table
eststo clear

quietly estpost sum tradable_sector emp lnK lnQ lnKL TFP export_share if ever_local==1 & (time_foreign==-1)
est store local

quietly estpost sum tradable_sector emp lnK lnQ lnKL TFP export_share if ever_expat==1 & (time_foreign==-1)
est store expat

esttab local expat using "output/table/desc_firmvars.tex", main(mean) aux(sd) mtitle("Local CEO" "Expatriate CEO") label pare nolegend nonote replace

*Selection regression

reghdfe ever_expat tradable_sector time_treat_1990s lnL lnKL TFP export_share if time_foreign==-1, noabsorb cluster(frame_id_numeric)
sum ever_expat if e(sample)
estadd scalar mean2 = r(mean)
est store est1

reghdfe ever_expat lnL lnKL TFP export_share if time_foreign==-1, absorb(year##teaor08_2d_pre time_treat) cluster(frame_id_numeric)
sum ever_expat if e(sample)
estadd scalar mean2 = r(mean)
est store est2

esttab est1 est2  using "output/table/selection_reg.tex", star(* .1 ** .05 *** .01) b(3) scalar("mean2 Mean depvar" ) noconstant nonote se replace label r2 nolegend nonote


*Regressions
global varlist_rhs "lnK lnL TFP lnQ export_share"


*Full sample

eststo clear
foreach Y in $varlist_rhs {

	eststo: xt2treatments `Y', treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet) weighting(optimal)

}

esttab using "output/table/reg_full_sample.tex", b(3) se  style(tex) replace nolegend label nonote

*Tradable/nontradable


forvalues i=0/1 {
	
	eststo clear
	foreach Y in $varlist_rhs {
		eststo: xt2treatments `Y' if tradable_sector==`i', treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet) weighting(optimal)
	}

	esttab using "output/table/reg_tradable`i'_sample.tex", b(3) se  style(tex) replace nolegend nonote label

}


*Export, export entry
eststo clear
eststo: xt2treatments exporter, treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet) weighting(optimal)
eststo: xt2treatments exporter if tradable_sector==0, treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet) weighting(optimal)
eststo: xt2treatments exporter if tradable_sector==1, treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet) weighting(optimal)
esttab using "output/table/reg_exporter.tex", b(3) se  style(tex) replace nolegend label nonote

eststo clear
eststo: xt2treatments exporter if exporter_pre==0, treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet) weighting(optimal)
eststo: xt2treatments exporter if exporter_pre==0 & tradable_sector==0, treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet) weighting(optimal)
eststo: xt2treatments exporter if exporter_pre==0 & tradable_sector==1, treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet) weighting(optimal)
esttab using "output/table/reg_exportentry.tex", b(3) se  style(tex) replace nolegend label nonote


*Qd
eststo clear
eststo: xt2treatments lnQd if lnQd_exist_post==1, treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet) weighting(optimal)
eststo: xt2treatments lnQd if lnQd_exist_post==1 & tradable_sector==0, treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet) weighting(optimal)
eststo: xt2treatments lnQd if lnQd_exist_post==1 & tradable_sector==1, treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet) weighting(optimal)
esttab using "output/table/reg_lnQd.tex", b(3) se  style(tex) replace nolegend label nonote



