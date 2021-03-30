clear all
set more off

* find root folder
here
local here = r(here)

use "`here'/temp/event_time_all_balance.dta", clear
append using "`here'/temp/event_time_foreign_balance.dta"
append using "`here'/temp/event_time_foreign_clean.dta"
append using "`here'/temp/event_time_foreign_analysis.dta"

count

keep if time_foreign > -6 & time_foreign < 6

count

rename _freq frequency

bys type: egen frequency0 = max(cond(time_foreign == 0,frequency,.))
gen frequency_rel = frequency / frequency0 * 100

sort type time_foreign

twoway (line frequency_rel time_foreign if type == "all", color(red)) (line frequency_rel time_foreign if type == "balance", color(green)) (line frequency_rel time_foreign if type == "clean", color(blue)) (line frequency_rel time_foreign if type == "analysis", color(orange)), title("Time foreign for companies", color(black)) xtitle("Time event") ytitle("") xlabel(-5(1)5) legend(order(1 "balance-small - all" 2 "balance-small - filtered" 3 "clean" 4 "analysis-sample")) graphregion(color(white))
graph export "`here'/output/figure/event_time_foreign.png", replace
