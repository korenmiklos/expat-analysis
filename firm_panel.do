*Betöltés
set more off
clear all
capture log close
log using output/firm_panel, text replace

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

*Cégév szintre ejtés
/* how many ceos in a category? what is their lowest tenure? so that

manager_id      = 1 1 1 1 2 2 2 3 3 3
expat           = 0 0 0 0 1 1 1 0 0 0
tenure_expat    = . . . . 0 1 2 . . .
tenure_domestic = 0 1 2 3 . . . 0 1 2

*/
collapse (sum) N=egy (min) tenure (firstnm) N_total=man_number firm_age, by(frame_id year expat)
reshape wide N tenure, i(frame_id year) j(expat)
ren *0 *_domestic
ren *1 *_expat

mvencode N*, mv(0) override

label var N_total "Number of all managers"
label var N_domestic "Number of domestic CEOs"
label var N_expat "Number of expatriate CEOs"
label var tenure_domestic "Lowest tenure (domestic CEOs)"
label var tenure_expat "Lowest tenure (expatriate CEOs)"
label var firm_age "Firm age"

compress
save_all_to_json
save temp/firm_ceo_panel, replace
log close
