here
local here = r(here)
use "`here'/input/ceo-panel/ceo-panel.dta", clear 
rename person_id manager_id

local western AT DE BE CA CH DK ES FR GB IT NL NO SE US IE US IL KO JP
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

generate originalid = frame_id_numeric
* special case some manually checked firms
* these are all Hungarian firms with Hungarian names and addresses
replace foreign_name = 0 if inlist(originalid, 11941712, 10362675, 12282799, 12566947, 13448064)

* these 40 names are cleary of Western origin
replace ever_western = 1 if originalid==10741973
replace ever_western = 1 if originalid==14655380
replace ever_western = 1 if originalid==24690210
replace ever_western = 1 if originalid==10414648
replace ever_western = 1 if originalid==10543294
replace ever_western = 1 if originalid==10751161
replace ever_western = 1 if originalid==11064899
replace ever_western = 1 if originalid==11077200
replace ever_western = 1 if originalid==11101291
replace ever_western = 1 if originalid==11179924
replace ever_western = 1 if originalid==11854463
replace ever_western = 1 if originalid==13212366
replace ever_western = 1 if originalid==14995806
replace ever_western = 1 if originalid==22592903
replace ever_western = 1 if originalid==23383636
replace ever_western = 1 if originalid==11182232
replace ever_western = 1 if originalid==11924717
replace ever_western = 1 if originalid==10548938
replace ever_western = 1 if originalid==11225685
replace ever_western = 1 if originalid==12106282
replace ever_western = 1 if originalid==12152104
replace ever_western = 1 if originalid==12206928
replace ever_western = 1 if originalid==12395073
replace ever_western = 1 if originalid==12691908
replace ever_western = 1 if originalid==12860777
replace ever_western = 1 if originalid==14068012
replace ever_western = 1 if originalid==12492455
replace ever_western = 1 if originalid==11142755
replace ever_western = 1 if originalid==11087388
replace ever_western = 1 if originalid==12353817
replace ever_western = 1 if originalid==26100667
replace ever_western = 1 if originalid==10640384
replace ever_western = 1 if originalid==10751642
replace ever_western = 1 if originalid==12509166
replace ever_western = 1 if originalid==12722312
replace ever_western = 1 if originalid==11192145
replace ever_western = 1 if originalid==10804472
replace ever_western = 1 if originalid==12158485
replace ever_western = 1 if originalid==11898353
replace ever_western = 1 if originalid==10732803

drop originalid

label define foreignness 0 "Hungarian name and address" 1 "Hungarian name, neighboring address" 3 "Hungarian name, other address" 2 "Foreign name, Hungarian address" 4 "Foreign name, non-Western address" 5 "Foreign name, Western address"
generate byte foreignness = 0 if !first_address_foreign & !foreign_name
replace foreignness = 1 if !foreign_name & ever_neighbor
replace foreignness = 2 if foreign_name & !first_address_foreign
replace foreignness = 3 if !foreign_name & !ever_neighbor & first_address_foreign
replace foreignness = 4 if foreign_name & !ever_western & first_address_foreign
replace foreignness = 5 if ever_western
label values foreignness foreignness

drop expat

tabulate foreignness, missing

compress
save "`here'/temp/ceo-panel.dta", replace
