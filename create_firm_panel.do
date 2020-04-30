*Betöltés
set more off
clear all
capture log close
log using output/firm_panel, text replace

use "temp/balance-small.dta"
*Tempvars were created for some reason when I was closing the previous file
*drop __* - deleted in select_sample
collapse (min) firm_birth = year (max) firm_death = year, by(frame_id)
tempfile sample
save `sample', replace

use "input/ceo-panel/ceo-panel.dta", clear
rename person_id manager_id

* only keep sample firms
merge m:1 frame_id using `sample', keep(match) nogen
drop if year>firm_death

* balance panel
egen company_manager = group(frame_id manager_id)
xtset company_manager year
by company_manager: generate gap = year - year[_n-1] - 1
replace gap = 0 if missing(gap)
tabulate gap

* fill in gap if only 1-year long
expand 1+(gap==1), generate(filled_in)
replace year = year - 1 if filled_in
xtset company_manager year
xtdescribe

* create contiguous spells
gen change = ceo != L.ceo 
bysort company_manager (year): gen job_spell = sum(change)

* count number of CEOs
preserve
	collapse (count) N_ceos = expat, by(frame_id year)
	save temp/N_ceos, replace
restore

collapse (min) job_begin = year (max) job_end = year (firstnm) expat manager_category firm_birth, by(frame_id manager_id job_spell)

* if first managers arrive in year 1, extrapolate to year 0
egen first_cohort = min(job_begin), by(frame_id)
replace job_begin = job_begin - 1 if (first_cohort == firm_birth + 1) & (job_begin == first_cohort)

gen byte spell = 1
bysort frame_id (job_begin manager_id): replace spell =  cond(job_begin > job_begin[_n-1], spell[_n-1]+1, spell[_n-1]) if _n>1

egen max_expat = max(expat), by(frame_id spell)
tempvar lag_expat
gen `lag_expat' = .
bysort frame_id (job_begin manager_id): replace `lag_expat' = max_expat[_n-1] if _n>1 & job_begin > job_begin[_n-1]
egen lag_expat = mean(`lag_expat'), by(frame_id spell)
assert lag_expat==0 | lag_expat==1 | (missing(lag_expat) & spell==1)

compress
save_all_to_json
save "temp/firm_ceo_panel.dta", replace
log close
