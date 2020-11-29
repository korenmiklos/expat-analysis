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
keep frame_id_numeric manager_id job_spell year job_begin job_end expat founder insider outsider firm_birth foreign country_code

* if first managers arrive in year 1, extrapolate to year 0 - DROP SPELL
bys frame_id_numeric: egen first_cohort = min(job_begin)
replace job_begin = job_begin - 1 if (first_cohort == firm_birth + 1) & (job_begin == first_cohort)

* NOTE: no collapse and expand --> there might be holes
sort frame_id_numeric manager_id year
count if frame_id_numeric == frame_id_numeric[_n-1] & manager_id == manager_id[_n-1] & year != (year[_n-1] + 1)

* expat before 1990
replace expat = 0 if job_begin < 1990

***********************
* time invariant vars and drop entire series of firms from sample *
***********************
	by frame_id_numeric: egen first_year_expat = min(cond(expat == 1, job_begin,.))
	by frame_id_numeric: egen first_year_foreign = min(cond(foreign == 1, year,.))
	
	* which of the two happened first?
	generate manager_after_owner = first_year_expat - first_year_foreign
	* event time relative to that
	generate event_time = year - first_year_expat
	
	* if foreign manager arrives up to 2 years before 1 year later than foreign owner, use foreign manager as arrival date. this is easier to implement
	replace foreign = 1 if (manager_after_owner == -2) & inlist(event_time, 0, 1)
	replace foreign = 1 if (manager_after_owner == -1) & inlist(event_time, 0)
	replace foreign = 0 if (manager_after_owner == +1) & inlist(event_time, -1)

	* QUESTION: order of deletions (may be fine as all are firm level)
	* drop firms where expat arrives earlier than 2 years before owner
	drop if manager_after_owner < -2
	
	* ever expat and foreign created after foreign changes (drops were firm level before so should not mess with ever variables)
	foreach X of var expat foreign {
		by frame_id_numeric: egen ever_`X' = max(`X'==1)
	}

	* drop if there was an expat but was never foreign
	drop if ever_expat == 1 & ever_foreign == 0
	scalar dropped_do3_expat_firmyears = r(N_drop)
	
	* drop too many CEO-s - FIXME AND QUESTION: should be moved in the next file where spells are limited - but there cannot be created without manager level data
	egen fp_tag = tag(frame_id_numeric manager_id) 
	by frame_id_numeric: egen n_ceo_ever = sum(fp_tag)
	drop if n_ceo > 15
	scalar dropped_too_many_CEOs = r(N_drop)
	drop fp_tag n_ceo_ever
	
