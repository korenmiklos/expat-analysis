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

* count expats in do - asterisk used
*use "`here'/input/ceo-panel/ceo-panel.dta", clear // QUESTION: what is owner
*rename person_id manager_id
*merge m:1 frame_id_numeric year using `sample', keep(match) nogen
*bys frame_id_numeric: egen ever_expat = max(expat == 1)
*bys frame_id_numeri: egen ever_foreign = max(foreign == 1)
*egen firm_tag = tag(frame_id_numeric)
*count if ever_expat == 1 & ever_foreign == 0 & firm_tag == 1

foreach type in ceo nceo {
	use "`here'/input/`type'-panel/`type'-panel.dta", clear // QUESTION: what is owner
	rename person_id manager_id
	
	*for descriptives (number of ceo-s and nceo-s in original data, number of ceo and nceo job-spells in original data)
	count
	egen company_manager_id = group(frame_id_numeric manager_id)
	codebook manager_id
	codebook company_manager_id
	drop company_manager_id

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
	gen change = ceo != L.ceo // intuition: should be ok in both files (possible FIXME)
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
			by frame_id_numeric: egen ever_`X'_`type' = max(`X'==1)
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

	gen hire_expat_`type' = hire * expat
	gen fire_expat_`type' = fire * expat

	* number of expats and locals
	bys frame_id_numeric year: egen n_expat_`type' = total(cond(expat, 1, 0)) // could be in collapse but local not
	bys frame_id_numeric year: egen n_local_`type' = total(cond(!expat, 1, 0))
	
	*for descriptives (number of ceo-s and nceo-s in final data, number of ceo and nceo job-spells in final data) - part I
	*tempfile raw_`type'
	*save `raw_`type''
	save "`here'/temp/raw_`type'.dta", replace
	
	* create firm-year data
	* FIXME: country_code may be different within a firm-year
	collapse (sum) n_founder_`type' = founder n_insider_`type' = insider n_outsider_`type' = outsider (firstnm) n_expat_`type' n_local_`type' foreign_`type' = foreign ever_expat_`type' ever_foreign_`type' (count) n_`type' = expat (max) hire_`type' = hire fire_`type' = fire hire_expat_`type' fire_expat_`type', by(frame_id_numeric year)

	* managers in first year not classified as new hires and in last year not classified as fired
	bys frame_id_numeric (year): replace hire_`type' = 0 if (_n==1)
	bys frame_id_numeric (year): replace fire_`type' = 0 if (_n==_N)
	bys frame_id_numeric (year): replace hire_expat_`type' = 0 if (_n==1)
	bys frame_id_numeric (year): replace fire_expat_`type' = 0 if (_n==_N)
	bys frame_id_numeric (year): gen ceo_spell_`type' = sum(hire_`type' | fire_`type') + 1 // so that index start from 1

	* create dummies from numbers
	foreach var in expat local founder insider outsider {
		gen has_`var'_`type' = (n_`var'_`type' > 0) & n_`var'_`type' != .
	}
	
	tempfile manager_`type'
	save `manager_`type''
}

*for descriptives (number of ceo-s and nceo-s in final data, number of ceo and nceo job-spells in final data) - part II
*foreach type in ceo nceo {
*	use "`here'/temp/balance-small-clean.dta", clear
*	merge 1:m frame_id_numeric year using `raw_`type'', nogen keep(match) keepusing(manager_id)
*	count
*	egen company_manager_id = group(frame_id_numeric manager_id)
*	codebook manager_id
*	codebook company_manager_id 
*}

use `manager_ceo'

* merge on manager_countries
merge 1:1 frame_id_numeric year using "`here'/temp/manager_country.dta", keep(master match) nogen
tabulate has_expat_ceo if missing(country_list)
tabulate has_expat_ceo if !missing(country_list)
rename country_list country_all_ceo
rename language_list lang_all_ceo

merge 1:1 frame_id_numeric year using `manager_nceo', keep (1 3) nogen // 1, only 1 and 3 to not have missing cases in tab has_expat_ceo, missing in analysis-sample 2, merge here to makes sure to have only ceo-s when countries are merged

count

compress
*save_all_to_json
save "`here'/temp/firm_events.dta", replace
log close
