here
local here = r(here)
use "`here'/input/ceo-panel/ceo-panel.dta", clear 
rename person_id manager_id

local western AT DE BE CA CH DE DK ES FR GB IT NL NO SE US IE US IL KO JP
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
replace foreign_name = 0 if inlist(originalid, 11941712, 10362675, 12282799, 12566947, 13448064, 10216770, 10441628, 11245652, 12862865, 12914539, 22781684, 23464997)

* these 73 names are clearly of Western origin
replace ever_western = 1 if originalid==10741973 & foreign_name==1
replace ever_western = 1 if originalid==14655380 & foreign_name==1
replace ever_western = 1 if originalid==24690210 & foreign_name==1
replace ever_western = 1 if originalid==10414648 & foreign_name==1
replace ever_western = 1 if originalid==10543294 & foreign_name==1
replace ever_western = 1 if originalid==10751161 & foreign_name==1
replace ever_western = 1 if originalid==11064899 & foreign_name==1
replace ever_western = 1 if originalid==11077200 & foreign_name==1
replace ever_western = 1 if originalid==11101291 & foreign_name==1
replace ever_western = 1 if originalid==11179924 & foreign_name==1
replace ever_western = 1 if originalid==11854463 & foreign_name==1
replace ever_western = 1 if originalid==13212366 & foreign_name==1
replace ever_western = 1 if originalid==14995806 & foreign_name==1
replace ever_western = 1 if originalid==22592903 & foreign_name==1
replace ever_western = 1 if originalid==23383636 & foreign_name==1
replace ever_western = 1 if originalid==11182232 & foreign_name==1
replace ever_western = 1 if originalid==11924717 & foreign_name==1
replace ever_western = 1 if originalid==10548938 & foreign_name==1
replace ever_western = 1 if originalid==11225685 & foreign_name==1
replace ever_western = 1 if originalid==12106282 & foreign_name==1
replace ever_western = 1 if originalid==12152104 & foreign_name==1
replace ever_western = 1 if originalid==12206928 & foreign_name==1
replace ever_western = 1 if originalid==12395073 & foreign_name==1
replace ever_western = 1 if originalid==12691908 & foreign_name==1
replace ever_western = 1 if originalid==12860777 & foreign_name==1
replace ever_western = 1 if originalid==14068012 & foreign_name==1
replace ever_western = 1 if originalid==12492455 & foreign_name==1
replace ever_western = 1 if originalid==11142755 & foreign_name==1
replace ever_western = 1 if originalid==11087388 & foreign_name==1
replace ever_western = 1 if originalid==12353817 & foreign_name==1
replace ever_western = 1 if originalid==26100667 & foreign_name==1
replace ever_western = 1 if originalid==10640384 & foreign_name==1
replace ever_western = 1 if originalid==10751642 & foreign_name==1
replace ever_western = 1 if originalid==12509166 & foreign_name==1
replace ever_western = 1 if originalid==12722312 & foreign_name==1
replace ever_western = 1 if originalid==11192145 & foreign_name==1
replace ever_western = 1 if originalid==10804472 & foreign_name==1
replace ever_western = 1 if originalid==12158485 & foreign_name==1
replace ever_western = 1 if originalid==11898353 & foreign_name==1
replace ever_western = 1 if originalid==10732803 & foreign_name==1
replace ever_western = 1 if originalid==13871275 & foreign_name==1
replace ever_western = 1 if originalid==10067710 & foreign_name==1
replace ever_western = 1 if originalid==10213454 & foreign_name==1
replace ever_western = 1 if originalid==10317871 & foreign_name==1
replace ever_western = 1 if originalid==10353581 & foreign_name==1
replace ever_western = 1 if originalid==10382312 & foreign_name==1
replace ever_western = 1 if originalid==10428627 & foreign_name==1
replace ever_western = 1 if originalid==10456732 & foreign_name==1
replace ever_western = 1 if originalid==10541326 & foreign_name==1
replace ever_western = 1 if originalid==10587328 & foreign_name==1
replace ever_western = 1 if originalid==10669848 & foreign_name==1
replace ever_western = 1 if originalid==10692082 & foreign_name==1
replace ever_western = 1 if originalid==10777189 & foreign_name==1
replace ever_western = 1 if originalid==10815379 & foreign_name==1
replace ever_western = 1 if originalid==11018908 & foreign_name==1
replace ever_western = 1 if originalid==11115658 & foreign_name==1
replace ever_western = 1 if originalid==11119700 & foreign_name==1
replace ever_western = 1 if originalid==11487018 & foreign_name==1
replace ever_western = 1 if originalid==11504656 & foreign_name==1
replace ever_western = 1 if originalid==12281262 & foreign_name==1
replace ever_western = 1 if originalid==12550904 & foreign_name==1
replace ever_western = 1 if originalid==12581555 & foreign_name==1
replace ever_western = 1 if originalid==12619849 & foreign_name==1
replace ever_western = 1 if originalid==12622810 & foreign_name==1
replace ever_western = 1 if originalid==12624197 & foreign_name==1
replace ever_western = 1 if originalid==12813469 & foreign_name==1
replace ever_western = 1 if originalid==13025481 & foreign_name==1
replace ever_western = 1 if originalid==13497941 & foreign_name==1
replace ever_western = 1 if originalid==13639651 & foreign_name==1
replace ever_western = 1 if originalid==13717108 & foreign_name==1
replace ever_western = 1 if originalid==14904134 & foreign_name==1
replace ever_western = 1 if originalid==20679570 & foreign_name==1
replace ever_western = 1 if originalid==22658948 & foreign_name==1

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
