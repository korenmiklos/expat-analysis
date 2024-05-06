here
global here = r(here)
use "$here/temp/analysis_sample.dta", clear

which xthdidregress
which eventbaseline
which xt2treatments
which estout

*Samples
global local_sample "(ever_local==1 | foreign==0)"
global expat_sample "(ever_expat==1 | foreign==0)"

tabulate foreignness ever_expat
tabulate foreignness ever_expat if time_foreign == 0

local outcome TFP

foreach bs in atet -1 {
    quietly xthdidregress ra (`outcome') (local_ceo) if $local_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eventbaseline, pre(4) post(4) baseline(`bs')

    quietly xthdidregress ra (`outcome') (has_expat_ceo) if $expat_sample, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
    eventbaseline, pre(4) post(4) baseline(`bs')
}