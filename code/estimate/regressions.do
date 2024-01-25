**************
*Prepare data
**************

* find root folder
here
global here = r(here)

use "$here/temp/analysis_sample.dta", clear

* different ways of measuring export orientation
generate lnEx = ln(export_18)
generate lnQd = ln(sales_18 - export_18)
clonevar export_entry = exporter
replace export_entry = . if exporter_pre == 1

*Create teaor in year -1, drop agriculture

egen teaor08_1d_num = group(teaor08_1d)
egen teaor08_2d_pre = max(cond(time_foreign==-1, teaor08_2d, .)), by(frame_id_numeric)
egen teaor08_1d_pre = max(cond(time_foreign==-1, teaor08_1d_num, .)), by(frame_id_numeric)

* drop agriculture and mining firms
drop if teaor08_2d_pre<5
generate industrial_pre = (teaor08_2d_pre < 40)

* compute

quietly regress lnQ lnK lnL lnM i.teaor08_2d##year if industrial_firm==1
predict TFP if e(sample), resid

quietly regress lnQ lnK lnL lnM i.teaor08_2d##year if industrial_firm==0
predict TFP_temp if e(sample), resid

replace TFP = TFP_temp if missing(TFP)
drop TFP_temp

*Samples
global local_sample "(ever_local==1 | foreign==0)"
global expat_sample "(ever_expat==1 | foreign==0)"

global varlist_rhs "lnQ lnQL TFP lnK lnL lnM exporter lnEx lnQd export_entry "
local pre 3
local post 5

****Average effect, foreign_hire sample, local and expat separately, xthdidreg

foreach Y in $varlist_rhs {

    display
    display
    display
    display "=== Variable: `Y' ==="

    eststo clear
    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)
    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric)
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)

    display
    display "=== Full sample ==="
    esttab, b(3) se  style(tex)

    eststo clear
    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial_pre==1, group(frame_id_numeric) vce(cluster frame_id_numeric)
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)
    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial_pre==1, group(frame_id_numeric) vce(cluster frame_id_numeric)
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)

    display
    display "=== Industry sample ==="
    esttab, b(3) se  style(tex)

    eststo clear
    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial_pre==0, group(frame_id_numeric) vce(cluster frame_id_numeric)
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)
    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial_pre==0, group(frame_id_numeric) vce(cluster frame_id_numeric)
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)

    display
    display "=== Service sample ==="
    esttab, b(3) se style(tex)

}

STOP HERE

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



