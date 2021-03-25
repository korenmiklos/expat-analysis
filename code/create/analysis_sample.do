clear all
* find root folder
here
local here = r(here)

use "`here'/temp/balance-small-clean.dta"
drop foreign

merge 1:1 frame_id year using "`here'/temp/firm_events.dta", nogen keep(match)

rename foreign_ceo foreign
rename ever_foreign_ceo ever_foreign
drop foreign_nceo ever_foreign_nceo

*nceo overriden to have zeros
mvencode *_nceo, mv(0) override

* many foreign changes deleted
bys frame_id_numeric (year): gen owner_spell = sum(foreign != foreign[_n-1])
bys frame_id_numeric (year): egen owner_spell_total = total(foreign != foreign[_n-1])

drop if owner_spell_total > 3 // FIXME: doublecheck the length of spells
scalar dropped_too_many_foreign_change = r(N_drop)
display dropped_too_many_foreign_change

* divestiture
bys frame_id_numeric (year): gen divest = sum(cond(owner_spell != owner_spell[_n-1] & foreign == 0 & _n != 1, 1, 0))
replace divest = 1 if divest > 0

* only keep D, D-F owner spells
bys frame_id_numeric: egen start_as_domestic = max((owner_spell == 1) & (foreign == 0))
keep if start_as_domestic & owner_spell <= 2

* check foreign end expat numbers
egen firm_tag = tag(frame_id_numeric)
count if ever_foreign & firm_tag
count if ever_expat_ceo & firm_tag
count if ever_expat_nceo & firm_tag

count if has_expat_nceo == 1
count if has_expat_nceo == 1 & foreign == 0
count if has_expat_ceo == 1
count if has_expat_ceo == 1 & foreign == 0 // FIXME - should be 0
count if ever_expat_nceo == 1 & ever_foreign == 0
count if ever_expat_ceo == 1 & ever_foreign == 0

*do "`here'/code/create/event_dummies_firmlevel.do"

*merge 1:1 originalid year using "input/fo3-owner-names/country_codes.dta", keep(match master) nogen
* "same country" only applies to expats at foreign firms
*replace country_same = 0 if (has_expat == 0) | (foreign == 0)

egen industry_year = group(teaor08_1d year)
*egen last_before_acquisition = max(cond(time_foreign<0, time_foreign, .)), by(originalid)
*egen ever_same_country = max(country_same), by(originalid)

*do "`here'/code/create/countries.do"

*for descriptives (number of firms and firm-years in final data)
codebook frame_id_numeric
count if firm_tag
count

compress
save "`here'/temp/analysis_sample.dta", replace

*for descriptives (number of ceo-s and nceo-s in final data, number of ceo and nceo job-spells in final data) - part III
foreach type in ceo nceo {
	use "`here'/temp/analysis_sample.dta", clear
	merge 1:m frame_id_numeric year using "`here'/temp/raw_`type'.dta", nogen keep(match)
	count
	egen company_manager_id = group(frame_id_numeric manager_id)
	codebook manager_id
	codebook company_manager_id
	save "`here'/temp/analysis_sample_manager_`type'.dta", replace
}
