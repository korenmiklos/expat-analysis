*Betöltés
set more off
clear all
capture log close
log using output/firm_panel, text replace

* keep only sample from balance-small - NOTE: had to restructure as we have to keep foreign which is different in years - so no collapse this time
use "temp/balance-small-clean.dta"
by frame_id_numeric: egen firm_birth = min(year)
by frame_id_numeric: egen firm_death = max(year)
keep frame_id year firm_birth firm_death foreign
tempfile sample
save `sample', replace

use "input/ceo-panel/ceo-panel.dta", clear // QUESTION: what is owner
rename person_id manager_id

* only keep sample firms
merge m:1 frame_id_numeric year using `sample', keep(match) nogen
count if first_year_of_firm == firm_birth // QUESTION: why not the same? - same for the last year

* balance panel
egen company_manager_id = group(frame_id manager_id)
xtset company_manager_id year
by company_manager_id: generate gap = year - year[_n-1] - 1
replace gap = 0 if missing(gap)
tabulate gap

* fill in gap if only 1-year long
expand 1 + (gap == 1), generate(filled_in) // FIXME OR QUESTION: maybe second year as well
replace year = year - 1 if filled_in
xtset company_manager_id year
xtdescribe

* create contiguous spells
gen change = ceo != L.ceo 
bysort company_manager_id (year): gen job_spell = sum(change)

* create job begin and end for each manager spell
bys frame_id_numeric manager_id job_spell: egen job_begin = min(year)
bys frame_id_numeric manager_id job_spell: egen job_end = max(year)
keep frame_id_numeric manager_id job_spell year job_begin job_end expat founder insider outsider firm_birth foreign

* if first managers arrive in year 1, extrapolate to year 0 - DROP SPELL
bys frame_id_numeric: egen first_cohort = min(job_begin)
replace job_begin = job_begin - 1 if (first_cohort == firm_birth + 1) & (job_begin == first_cohort)

gen byte spell = 1
bysort frame_id (job_begin manager_id): replace spell =  cond(job_begin > job_begin[_n-1], spell[_n-1]+1, spell[_n-1]) if _n>1

compress
save_all_to_json
save "temp/firm_events.dta", replace
log close
