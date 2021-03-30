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
keep if start_as_domestic //& owner_spell <= 2

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

do "`here'/code/create/event_dummies_firmlevel.do"

egen industry_year = group(teaor08_1d year)

*for descriptives (number of firms and firm-years in final data)
codebook frame_id_numeric
count if firm_tag
count

compress
save "`here'/temp/analysis_sample.dta", replace

