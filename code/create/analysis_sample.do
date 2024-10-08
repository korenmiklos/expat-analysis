clear all

* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/analysis_sample", text replace

use "`here'/temp/balance-small-clean.dta"
drop foreign

merge 1:1 frame_id_numeric year using "`here'/temp/firm_events.dta", keep(match) nogen

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

count if ever_foreign
count if ever_foreign & firm_tag
count if ever_expat & firm_tag
count if has_expat_ceo

drop ever_expat ever_foreign
egen ever_foreign = max(foreign), by(frame_id_numeric)
* did new foreign owner hire any ceos?
egen ever_foreign_hire = max((hire_ceo == 1) & (foreign == 1) * (owner_spell == 2)), by(frame_id_numeric)
generate foreign_hire = ever_foreign_hire & foreign

* check the patterns of expat - local transitions. 
local ceo has_expat_ceo
bys frame_id_numeric (year): generate ceo_foreign_spell = sum(`ceo' != `ceo'[_n-1])

* drop after first expat leaves
drop if ceo_foreign_spell > 2
drop if ceo_foreign_spell == 2 & has_expat_ceo == 0

keep if ever_foreign == 1

generate foreign_only = foreign & !foreign_hire
generate local_ceo = foreign_hire & !has_expat_ceo
egen ever_local_ceo = max(local_ceo), by(frame_id_numeric)

* drop if local hires are much later replaced by expats
drop if ever_local_ceo & has_expat_ceo
* sometimes we refer to the short name
clonevar ever_local = ever_local_ceo

tabulate foreign_only foreign_hire
tabulate local_ceo has_expat_ceo

keep if ever_foreign_hire
* no variation in these, drop
drop ever_foreign ever_foreign_hire

egen first_year_foreign = min(cond(foreign==1, year, .)), by(frame_id_numeric) 
generate time_foreign = year - first_year_foreign

egen ever_expat = max(has_expat_ceo), by(frame_id_numeric)

* limit sample to event window
keep if inrange(time_foreign, -6, 4)

egen exporter_pre = max(exporter & inrange(time_foreign, -3, -1)), by(frame_id_numeric)
* different ways of measuring export orientation
clonevar export_entry = exporter
replace export_entry = . if exporter_pre == 1

*Create teaor in year -1, drop agriculture

egen teaor08_1d_num = group(teaor08_1d)
tempvar last_year_before 
egen `last_year_before' = max(cond(time_foreign < 0, year,.)), by(frame_id_numeric)
drop if missing(`last_year_before')

egen teaor08_2d_pre = max(cond(year==`last_year_before', teaor08_2d, .)), by(frame_id_numeric)
egen teaor08_1d_pre = max(cond(year==`last_year_before', teaor08_1d_num, .)), by(frame_id_numeric)
assert !missing(teaor08_2d_pre)
drop `last_year_before'

* compute TFP

local agriculture 1 3
local industry 5 39
local services 40 75

keep if inrange(teaor08_2d_pre, 1, 75)
* drop finance
drop if inrange(teaor08_2d_pre, 64, 66)

* tradable as defined by OECD https://doi.org/10.1787/888933707836
generate byte tradable_sector = 0
replace tradable_sector = 1 if inrange(teaor08_2d_pre, 1, 39)
replace tradable_sector = 1 if inrange(teaor08_2d_pre, 58, 63)

generate TFP = .
tempvar TFP
foreach sector in agriculture industry services {
    local from : word 1 of ``sector''
    local to : word 2 of ``sector''
    quietly reghdfe lnQ lnK lnL lnM if inrange(teaor08_2d_pre, `from', `to'), absorb(i.teaor08_2d##i.year) resid
    predict `TFP', resid
    replace TFP = `TFP' if inrange(teaor08_2d_pre, `from', `to')
    * if singleton in sector, use average TFP of 0
    replace TFP = 0 if missing(TFP) & inrange(teaor08_2d_pre, `from', `to') & !missing(lnQ, lnK, lnL, lnM)
    drop `TFP'
}

tabulate foreignness has_expat_ceo
tabulate time_foreign foreignness if inrange(time_foreign, -2, 2) & ever_expat 

* keep only western foreigners and locals with Hungarian names
egen always0 = min(foreignness == 0), by(frame_id_numeric )
egen ever5 = max(foreignness == 5), by(frame_id_numeric )
tab always0 ever5 
keep if always0 | ever5 
drop always0 ever5

tabulate time_foreign has_expat_ceo 
xtset frame_id_numeric year

*Industrial firms
generate industrial_pre = inrange(teaor08_2d_pre, 5, 39)

*Tradable sectors (up to TEAOR 75)
generate tradable_nonservice = inrange(teaor08_2d_pre, 1, 35)
generate tradable_service = inlist(teaor08_2d_pre, 50, 51, 52, 58, 59, 60, 61, 62, 63, 69, 70, 71, 72, 73, 74) 
drop tradable_sector
generate tradable_sector = (tradable_nonservice==1 | tradable_service==1)

*Time of treatment
egen time_treat = min(cond(time_foreign==0, year, .)), by(frame_id_numeric)

*Variables for descriptives
egen time_treat_1990s = max(time_treat<2000), by(frame_id_numeric)
generate time_tradable_int = time_treat_1990s*tradable_sector

*Missing Qd before and after treatment
foreach Y in lnQd {
	egen `Y'_exist_pre = max(cond(!missing(`Y') & time_foreign<0, 1, 0)), by(frame_id_numeric)
	egen `Y'_exist_post = max(cond(!missing(`Y') & time_foreign>=0, 1, 0)), by(frame_id_numeric)
}

egen lnQd_missing = max(cond(missing(lnQd), 1, 0)), by(frame_id_numeric)
count if missing(lnQd) & lnQd_exist_pre==1 & lnQd_exist_post==1
*74 cases, 0.57%

*Variable labels
label var industrial_pre "Industrial Firm"
label var emp "Employment"
label var TFP "TFP"
label var tradable_sector "Tradable Sector"
label var time_treat_1990s "Early Acquisition"
label var export_share "Export Share"
label var local_ceo "Local CEO"
label var has_expat_ceo "Expatriate CEO"
label var lnK "Capital"
label var lnL "Labor"
label var lnQ "Sales"
label var lnQd "Domestic Sales"
label var lnKL "Capital-Labor Ratio"
label var ever_expat "Expatriate CEO"

* limit sample to event window
keep if inrange(time_foreign, -4, 4) 

compress
save "`here'/temp/analysis_sample.dta", replace
log close
