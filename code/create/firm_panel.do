*Betöltés
set more off
clear all
capture log close

* find root folder
here
local here = r(here)

log using "`here'/output/firm_panel", text replace

* keep only sample from balance-small
use "`here'/temp/balance-small-clean.dta"
by frame_id_numeric: egen firm_birth = min(year)
by frame_id_numeric: egen firm_death = max(year)
keep frame_id_numeric year firm_birth firm_death foreign
tempfile sample
save `sample', replace

use "`here'/temp/ceo-panel.dta", clear 

* only keep sample firms
merge m:1 frame_id_numeric year using `sample', keep(match) nogen
count if first_year_of_firm == firm_birth

*for descriptives (number of ceo-s and nceo-s in original data, number of ceo and nceo job-spells in original data)
count
egen company_manager_id = group(frame_id_numeric manager_id)
codebook manager_id
codebook company_manager_id

* balance panel
xtset company_manager_id year
by company_manager_id: generate gap = year - year[_n-1] - 1
replace gap = 0 if missing(gap)
tabulate gap

* fill in holes of 1 year, but not longer
expand 1 + (gap == 1), generate(filled_in)
replace year = year - 1 if filled_in

* create contiguous spells
xtset company_manager_id year
gen change = ceo != L.ceo
bysort company_manager_id (year): gen job_spell = sum(change)

* create job begin and end for each manager spell
bys frame_id_numeric manager_id job_spell: egen job_begin = min(year)
bys frame_id_numeric manager_id job_spell: egen job_end = max(year)
keep frame_id_numeric manager_id job_spell year job_begin job_end firm_birth foreign foreignness

* if first managers arrive in year 1, extrapolate to year 0 - DROP SPELL
bys frame_id_numeric: egen first_cohort = min(job_begin)
replace job_begin = job_begin - 1 if (first_cohort == firm_birth + 1) & (job_begin == first_cohort)

* NOTE: no collapse and expand --> there might be holes
sort frame_id_numeric manager_id year
count if frame_id_numeric == frame_id_numeric[_n-1] & manager_id == manager_id[_n-1] & year != (year[_n-1] + 1)

* hired or fired ceo since last observed year of firm
tempvar previous_year
generate previous_year = .
forval t = 1985/2018 {
	quietly by frame_id_numeric: egen `previous_year' = max(cond(year < `t', year, .))
	quietly replace previous_year = `previous_year' if year == `t'
	drop `previous_year'
}

tempvar next_year
generate next_year = .
forval t = 1985/2018 {
	quietly by frame_id_numeric: egen `next_year' = min(cond(year > `t', year, .))
	quietly replace next_year = `next_year' if year == `t'
	drop `next_year'
}

generate byte hire = (job_begin <= year) & (job_begin > previous_year) & !missing(previous_year)
* first cohort of managers are classified as newly hired
replace hire = 1 if job_begin == first_cohort
generate byte fire = (job_end >= year) & (job_end < next_year) & !missing(next_year)
tabulate hire fire 

generate byte expat = foreignness > 0

* manager change may anticipate foreign change by max this many years
local anticipation 2
local lag 1
tempvar time_foreign first_year_foreign ever_expat
***********************
* time invariant vars and drop entire series of firms from sample *
***********************
by frame_id_numeric: egen `first_year_foreign' = min(cond(foreign == 1, year,.))
generate `time_foreign' = year - `first_year_foreign'
by frame_id_numeric: egen `ever_expat' = max((expat == 1) & inrange(`time_foreign', -`anticipation', `lag'))
by frame_id_numeric: egen first_year_hire = min(cond((hire == 1) & (`time_foreign' >= -`anticipation'), job_begin,.))
by frame_id_numeric: egen first_year_expat = min(cond(expat == 1, job_begin,.))
by frame_id_numeric: egen first_year_foreign = min(cond(foreign == 1, year,.))

* which of the two happened first?
generate expat_after_owner = first_year_expat - first_year_foreign
generate manager_after_owner = first_year_hire - first_year_foreign
tabulate manager_after_owner

* if foreign manager arrives up to X years before or Y years later than foreign owner, use foreign manager as arrival date. 
forvalues t = -`anticipation'/-1 {
	local k = abs(`t') - 1
	replace foreign = 1 if (expat_after_owner == `t') 	& inrange(year - first_year_expat, 0, `k') 	& `ever_expat' 
	replace foreign = 1 if (manager_after_owner == `t') & inrange(year - first_year_hire, 0, `k')	& !`ever_expat'
}
forvalues t = 1/`lag' {
	local minust = -`t'
	replace foreign = 0 if (expat_after_owner == `t') 	& inrange(year - first_year_expat, `minust', -1)	& `ever_expat'
	replace foreign = 0 if (manager_after_owner == `t') & inrange(year - first_year_hire, `minust', -1)		& !`ever_expat'
}
* drop firms where expat arrives earlier than X years before owner
drop if first_year_expat - first_year_foreign < -`anticipation'

* ever expat and foreign created after foreign changes (drops were firm level before so should not mess with ever variables)
foreach X of var expat foreign {
	by frame_id_numeric: egen ever_`X' = max(`X'==1)
}

* drop if there was an expat but was never foreign - these are likely error
drop if ever_expat == 1 & ever_foreign == 0

* drop too many CEO-s
egen fp_tag = tag(frame_id_numeric manager_id) 
by frame_id_numeric: egen n_ceo_ever = sum(fp_tag)
drop if n_ceo_ever > 15
drop fp_tag n_ceo_ever
	
* create firm-year data
collapse (firstnm) foreign ever_expat ever_foreign (count) n_ceo = expat (max) hire_ceo = hire fire_ceo = fire foreignness, by(frame_id_numeric year)
label values foreignness foreignness
* define expat as any foreign link. we can limit the sample later
generate has_expat_ceo = foreignness > 0 & !missing(foreignness)

* if there is a change in the ceo team, hiring, increement the spell counter
bys frame_id_numeric (year): gen ceo_spell = sum(hire_ceo) + 1 // so that index start from 1

count
compress
save "`here'/temp/firm_events.dta", replace
log close
