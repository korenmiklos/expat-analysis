*Betöltés
set more off
clear all
capture log close
log using output/firm_panel, text replace

use temp/balance-small
*Tempvars were created for some reason when I was closing the previous file
*drop __* - deleted in select_sample
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

* flag founders
gen byte founder = (first_year==enter_year)
drop if year<enter_year | year>first_exit_year

* count number of CEOs
preserve
	collapse (count) N_ceos = expat, by(frame_id year)
	save temp/N_ceos, replace
restore

collapse (min) enter_year first_exit_year (firstnm) expat founder, by(frame_id manager_id)

gen byte spell = 1
bysort frame_id (enter_year manager_id): replace spell =  cond(enter_year>enter_year[_n-1],spell[_n-1]+1,spell[_n-1]) if _n>1

egen max_expat = max(expat), by(frame_id spell)
tempvar lag_expat
gen `lag_expat' = .
bysort frame_id (enter_year manager_id): replace `lag_expat' = max_expat[_n-1] if _n>1 & enter_year>enter_year[_n-1]
egen lag_expat = mean(`lag_expat'), by(frame_id spell)
assert lag_expat==0 | lag_expat==1 | (missing(lag_expat) & spell==1)

compress
save_all_to_json
save temp/firm_ceo_panel, replace
log close
