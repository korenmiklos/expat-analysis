clear all
use "temp/balance-small-clean.dta"
drop foreign

merge 1:1 frame_id year using "temp/firm_events.dta", nogen keep(match)

compress
save "temp/analysis_sample.dta", replace
