*Betöltés
set more off
clear all
capture log close
log using output/firm_panel, text replace

use temp/balance-small
collapse (max) firm_death=year, by(frame_id)
tempfile sample
save `sample', replace

use temp/manager_panel, clear

* only keep sample firms
merge m:1 frame_id using `sample', keep(match) nogen
drop if year>firm_death

do fill_in_ceo

*Cégalapítás éve
bys frame_id: egen first_year=min(year)
egen id=group(frame_id manager_id)

*Adott ceo első megjelenése és utolsó kilépése
egen enter_year=min(cond(ceo==1,year,.)), by(frame_id manager_id)
egen exit_year=max(cond(ceo==1,year,.)), by(frame_id manager_id)
xtset id year
egen first_exit_year = min(cond(ceo==1 & F.ceo!=1, year, .)), by(frame_id manager_id)

* FIXME: keep stats on non-CEO managers
keep if ceo==1

gen int tenure = year - enter_year
gen int firm_age = year - first_year
ren person_foreign expat

* drop founders
drop if first_year==enter_year
scalar dropped_founders = r(N_drop)

collapse (min) enter_year first_exit_year (firstnm) expat (count) N_ceos=expat, by(frame_id manager_id)

compress
save_all_to_json
save temp/firm_ceo_panel, replace
log close
