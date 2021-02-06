clear all
* find root folder
here
local here = r(here)

use "`here'/temp/balance-small-clean.dta"
drop foreign
keep frame_id_numeric year originalid teaor08_1d teaor08_2d

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

* only keep D, F, D-F owner spells
bys frame_id_numeric: egen start_as_domestic = max((owner_spell == 1) & (foreign == 0))
* exclude F-D divestments but keep greenfield
keep if (start_as_domestic & owner_spell <= 2) | (!start_as_domestic & owner_spell == 1)

* check foreign end expat numbers
egen firm_tag = tag(frame_id_numeric)
count if ever_foreign & firm_tag
count if ever_expat & firm_tag

do "`here'/code/create/event_dummies_firmlevel.do"

merge 1:1 frame_id_numeric year using "input/owner-country/owner-country-panel.dta", keep(match master) nogen
rename country_list country_all_owner

egen industry_year = group(teaor08_1d year)
egen last_before_acquisition = max(cond(time_foreign<0, time_foreign, .)), by(originalid)

keep if year >= 1992 & year <= 2003

tempfile fy
save `fy', replace

do "`here'/code/create/countries.do"
merge 1:1 originalid year using "temp/trade.dta", keep(master match) nogen
mvencode export* import*, mv(0) override

keep originalid year export?? import?? import_capital?? import_material?? owner?? manager??

reshape long export import import_capital import_material owner manager, i(originalid year) j(country) string

* different combinations of owners and managers
generate byte both = owner & manager
generate byte either = owner | manager
generate byte only_owner = owner & !manager
generate byte only_manager = manager & !owner

do "`here'/code/create/lags.do" export import import_capital import_material owner manager both either only_owner only_manager
merge m:1 originalid year using `fy', keep(match) nogen

merge m:1 country using "`here'/temp/gravity.dta", keep(master match) nogen
generate ln_distance = ln(dist)
foreach X of var ln_distance German English contig {
	generate X`X' = Leither * `X'
}

egen cc = group(country)
compress
save "`here'/temp/analysis_sample_dyadic.dta", replace
