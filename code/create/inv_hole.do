clear all
* find root folder
here
local here = r(here)

*cap log close
*log using "`here'/temp/inv_hole", text replace

use "`here'/input/ceo-panel/ceo-panel.dta", clear
*merge m:1 frame_id_numeric using "`here'/temp/holes_manager_sample", keep(3) keepusing(year_hole hole10_balance_ceo)
merge m:1 frame_id_numeric using "`here'/temp/holes_manager_sample_unique", keep(3) keepusing(year_hole)
sort frame_id_numeric year
browse frame_id_numeric person_id year year_hole

*log close
