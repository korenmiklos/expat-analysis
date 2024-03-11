**************
*Prepare data
**************

* find root folder
here
global here = r(here)

use "$here/temp/analysis_sample.dta", clear

*Samples
global local_sample "((ever_local==1 | foreign==0) & (added_controls==0))"
global expat_sample "((ever_expat==1 | foreign==0) & (added_controls==0))"
global diff_sample "(ever_local==1 | ever_expat==1 | foreign==0)"

global varlist_rhs "lnK lnL TFP export_entry lnEx lnQd  "
local pre 4
local post 4

generate byte diff_treatment = has_expat_ceo | local_ceo
* add explicit control firms
* only keep control years of these firms
generate byte control = (foreign==0)
expand 1+control, generate(added_controls)
tabulate time_foreign added_controls 
* these firms need a new id
replace frame_id_numeric = 10*frame_id_numeric if added_controls==1

****Average effect, foreign_hire sample, local and expat separately, xthdidreg
local options group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
foreach Y in $varlist_rhs {

    display
    display
    display
    display "=== Variable: `Y' ==="
    clonevar difference = `Y'
    replace difference = -`Y' if ever_local==1 & added_controls==0
    replace difference = -`Y' if added_controls==1

    eststo clear
    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, `options'
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)
    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, `options'
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)
    quietly xthdidregress ra (difference) (diff_treatment) if $diff_sample, `options'
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)

    display
    display "=== Full sample ==="
    esttab, b(3) se  style(tex)

    eststo clear
    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial_pre==1,  `options'
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)
    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial_pre==1,  `options'
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)
    quietly xthdidregress ra (difference) (diff_treatment) if $diff_sample & industrial_pre==1, `options'
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)

    display
    display "=== Industry sample ==="
    esttab, b(3) se  style(tex)

    eststo clear
    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial_pre==0,  `options'
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)
    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial_pre==0,  `options'
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)
    quietly xthdidregress ra (difference) (diff_treatment) if $diff_sample & industrial_pre==0, `options'
    eststo: quietly eventbaseline, pre(`pre') post(`post') baseline(atet)

    display
    display "=== Service sample ==="
    esttab, b(3) se style(tex)

    drop difference
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



