clear all
set more off

* find root folder
here
local here = r(here)

use "`here'/temp/analysis_sample.dta", clear
sort frame_id_numeric year
gen x = year - year[_n-1] if frame_id_numeric == frame_id_numeric[_n-1]
gen hole_large_year = (x > 10 & x != .)
by frame_id_numeric: egen hole_large =  max(cond((x > 10 & x != .),1,0))
tab hole_large
tempfile holes
save `holes'

use "`here'/input/merleg-expat/balance-small.dta", clear

keep if substr(frame_id, 1, 2) == "ft"
generate long frame_id_numeric = real(substr(frame_id, 3, 8))
codebook frame_id*
drop frame_id
xtset frame_id_numeric year

merge m:1 frame_id_numeric year using `holes', keepusing(ever_foreign hole_large hole_large_year) keep(1 3) //nogen

tab hole_large
tab hole_large if ever_foreign
codebook frame_id_numeric if hole_large == 1 & ever_foreign

browse if hole_large == 1 & ever_foreign

sort frame_id_numeric year
gen x = year - year[_n-1] if frame_id_numeric == frame_id_numeric[_n-1]
gen hole_large_year_balance = (x > 10 & x != .)
by frame_id_numeric: egen hole_large_balance =  max(cond((x > 10 & x != .),1,0))

tab hole_large hole_large_balance
tab hole_large_year hole_large_year_balance

*sort frame_id_numeric year
*gen change_originalid = 0
*replace change_originalid = 1 if hole_large_year == 1 & (originalid != originalid[_n-1])
*gen change_teaor = 0
*replace change_teaor = 1 if hole_large_year == 1 & (teaor08_2d != teaor08_2d[_n-1])
*mvencode change_originalid change_teaor, mv(0)

*tab change_originalid change_teaor
*tab change_originalid change_teaor if hole_large == 1 & ever_foreign

use "`here'/temp/balance-small-clean.dta", clear

merge m:1 frame_id_numeric year using `holes', keepusing(ever_foreign hole_large hole_large_year) keep(1 3) //nogen

sort frame_id_numeric year
gen x = year - year[_n-1] if frame_id_numeric == frame_id_numeric[_n-1]
gen hole_large_year_clean = (x > 10 & x != .)
by frame_id_numeric: egen hole_large_clean =  max(cond((x > 10 & x != .),1,0))

tab hole_large hole_large_clean
tab hole_large_year hole_large_year_clean
