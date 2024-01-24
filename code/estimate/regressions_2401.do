**************
*Prepare data
**************

global here "/srv/sandbox/expat/almos"
use "$here/temp/analysis_sample.dta", clear
keep if ever_foreign_hire==1
drop if time_foreign<-10
drop if time_foreign>5

*keep if time_foreign>-4 & time_foreign<6

gen trend_plus=time_foreign+100

gen x=exporter if time_foreign==-1 | time_foreign==-2
egen exporter_pre=max(x), by(frame_id_numeric)
drop x

gen local_ceo=(has_expat_ceo==0  & foreign_hire==1)
egen ever_local=max(local), by(frame_id_numeric)

*Tradeable-nontradeable variable

*Create teaor in year -1, drop agriculture

tempvar x
gen `x'=teaor08_2d if time_foreign==-1
egen teaor08_2d_pre=max(`x'), by(frame_id_numeric)

egen teaor08_1d_num=group(teaor08_1d)

tempvar x
gen `x'=teaor08_1d_num if time_foreign==-1
egen teaor08_1d_pre=max(`x'), by(frame_id_numeric)

drop if teaor08_2d_pre<5

gen industrial_pre=(teaor08_2d_pre<40)

*TFP
drop TFP_cd

quietly reg lnQ lnK lnL lnM i.teaor08_2d##year if industrial_firm==1
predict TFP if e(sample), res
quietly reg lnQ lnK lnL lnM i.teaor08_2d##year if industrial_firm==0
predict TFP_temp if e(sample), res
replace TFP=TFP_temp if TFP==.
drop TFP_temp

*Samples
global local_sample "(ever_local==1 | foreign==0)"
global expat_sample "(ever_expat==1 | foreign==0)"

global varlist_rhs "lnQ lnQL TFP lnK lnL lnM exporter lnEx lnQd"


****Average effect, foreign_hire sample, local and expat separately, xthdidreg

foreach Y in $varlist_rhs {

display "`Y'"

eststo clear
quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)

display "Full sample"
esttab, b(3) se  style(tex)

eststo clear
quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial_pre==1, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial_pre==1, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)

display "Industry sample"
esttab, b(3) se  style(tex)

eststo clear
quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial_pre==0, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial_pre==0, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)

display "Service sample"
esttab, b(3) se style(tex)

}


*Inputs

eststo clear
foreach Y in lnK lnL lnM {

quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
}

display "Full sample"
esttab, b(3) se  style(tex)

eststo clear
foreach Y in lnK lnL lnM {

quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial_pre==1, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial_pre==1, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
}

display "Industry sample"
esttab, b(3) se  style(tex)

eststo clear
foreach Y in lnK lnL lnM {

quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial_pre==0, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial_pre==0, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
}

display "Service sample"
esttab, b(3) se style(tex)


*Outputs

eststo clear
foreach Y in lnQ lnEx lnQd {

quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
}

display "Full sample"
esttab, b(3) se  style(tex)

eststo clear
foreach Y in lnQ lnEx lnQd {

quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial_pre==1, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial_pre==1, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
}

display "Industry sample"
esttab, b(3) se  style(tex)

eststo clear
foreach Y in lnQ lnEx lnQd {

quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial_pre==0, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial_pre==0, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
}

display "Service sample"
esttab, b(3) se style(tex)


*****Figures

*Whole sample
foreach Y in $varlist_rhs {

quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
eventstudy, pre(3) post(4) baseline(-1) generate(event_expat)

quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
eventstudy, pre(3) post(4) baseline(-1) generate(event_local)

frame event_expat: frlink 1:1 time, frame(event_local) generate(local)
frame event_expat: frget coef_local=coef upper_local=upper lower_local=lower, from(local)

frame event_expat: graph twoway (rarea lower upper time, fcolor(red%10) lcolor(red%10)) (line coef time, color(red)) (rarea lower_local upper_local time, fcolor(gs10%10) lcolor(gs5%10)) (line coef_local time, color(grey)), graphregion(color(white)) xlabel(-3(1)4) legend(off) xline(-0.5) xtitle("Event time") yline(0) 

gr export "$here/output/twfe/expat_local_`Y'.pdf", replace

}

*Industry

preserve
keep if industrial_pre==1

foreach Y in $varlist_rhs {

quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
eventstudy, pre(3) post(4) baseline(-1) generate(event_expat)

quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
eventstudy, pre(3) post(4) baseline(-1) generate(event_local)

frame event_expat: frlink 1:1 time, frame(event_local) generate(local)
frame event_expat: frget coef_local=coef upper_local=upper lower_local=lower, from(local)

frame event_expat: graph twoway (rarea lower upper time, fcolor(red%10) lcolor(red%10)) (line coef time, color(red)) (rarea lower_local upper_local time, fcolor(gs10%10) lcolor(gs5%10)) (line coef_local time, color(grey)), graphregion(color(white)) xlabel(-3(1)4) legend(off) xline(-0.5) xtitle("Event time") yline(0) 

gr export "$here/output/twfe/expat_local_ind_`Y'.pdf", replace

}
restore

*Services
preserve
keep if industrial_pre==0

foreach Y in $varlist_rhs {	

quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
eventstudy, pre(3) post(4) baseline(-1) generate(event_expat)

quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
eventstudy, pre(3) post(4) baseline(-1) generate(event_local)

frame event_expat: frlink 1:1 time, frame(event_local) generate(local)
frame event_expat: frget coef_local=coef upper_local=upper lower_local=lower, from(local)

frame event_expat: graph twoway (rarea lower upper time, fcolor(red%10) lcolor(red%10)) (line coef time, color(red)) (rarea lower_local upper_local time, fcolor(gs10%10) lcolor(gs5%10)) (line coef_local time, color(grey)), graphregion(color(white)) xlabel(-3(1)4) legend(off) xline(-0.5) xtitle("Event time") yline(0) 

gr export "$here/output/twfe/expat_local_serv_`Y'.pdf", replace

}
restore

quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial_pre==0, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial_pre==0, group(frame_id_numeric) vce(cluster frame_id_numeric)
eststo: quietly eventstudy, pre(3) post(5) baseline(atet)
}



