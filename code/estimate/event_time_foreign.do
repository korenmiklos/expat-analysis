clear all
set more off

* find root folder
here
local here = r(here)

use "`here'/temp/event_time_all_balance", clear
append using "`here'/temp/event_time_all_clean"
append using "`here'/temp/event_time_all_analysis"
append using "`here'/temp/event_time_foreign_balance"
append using "`here'/temp/event_time_foreign_clean"
append using "`here'/temp/event_time_foreign_analysis"

count

keep if time_foreign > -6 & time_foreign < 6

count

rename _freq frequency

bys type: egen frequency0 = max(cond(time_foreign == 0,frequency,.))
gen frequency_rel = frequency / frequency0 * 100

sort type time_foreign

*twoway (line frequency_rel time_foreign if type == "balance-all", color(red)) (line frequency_rel time_foreign if type == "balance", color(purple)) (line frequency_rel time_foreign if type == "clean-all", color(black)) (line frequency_rel time_foreign if type == "clean", color(blue)) (line frequency_rel time_foreign if type == "analysis-all", color(green)) (line frequency_rel time_foreign if type == "analysis", color(orange)), title("Time foreign for companies", color(black)) xtitle("Time foreign") ytitle("") xlabel(-5(1)5) legend(order(1 "balance-small - all" 2 "balance-small - filtered" 3 "clean - all" 4 "clean - filtered" 5 "analysis-sample - all" 6 "analysis-sample - filtered")) graphregion(color(white))

twoway (line frequency_rel time_foreign if type == "balance-all", color(red)) (line frequency_rel time_foreign if type == "clean-all", color(black)) (line frequency_rel time_foreign if type == "analysis-all", color(green)) (line frequency_rel time_foreign if type == "analysis", color(orange)), title("Time foreign for companies", color(black)) xtitle("Time foreign") ytitle("") xlabel(-5(1)5) legend(order(1 "balance-small - all" 2 "clean - all" 3 "analysis-sample - all" 4 "filtered")) graphregion(color(white))
graph export "`here'/output/figure/event_time_foreign.png", replace