* hired or fired ceo since last observed year of firm - * POSSIBLE FIXME: expat, owner, insider, outsider, founder - hire, fire combinations later
tempvar previous_year
generate previous_year = .
forval t = 1985/2018 {
	by frame_id_numeric: egen `previous_year' = max(cond(year < `t', year, .))
	replace previous_year = `previous_year' if year == `t'
	drop `previous_year'
}

by frame_id_numeric: egen first_year = min(year)
bys frame_id_numeric (year): generate byte hire = cond(first_year == year, 1, (job_begin <= year) & (job_begin > previous_year))

tempvar next_year
generate next_year = .
forval t = 1985/2018 {
	by frame_id_numeric: egen `next_year' = min(cond(year > `t', year, .))
	replace next_year = `next_year' if year == `t'
	drop `next_year'
}

gen byte fire = ((job_end >= year) & (job_end < next_year))
tabulate hire fire 

gen hire_expat = hire * expat
gen fire_expat = fire * expat

* number of expats and locals
bys frame_id_numeric year: egen n_expat = total(cond(expat, 1, 0)) // could be in collapse but local not
bys frame_id_numeric year: egen n_local = total(cond(!expat, 1, 0))

* checking whether the same manager can come from different countries
sort frame_id_numeric manager_id year
count if (frame_id_numeric == frame_id_numeric[_n-1]) & (manager_id == manager_id[_n-1]) & (country_code != country_code[_n-1]) & country_code != "" & country_code[_n-1] != ""
count if (frame_id_numeric == frame_id_numeric[_n-1]) & (manager_id == manager_id[_n-1]) & (country_code != country_code[_n-1]) & country_code == "" & country_code[_n-1] != ""
*browse if (frame_id_numeric == frame_id_numeric[_n-1]) & (manager_id == manager_id[_n-1]) & (country_code != country_code[_n-1]) & country_code != "" & country_code[_n-1] != ""
*browse if (frame_id_numeric == frame_id_numeric[_n-1]) & (manager_id == manager_id[_n-1]) & (country_code != country_code[_n-1]) & country_code == "" & country_code[_n-1] != ""

* same manager with multiple countries changed to mode country
tab country_code expat, missing
bys frame_id_numeric manager_id: egen country_code_fill = mode(country_code), minmode
tab country_code_fill expat, missing

* same manager with multiple countries changed to mode country
bys manager_id: egen country_code_fill_manager = mode(country_code), minmode
tab country_code_fill_manager expat, missing

* checking whether the same manager can come from different countries after mode change
sort frame_id_numeric manager_id year
count if (frame_id_numeric == frame_id_numeric[_n-1]) & (manager_id == manager_id[_n-1]) & (country_code_fill != country_code_fill[_n-1]) & country_code_fill != "" & country_code_fill[_n-1] != ""
count if (frame_id_numeric == frame_id_numeric[_n-1]) & (manager_id == manager_id[_n-1]) & (country_code_fill != country_code_fill[_n-1]) & country_code_fill == "" & country_code_fill[_n-1] != ""

* checking whether there are expats from multiple countries in a given year
sort frame_id_numeric year manager_id
count if (frame_id_numeric == frame_id_numeric[_n-1]) & (year == year[_n-1]) & country_code_fill != "" & country_code_fill[_n-1] != "" & n_expat > 1
count if (frame_id_numeric == frame_id_numeric[_n-1]) & (year == year[_n-1]) & (country_code_fill != country_code_fill[_n-1]) & country_code_fill != "" & country_code_fill[_n-1] != "" & n_expat > 1
count if (frame_id_numeric == frame_id_numeric[_n-1]) & (year == year[_n-1]) & (country_code_fill == country_code_fill[_n-1]) & country_code_fill != "" & country_code_fill[_n-1] != "" & n_expat > 1
count

* adding all country codes for one firm-year into one variable
preserve
duplicates drop frame_id_numeric year country_code_fill, force
replace country_code_fill = "missing" if country_code_fill == ""

forval i = 1/4 {
	bys frame_id_numeric year: gen country_`i' = country_code_fill[`i']
}

gen country_all = country_1 + "," +country_2  + "," +country_3
replace country_all = subinstr(country_all,",,","",.)
replace country_all = substr(country_all, 1, length(country_all) - 1) if substr(country_all, -1, 1) ==  ","

duplicates drop frame_id_numeric year, force

tempfile countries
save `countries'
restore

merge m:1 frame_id_numeric year using `countries', nogen keepusing(country_all)
count

* create firm-year data
* FIXME: country_code may be different within a firm-year
collapse (sum) n_founder = founder n_insider = insider n_outsider = outsider (firstnm) n_expat n_local foreign ever_expat ever_foreign country_code = country_all (count) n_ceo = expat (max) hire_ceo = hire fire_ceo = fire hire_expat fire_expat, by(frame_id_numeric year)

* managers in first year not classified as new hires and in last year not classified as fired
bys frame_id_numeric (year): replace hire_ceo = 0 if (_n==1)
bys frame_id_numeric (year): replace fire_ceo = 0 if (_n==_N)
bys frame_id_numeric (year): replace hire_expat = 0 if (_n==1)
bys frame_id_numeric (year): replace fire_expat = 0 if (_n==_N)
bys frame_id_numeric (year): gen ceo_spell = sum(hire_ceo | fire_ceo) + 1 // so that index start from 1

* create dummies from numbers
foreach var in expat local founder insider outsider {
	gen has_`var' = (n_`var' > 0)
}

count

compress
save_all_to_json
save "temp/firm_events.dta", replace
log close
