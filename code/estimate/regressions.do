here
global here = r(here)
use "$here/temp/analysis_sample.dta", clear

*Samples
global local_sample "(ever_local==1 | foreign==0)"
global expat_sample "(ever_expat==1 | foreign==0)"

global varlist_rhs "exporter export_entry lnQL"

****Average effect, foreign_hire sample, local and expat separately, xthdidreg


*Full sample
foreach Y in $varlist_rhs {

    display "`Y'"

    eststo clear
    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)

    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)

    eststo: quietly xt2treatments `Y',  treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet)

    display "Full sample"
    esttab, b(3) se  style(tex)

}

*Industrial sample
preserve
keep if industrial==1
foreach Y in $varlist_rhs {
    display "`Y'"

    eststo clear
    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial==1, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)
    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial==1, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)

    eststo: quietly xt2treatments `Y',  treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet)

    display "Industry sample"
    esttab, b(3) se  style(tex)
}
restore

*Service sample
preserve
keep if industrial==0
foreach Y in $varlist_rhs {

    display "`Y'"

    eststo clear
    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample & industrial==0, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)
    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample & industrial==0, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)

    eststo: quietly xt2treatments `Y',  treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(atet)

    display "Service sample"
    esttab, b(3) se style(tex)
}
restore

*****Figures

*Whole sample
foreach Y in $varlist_rhs {

    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eventbaseline, pre(4) post(4) baseline(-1) generate(event_expat)

    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eventbaseline, pre(4) post(4) baseline(-1) generate(event_local)

    frame event_expat: frlink 1:1 time, frame(event_local) generate(local)
    frame event_expat: frget coef_local=coef upper_local=upper lower_local=lower, from(local)

    frame event_expat: graph twoway (rarea lower upper time, fcolor(red%10) lcolor(red%10)) (line coef time, color(red)) (rarea lower_local upper_local time, fcolor(gs10%10) lcolor(gs5%10)) (line coef_local time, color(grey)), graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xtitle("Event time") yline(0) 

    gr export "$here/output/twfe/expat_local_`Y'.pdf", replace

}

*Industry

preserve
keep if industrial==1

foreach Y in $varlist_rhs {

    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eventbaseline, pre(4) post(4) baseline(-1) generate(event_expat)

    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eventbaseline, pre(4) post(4) baseline(-1) generate(event_local)

    frame event_expat: frlink 1:1 time, frame(event_local) generate(local)
    frame event_expat: frget coef_local=coef upper_local=upper lower_local=lower, from(local)

    frame event_expat: graph twoway (rarea lower upper time, fcolor(red%10) lcolor(red%10)) (line coef time, color(red)) (rarea lower_local upper_local time, fcolor(gs10%10) lcolor(gs5%10)) (line coef_local time, color(grey)), graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xtitle("Event time") yline(0) 

    gr export "$here/output/twfe/expat_local_ind_`Y'.pdf", replace

}
restore

*Services
preserve
keep if industrial==0

foreach Y in $varlist_rhs {	

    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eventbaseline, pre(4) post(4) baseline(-1) generate(event_expat)

    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eventbaseline, pre(4) post(4) baseline(-1) generate(event_local)

    frame event_expat: frlink 1:1 time, frame(event_local) generate(local)
    frame event_expat: frget coef_local=coef upper_local=upper lower_local=lower, from(local)

    frame event_expat: graph twoway (rarea lower upper time, fcolor(red%10) lcolor(red%10)) (line coef time, color(red)) (rarea lower_local upper_local time, fcolor(gs10%10) lcolor(gs5%10)) (line coef_local time, color(grey)), graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xtitle("Event time") yline(0) 

    gr export "$here/output/twfe/expat_local_serv_`Y'.pdf", replace

}
restore
