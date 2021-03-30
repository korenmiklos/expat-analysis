clear all
set more off

* find root folder
here
local here = r(here)

use "`here'/input/merleg-expat/balance-small.dta", clear

* keep only numeric part of frame_id
keep if substr(frame_id, 1, 2) == "ft"
generate long frame_id_numeric = real(substr(frame_id, 3, 8))
codebook frame_id*
drop frame_id
xtset frame_id_numeric year

*count
sort frame_id_numeric year
recode fo3 (. = 0)

tempfile balance
save `balance'

tempname graph
postfile `graph' time_event frequency year using "`here'/temp/event_time_year.dta", replace

forval i = 1995(5)2010 {
	use `balance', clear
	bys frame_id_numeric: egen firm_exist = max(cond(year == `i',1,0))
	gen year_reference = `i'
	gen time_event = year - year_reference
	contract time_event if firm_exist
	tempfile frequency_`i'
	save `frequency_`i''
	forval j = 1/`=_N' {
		use `frequency_`i'', clear
		keep in `j'
		post `graph' (time_event) (_freq) (`i')
	}
}

postclose `graph'
use "`here'/temp/event_time_year.dta", clear

count

keep if time_event > -6 & time_event < 6

bys year: egen frequency0 = max(cond(time_event == 0,frequency,.))
gen frequency_rel = frequency / frequency0 * 100

twoway (line frequency_rel time_event if year == 1995, color(red)) (line frequency_rel time_event if year == 2000, color(green)) (line frequency_rel time_event if year == 2005, color(blue)) (line frequency_rel time_event if year == 2010, color(orange)), title("Time events for all companies", color(black)) xtitle("Time event") ytitle("") xlabel(-5(1)5) legend(order(1 "1995" 2 "2000" 3 "2005" 4 "2010")) graphregion(color(white))
graph export "`here'/output/figure/event_time_year.png", replace
