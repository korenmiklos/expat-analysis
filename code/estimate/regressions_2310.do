
**************
*Prepare data
**************

global here "/srv/sandbox/expat/almos"
use "$here/temp/analysis_sample.dta", clear

*Tradeable-nontradeable grouping


drop export_share
gen export_share=export/sales
replace export_share=1 if export_share>1 & missing(export_share)==0

*industry-decade
gen decade=1990 if year<2000
replace decade=2000 if year>=2000 & year<2010
replace decade=2010 if year>=2010

egen sales_ind=total(sales), by(teaor08_2d decade)
egen export_ind=total(export), by(teaor08_2d decade)
gen export_share_ind=export_ind/sales_ind

*Make sample

keep if ever_foreign_hire==1

drop if time_foreign<-4
drop if time_foreign>4 & time_foreign!=.

gen trend_plus=time_foreign+100

gen foreign_hire_local=(foreign_hire==1 & has_expat_ceo==0)
egen ever_foreign_hire_local=max(foreign_hire_local), by(frame_id_numeric)

gen x=(export_share_ind>.15) if time_foreign==0
egen exporter_ind=max(x), by(frame_id_numeric)
drop x

gen x=exporter if time_foreign==-1 | time_foreign==-2
egen exporter_pre=max(x), by(frame_id_numeric)
drop x

*Based on common sense
gen x=(industrial==1 | teaor08_2d>58) if time_foreign==0
egen exporter_ind_common=max(x), by(frame_id_numeric)

*************************
*Ever foreign hire sample
*************************

foreach depvar of varlist $outcome {

quietly xthdidregress ra (`depvar' i.trend_plus) (has_expat_ceo), group(frame_id_numeric) vce(cluster frame_id_numeric)

eststo: eventstudy, pre(4) post(4) baseline(atet)

eventstudy, pre(4) post(4) baseline(-4) generate(event_expat)

frame event_expat: graph twoway (rarea lower upper time, fcolor(gs10%30) lcolor(gs5%20)) (line coef time, color(olive)), graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xtitle("Event time") yline(0) 
*gr export "$here/output/twfe/expat_`depvar'_fh.png", replace

}

esttab using "$here/output/twfe/expat_`depvar'_fh.tex", star(* .1 ** .05 *** .01)  b(3) se  noconstant label replace  nonote  r2

quietly xthdidregress ra (lnQ i.trend_plus lnK lnL lnM ) (has_expat_ceo), group(frame_id_numeric) vce(cluster frame_id_numeric)

eststo: eventstudy, pre(4) post(4) baseline(atet)

eventstudy, pre(4) post(4) baseline(-4) generate(event_expat)

frame event_expat: graph twoway (rarea lower upper time, fcolor(gs10%30) lcolor(gs5%20)) (line coef time, color(olive)), graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xtitle("Event time") yline(0) 
gr export "$here/output/twfe/expat_TFP_fh.png", replace

quietly xthdidregress ra (exporter  i.trend_plus) (has_expat_ceo) if exporter_pre==0, group(frame_id_numeric) vce(cluster frame_id_numeric)
quietly xthdidregress ra (lnEx  i.trend_plus) (has_expat_ceo) if exporter_pre==1, group(frame_id_numeric) vce(cluster frame_id_numeric)
quietly xthdidregress ra (lnQd  i.trend_plus) (has_expat_ceo), group(frame_id_numeric) vce(cluster frame_id_numeric)


quietly xthdidregress ra (lnQ lnM lnL lnK  i.trend_plus ) (has_expat_ceo) if industrial==0, group(frame_id_numeric) vce(cluster frame_id_numeric)

eststo: eventstudy, pre(4) post(4) baseline(atet)
eventstudy, pre(4) post(4) baseline(-4) generate(event_expat)




