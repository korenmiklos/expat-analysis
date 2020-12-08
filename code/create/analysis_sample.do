clear all
* find root folder
here
local here = r(here)

use "`here'/temp/balance-small-clean.dta"
drop foreign

merge 1:1 frame_id year using "`here'/temp/firm_events.dta", nogen keep(match)

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
count if ever_expat & firm_tag

do "`here'/code/create/event_dummies_firmlevel.do"

compress
save "`here'/temp/analysis_sample.dta", replace
