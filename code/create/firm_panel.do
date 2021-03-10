*Betöltés
set more off
clear all
capture log close

* find root folder
here
local here = r(here)

log using "`here'/output/firm_panel", text replace

* keep only sample from balance-small - NOTE: had to restructure as we have to keep foreign which is different in years - so no collapse this time
use "`here'/temp/balance-small-clean.dta"
by frame_id_numeric: egen firm_birth = min(year)
by frame_id_numeric: egen firm_death = max(year)
keep frame_id year firm_birth firm_death foreign
tempfile sample
save `sample', replace

use "`here'/input/ceo-other-panel/ceo-other-panel.dta", clear // QUESTION: what is owner
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
tab position
gen change_ceo = ceo != L.ceo 
*gen change = position != L.position 
*tab change_ceo change
bysort company_manager_id (year): gen job_spell = sum(change)

* create job begin and end for each manager spell
bys frame_id_numeric manager_id job_spell: egen job_begin = min(year)
bys frame_id_numeric manager_id job_spell: egen job_end = max(year)
keep frame_id_numeric manager_id job_spell year job_begin job_end expat founder insider outsider firm_birth foreign country_code position

* if first managers arrive in year 1, extrapolate to year 0 - DROP SPELL
bys frame_id_numeric: egen first_cohort = min(job_begin)
replace job_begin = job_begin - 1 if (first_cohort == firm_birth + 1) & (job_begin == first_cohort)

* NOTE: no collapse and expand --> there might be holes
sort frame_id_numeric manager_id year
count if frame_id_numeric == frame_id_numeric[_n-1] & manager_id == manager_id[_n-1] & year != (year[_n-1] + 1)

* expat before 1990
replace expat = 0 if job_begin < 1990

foreach var in expat founder insider outsider {
	gen `var'_ceo = (`var' & position == 1)
	gen `var'_other = (`var' & position == 2)
}

tab expat expat_ceo
tab expat expat_other
tab expat_other expat_ceo

***********************
* time invariant vars and drop entire series of firms from sample *
***********************
	by frame_id_numeric: egen first_year_expat = min(cond(expat == 1, job_begin,.))
	by frame_id_numeric: egen first_year_expat_other = min(cond(expat_other, job_begin,.))
	by frame_id_numeric: egen first_year_expat_ceo = min(cond(expat_ceo, job_begin,.))
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
	foreach X of var expat* foreign {
		by frame_id_numeric: egen ever_`X' = max(`X'==1)
	}

	* drop if there was an expat but was never foreign
	drop if ever_expat == 1 & ever_foreign == 0
	scalar dropped_do3_expat_firmyears = r(N_drop)
	
	* drop too many CEO-s - FIXME AND QUESTION: should be moved in the next file where spells are limited - but there cannot be created without manager level data
	*egen fp_tag = tag(frame_id_numeric manager_id)
	bys frame_id_numeric manager_id: gen fp_tag_ceo = cond(position == 1,1,.) if _n == 1
	*bys frame_id_numeric manager_id: gen fp_tag2 = 1 if _n == 1
	*tab fp_tag fp_tag2
	by frame_id_numeric: egen n_ceo_ever = sum(fp_tag_ceo)
	*by frame_id_numeric: egen n_manager_ever = sum(fp_tag)
	drop if n_ceo_ever > 15
	scalar dropped_too_many_CEOs = r(N_drop)
	drop fp_tag_ceo n_ceo_ever
	
* hired or fired ceo since last observed year of firm - * POSSIBLE FIXME: expat, owner, insider, outsider, founder - hire, fire combinations later
* FIXME: hire and fire for CEO-s and other managers if needed
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
bys frame_id_numeric year: egen n_expat_ceo = total(cond(expat_ceo, 1, 0)) // could be in collapse but local not
bys frame_id_numeric year: egen n_local_ceo = total(cond(!expat & position == 1, 1, 0))
bys frame_id_numeric year: egen n_expat_other = total(cond(expat_other, 1, 0)) // could be in collapse but local not
bys frame_id_numeric year: egen n_local_other = total(cond(!expat & position == 2, 1, 0))

*number of ceo-s and other managers
bys frame_id_numeric year: egen n_ceo = total(cond(position == 1, 1, 0))
bys frame_id_numeric year: egen n_other = total(cond(position == 2, 1, 0))

* create firm-year data
* FIXME: country_code may be different within a firm-year
collapse (sum) n_founder = founder n_insider = insider n_outsider = outsider n_founder_ceo = founder_ceo n_insider_ceo = insider_ceo n_outsider_ceo = outsider_ceo n_founder_other = founder_other n_insider_other = insider_other n_outsider_other = outsider_other (firstnm) n_expat n_local n_expat_ceo n_local_ceo n_expat_other n_local_other foreign ever_expat ever_expat_ceo ever_expat_other ever_foreign n_ceo n_other (count) n_manager = expat (max) hire fire hire_expat fire_expat, by(frame_id_numeric year)

count if n_founder != (n_founder_ceo + n_founder_other)
count if n_insider != (n_insider_ceo + n_insider_other)
count if n_outsider != (n_outsider_ceo + n_outsider_other)
count if n_expat != (n_expat_ceo + n_expat_other)
count if n_local != (n_local_ceo + n_local_other)
count if n_manager != (n_ceo + n_other)

* managers in first year not classified as new hires and in last year not classified as fired
bys frame_id_numeric (year): replace hire = 0 if (_n==1)
bys frame_id_numeric (year): replace fire = 0 if (_n==_N)
bys frame_id_numeric (year): replace hire_expat = 0 if (_n==1)
bys frame_id_numeric (year): replace fire_expat = 0 if (_n==_N)
bys frame_id_numeric (year): gen ceo_spell = sum(hire | fire) + 1 // so that index start from 1

* create dummies from numbers
foreach var in expat expat_ceo expat_other local local_ceo local_other founder founder_ceo founder_other insider insider_ceo insider_other outsider outsider_ceo outsider_other {
	gen has_`var' = (n_`var' > 0)
}

* merge on manager_countries
merge 1:1 frame_id_numeric year using "`here'/temp/manager_country.dta", keep(master match) nogen
tabulate has_expat if missing(country_list)
tabulate has_expat if !missing(country_list)
rename country_list country_all_manager
rename language_list lang_all_manager

count

compress
*save_all_to_json
save "`here'/temp/firm_events.dta", replace
log close
