*Betöltés
set more off
clear all
capture log close
log using output/firm_panel, text replace

* keep managers this many years before and after they start at a firm
local T 10

use temp/manager_panel

do fill_in_ceo


*Cégalapítás éve
bys frame_id: egen first_year=min(year)

*Adott ceo első megjelenése és utolsó kilépése
bys frame_id manager_id: egen enter_year=min(cond(ceo==1,year,.))
bys frame_id manager_id: egen exit_year=max(cond(ceo==1,year,.))

gen int tenure = year - enter_year
gen int firm_age = year - first_year
ren person_foreign expat

gen egy=1
* FIXME: keep stats on non-CEO managers
keep if ceo==1

keep if tenure<=`T'
* create pre years
egen firm_age_at_ceo_entry = mean(cond(tenure==0,firm_age,.)), by(frame_id manager_id)
gen pre_years = min(`T', firm_age_at_ceo_entry)
expand (tenure==0)*(pre_years+1), gen(expanded)
* fill in data for these years
bys expanded frame_id manager_id: replace tenure = -_n if expanded==1
replace year = enter_year+tenure if expanded==1

keep frame_id manager_id year tenure expat man_number firm_age

compress
save_all_to_json
save temp/firm_ceo_panel, replace
log close
