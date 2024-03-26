set varabbrev off, permanently
here
global here = r(here)
use "$here/temp/analysis_sample.dta", clear

keep if year < 2010

*Samples
global local_sample "(ever_local==1 | foreign==0) & !fake"
global expat_sample "(ever_expat==1 | foreign==0) & !fake"

global varlist_rhs "lnK lnL TFP lnQ lnEx lnQd exporter"

do "code/create/fake_controls.do"
tempvar N_control Yg

****Average effect, foreign_hire sample, local and expat separately, xthdidreg

local samples full industrial service
local full 1
local industrial industrial==1
local service industrial==0
foreach sample in `samples'{
    preserve
    display "`sample' sample"
    keep if (``sample'') | fake
foreach Y in $varlist_rhs {

    display "`Y'"

    eststo clear
    xtset frame_id_numeric year

    tabulate local_ceo if $local_sample, missing

    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    egen `N_control' = total(control & e(sample)), by(year)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)
    scalar mean1l = e(b)[1,1]

    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)
    scalar mean1e = e(b)[1,1]

    quietly xthdidregress ra (`Y') (local_ceo) if (ever_local==1)|(fake & (frame_id_numeric <= `N_control')), group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(never)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)
    scalar mean2l = e(b)[1,1]
    scalar variancel = e(V)[1,1]

    quietly xthdidregress ra (`Y') (has_expat_ceo) if (ever_expat==1)|(fake & (frame_id_numeric <= `N_control')), group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(never)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)
    scalar mean2e = e(b)[1,1]
    scalar variancee = e(V)[1,1]

    display "Full sample"
    esttab, b(3) se  style(tex)
    display "Difference in means: " mean1l - mean1e
    display "ATET of differences: " mean2l - mean2e
    display "Standard error of difference: " sqrt(variancel + variancee)

    drop `N_control'

}
restore
}

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
