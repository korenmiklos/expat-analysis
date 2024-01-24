clear all
set more off

* find root folder
here
local here = r(here)

use "`here'/temp/balance-small-clean.dta", clear

sort frame_id_numeric year

gen pattern_me = (frame_id_numeric == frame_id_numeric[_n-1] & (year != (year[_n-1] + 1)))
gen pattern_eme = ((frame_id_numeric == frame_id_numeric[_n-1] & (year != (year[_n-1] + 1))) & (frame_id_numeric == frame_id_numeric[_n-2] & (year == (year[_n-2] + 2))))

tab pattern_me
tab pattern_eme
