clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/timer.log", text replace

use "`here'/temp/analysis_sample.dta", clear
net install csdid, from ("https://raw.githubusercontent.com/friosavila/csdid_drdid/main/code/") replace

timer on 1
attgt lnQ if ever_foreign, treatment(foreign) aggregate(e) reps(20) notyet
timer off 1

timer on 2
attgt lnQ if ever_foreign, treatment(foreign) aggregate(att) reps(20) notyet
timer off 2

timer on 3
csdid lnQ if ever_foreign, ivar(frame_id_numeric) time(year) gvar(first_year_foreign) method(dripw) notyet
estat simple
estat event
timer off 3

timer list 1
timer list 2
timer list 3

log close
