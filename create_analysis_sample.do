clear all
use "temp/firm_events.dta"

merge m:1 frame_id year using "temp/balance-small.dta", nogen keep(match)

compress
save "temp/analysis_sample.dta", replace
