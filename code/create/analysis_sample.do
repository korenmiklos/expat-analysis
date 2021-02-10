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
egen last_before_acquisition = max(cond(time_foreign<0, time_foreign, .)), by(frame_id_numeric)

keep if year >= 1992 & year <= 2003

tempfile fy
save `fy', replace

do "`here'/code/create/countries.do"
merge 1:1 originalid year using "temp/trade.dta", keep(master match) nogen
mvencode export* import*, mv(0) override

keep frame_id_numeric year export?? export_rauch?? export_nonrauch?? export_consumer?? import?? import_rauch?? import_nonrauch?? import_consumer?? import_capital?? import_material?? owner?? manager??

* only reshape trade so that we can compute distance measures between where owners are from and where this firm is trading
reshape long export export_rauch export_nonrauch export_consumer import import_rauch import_nonrauch import_consumer import_capital import_material, i(frame_id_numeric year) j(country) string
local vars distance contig comlang
levelsof country
local countries = r(levels)
foreach role in owner manager {
	* do long reshape manually
	generate byte `role' = 0
	foreach country in `countries' {
		generate str2 iso2_o = "`country'" if `role'`country' == 1
		merge m:1 iso2_o country using "`here'/temp/gravity.dta", keep(master match) nogen
		foreach X of var `vars' {
			rename `X' `role'_`X'`country'
		}
		drop iso2_o
		* turn on dummy of owner/manager is from the same country
		replace `role' = 1 if (`role'`country' == 1) & (country == "`country'")
	}
	* find the closest owner/manager in all dimensions
	egen byte `role'_contig = rmax(`role'_contig??)
	egen byte `role'_comlang = rmax(`role'_comlang??)
	egen `role'_distance = rmin(`role'_distance??)
	drop *`role'?? `role'_contig?? `role'_comlang?? `role'_distance??
}
* if no foreign managers, replace distance variables with 0 - these are soaked up in the firm-country fixed effects
mvencode *er_contig *er_comlang *er_distance, mv(0) override

* different combinations of owners and managers
generate byte both = owner & manager
generate byte either = owner | manager
generate byte only_owner = owner & !manager
generate byte only_manager = manager & !owner

do "`here'/code/create/lags.do" export import import_capital import_material owner manager both either only_owner only_manager owner_contig owner_comlang manager_contig manager_comlang
* lag distance
tempvar mindist
foreach role in owner manager {
	generate L`role'_distance = 0
	forvalues t = 1992/2003 {
		egen `mindist' = min(cond(`role'_distance!=0 & year < `t', `role'_distance, .)), by(frame_id_numeric country)
		replace L`role'_distance = `mindist' if year == `t' & !missing(`mindist')
		drop `mindist'
	}
	mvencode L`role'_distance, mv(0) override
}

merge m:1 frame_id_numeric year using `fy', keep(match) nogen

egen cc = group(country)
compress
save "`here'/temp/analysis_sample_dyadic.dta", replace
