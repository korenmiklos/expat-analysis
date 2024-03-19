here
local here = r(here)
use "`here'/input/ceo-panel/ceo-panel.dta", clear 
rename person_id manager_id
replace expat = (foreign_name == 1) | (foreign_address == 1)

compress
save "`here'/temp/ceo-panel.dta", replace
