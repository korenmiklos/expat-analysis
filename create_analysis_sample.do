clear all
use "temp/event_windows.dta"

do "create_event_dummies.do"

merge m:1 frame_id year using "temp/balance-small.dta", nogen keep(match)

compress
save "temp/analysis_sample.dta", replace
