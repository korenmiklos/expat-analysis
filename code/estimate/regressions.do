set varabbrev off, permanently
here
global here = r(here)
use "$here/temp/analysis_sample.dta", clear

which xthdidregress
which eventbaseline
which xt2treatments
which estout

* only keep firms that have both t = g and t = g-1
egen has1 = max(time_foreign == -1), by(frame_id_numeric)
egen has0 = max(time_foreign == 0), by(frame_id_numeric)
keep if has0 & has1

*Samples
global local_sample "(ever_local==1 | foreign==0) & !fake"
global expat_sample "(ever_expat==1 | foreign==0) & !fake"

global varlist_rhs "lnK lnL TFP lnQ lnEx lnQd exporter"

egen g = max(cond(time_foreign == 0, year, .)), by(frame_id_numeric)
egen Ng_expat = total(time_foreign == 0 & ever_expat), by(g)
egen Ng_local = total(time_foreign == 0 & ever_local), by(g)
egen Ng_treated = total(time_foreign == 0), by(g)
assert Ng_treated == Ng_expat + Ng_local
generate weight = cond(ever_expat, round(Ng_treated/Ng_expat), round(Ng_treated/Ng_local))

* explicitly duplicate overweighted observations
expand weight
egen index = seq(), by(frame_id_numeric year)
tabulate index

do "code/create/fake_controls.do"
replace index = 1 if missing(index)
egen new_firm_id = group(frame_id_numeric index)
xtset new_firm_id year

****Average effect, foreign_hire sample, local and expat separately, xthdidreg
local coef 1

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
    xtset new_firm_id year

    quietly xthdidregress ra (`Y') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)
    scalar mean1l = e(b)[1, `coef']

    quietly xthdidregress ra (`Y') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)
    scalar mean1e = e(b)[1, `coef']

    quietly xthdidregress ra (`Y') (local_ceo) if (ever_local==1)|fake, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(never)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)
    scalar mean2l = e(b)[1, `coef']
    scalar variancel = e(V)[`coef', `coef']

    quietly xthdidregress ra (`Y') (has_expat_ceo) if (ever_expat==1)|fake, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(never)
    eststo: quietly eventbaseline, pre(4) post(4) baseline(atet)
    scalar mean2e = e(b)[1, `coef']
    scalar variancee = e(V)[`coef', `coef']

    display "Full sample"
    esttab, b(3) se  style(tex)
    display "Difference in means: " mean1l - mean1e
    display "ATET of differences: " mean2l - mean2e
    display "Standard error of difference: " sqrt(variancel + variancee)

}
restore
}

BRK

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
