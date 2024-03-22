here
local here = r(here)
use "`here'/input/ceo-panel/ceo-panel.dta", clear 
rename person_id manager_id

local western AT DE BE CA CH DE DK ES FR GB IT NL NO SE US IE US
local neighbor SK UA RO RS HR SI 
generate byte western = 0
foreach country in `western' {
    replace western = 1 if (country_code == "`country'")
}
generate byte neighbor = 0
foreach country in `neighbor' {
    replace neighbor = 1 if (country_code == "`country'")
}
egen byte ever_western = max(western), by(manager_id)
egen byte ever_neighbor = max(neighbor), by(manager_id)
replace ever_western = 0 if !first_address_foreign
replace ever_neighbor = 0 if !first_address_foreign

label define foreignness 0 "Hungarian name and address" 1 "Hungarian name, neighboring address" 3 "Hungarian name, other address" 2 "Foreign name, Hungarian address" 4 "Foreign name, non-Western address" 5 "Foreign name, Western address"
generate byte foreignness = 0 if !first_address_foreign & !foreign_name
replace foreignness = 1 if !foreign_name & ever_neighbor
replace foreignness = 2 if foreign_name & !first_address_foreign
replace foreignness = 3 if !foreign_name & !ever_neighbor & first_address_foreign
replace foreignness = 4 if foreign_name & !ever_western & first_address_foreign
replace foreignness = 5 if foreign_name & ever_western & first_address_foreign
label values foreignness foreignness

drop expat

tabulate foreignness, missing

compress
save "`here'/temp/ceo-panel.dta", replace
