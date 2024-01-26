clear all

* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/analysis_sample", text replace

use "`here'/temp/balance-small-clean.dta"
drop foreign

merge 1:1 frame_id year using "`here'/temp/firm_events.dta", keep(match) nogen

* many foreign changes deleted
bys frame_id_numeric (year): gen owner_spell = sum(foreign != foreign[_n-1])
bys frame_id_numeric (year): egen owner_spell_total = total(foreign != foreign[_n-1])
tabulate owner_spell_total

drop if owner_spell_total > 3 

* divestment
bys frame_id_numeric (year): gen divest = sum(owner_spell != owner_spell[_n-1] & foreign == 0 & _n != 1)
replace divest = 1 if divest > 0

* only D, D-F F owner spells
bys frame_id_numeric: egen start_as_domestic = max((owner_spell == 1) & (foreign == 0))
tabulate start_as_domestic
keep if start_as_domestic
keep if owner_spell <= 2
drop if divest == 1

drop owner_spell_total divest start_as_domestic

* check foreign and expat numbers
egen firm_tag = tag(frame_id_numeric)

count if ever_foreign
count if ever_foreign & firm_tag
count if ever_expat & firm_tag

count if has_expat_ceo == 1
count if has_expat_ceo == 1 & foreign == 0 
count if ever_expat == 1 & ever_foreign == 0

egen industry_year = group(teaor08_1d year)

*for descriptives (number of firms and firm-years in final data)
codebook frame_id_numeric
count if firm_tag
count

drop first_year_foreign time_foreign 

count
count if ever_foreign
count if ever_foreign & firm_tag
count if ever_expat & firm_tag
count if has_expat_ceo

drop ever_expat ever_foreign
egen ever_foreign = max(foreign), by(frame_id_numeric)
* did new foreign owner hire any ceos?
egen ever_foreign_hire = max((hire_ceo == 1) & (foreign == 1) & (owner_spell == 2)), by(frame_id_numeric)
generate foreign_hire = ever_foreign_hire & foreign

* check the patterns of expat - local transitions. 
local ceo has_expat_ceo
bys frame_id_numeric (year): generate ceo_foreign_spell = sum(`ceo' != `ceo'[_n-1])

keep if ever_foreign == 1
keep if ever_foreign_hire
* no variation in these, drop
drop ever_foreign ever_foreign_hire

egen ever_expat = max(has_expat_ceo & ceo_foreign_spell==2), by(frame_id_numeric)
generate ever_local = !ever_expat
generate local_ceo = foreign_hire & ever_local
* to ensure staggered treatment - this is intent to treat estimate
replace has_expat_ceo = foreign_hire & ever_expat

egen first_year_foreign = min(cond(foreign==1, year, .)), by(frame_id_numeric) 
generate time_foreign = year - first_year_foreign

* drop if local hires are much later replaced by expats
drop if ever_local & has_expat_ceo

tabulate local_ceo has_expat_ceo
tabulate ever_expat ever_local if time_foreign == 0

* limit sample to event window
keep if inrange(time_foreign, -10, 5)

egen exporter_pre = max(exporter & (time_foreign < 0)), by(frame_id_numeric)

compress
save "`here'/temp/analysis_sample.dta", replace
log close
