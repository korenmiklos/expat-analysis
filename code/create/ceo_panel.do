here
local here = r(here)
use "`here'/input/ceo-panel/ceo-panel.dta", clear 
rename person_id manager_id

local western AT DE BE CA CH DE DK ES FR GB IT NL NO SE US IE US
generate byte western = 0
foreach country in `western' {
    replace western = 1 if (country_code == "`country'")
}
egen byte ever_western = max(western), by(manager_id)
replace ever_western = 0 if !first_address_foreign

replace expat = (ever_western == 1)

compress
save "`here'/temp/ceo-panel.dta", replace
