*cd /// setting the folder

use "temp/analysis_sample.dta", clear

bys frame_id_numeric (year): egen ever_foreign = max(foreign)
egen firm_tag = tag(frame_id_numeric)

count
count if start_as_domestic == 1 & owner_spell <= 2

count if ever_foreign & firm_tag
count if ever_foreign & firm_tag & start_as_domestic == 1 & owner_spell <= 2

keep if ever_foreign & firm_tag

tostring(frame_id_numeric), generate(frame_id)
replace frame_id = "ft" + frame_id

save "temp/frameid_ever_foreign.dta", replace
