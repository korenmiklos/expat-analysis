clear all

use "temp/balance-small.dta"
keep frame_id year foreign
tempfile sample
save `sample', replace

use "temp/firm_ceo_panel.dta", clear
capture drop _*

expand (job_end - job_begin + 1)
bys frame_id manager_id spell: gen year = job_begin + _n - 1

* only keep years when the firm is alive, without merging actual balance data
merge m:1 frame_id year using `sample', nogen keep(match)

codebook frame_id

*expat before 1990
replace expat=0 if job_begin<1990

***********************
* time invariant vars *
***********************
	egen first_year_expat = min(cond(expat==1,job_begin,.)), by(frame_id)
	egen first_year_foreign = min(cond(foreign==1,year,.)), by(frame_id)
	
	* which of the two happened first?
	generate manager_after_owner = first_year_expat - first_year_foreign
	* event time relative to that
	generate event_time = year - first_year_expat
	
	* if foreign manager arrives up to 2 years before 1 year later than foreign owner, use foreign manager as arrival date. this is easier to implement
	replace foreign = 1 if (manager_after_owner == -2) & inlist(event_time, 0, 1)
	replace foreign = 1 if (manager_after_owner == -1) & inlist(event_time, 0)
	replace foreign = 0 if (manager_after_owner == +1) & inlist(event_time, -1)

	* drop firms where expat arrives earlier than 2 years before owner
	drop if manager_after_owner < -2
	
	foreach X of var expat foreign {
		egen ever_`X' = max(`X'==1), by(frame_id)
	}

*******************************************
* drop entire series of firms from sample *
*******************************************
	drop if ever_expat==1 & ever_foreign==0
	scalar dropped_do3_expat_firmyears = r(N_drop)

	* drop very large firms
	egen fp_tag = tag(frame_id manager_id ) 
	egen total_CEOs = sum(fp_tag ), by(frame_id )
	tab total_CEOs 

	drop if total_CEOs>15
	scalar dropped_too_many_CEOs = r(N_drop)
	drop fp_tag total_CEOs
	
* hired ceo since last observed year of firm
tempvar last_year
generate last_year = .
forval t = 1985/2018 {
	egen `last_year' = max(cond(year < `t', year, .)), by(frame_id)
	replace last_year = `last_year' if year == `t'
	drop `last_year'
}
egen first_year = min(year), by(frame_id)
bysort frame_id (year): generate byte change = cond(first_year == year, 1, (job_begin <= year) & (job_begin > last_year))

tempvar next_year
generate next_year = .
forval t = 1985/2018 {
	egen `next_year' = min(cond(year > `t', year, .)), by(frame_id)
	replace next_year = `next_year' if year == `t'
	drop `next_year'
}

*generate byte fired = (job_end == year)
gen byte fired = ((job_end >= year) & (job_end < next_year))
*bys frame_id (year): egen last_year_firm = max(year)
*bys frame_id (year): generate byte fired = cond(job_end == year, 1, (last_year_firm == year) & (job_end > last_year_firm))
*replace fired = 1 if ((last_year_firm == year) & (job_end > last_year_firm))
tabulate change
tabulate fired

generate N = 1
collapse (sum) N (firstnm) foreign (max) change fired, by(frame_id year manager_category expat)
egen hires_new_ceo = max(change), by(frame_id year)
egen fires_ceo = max(fired), by(frame_id year)
drop change fired

reshape wide N, i(frame_id year expat) j(manager_category)
reshape wide N1 N2 N3, i(frame_id year) j(expat)
mvencode N??, mv(0)

egen number_ceos = rsum(N??)

generate has_expat = (N11>0)|(N21>0)|(N31>0)
generate has_local = (N10>0)|(N20>0)|(N30>0)
generate has_founder = (N10>0)|(N11>0)
generate has_insider = (N20>0)|(N21>0)
generate has_outsider = (N30>0)|(N31>0)
drop N??

* managers in first year not classified as new hires
bysort frame_id (year): replace hires_new_ceo = 0 if (_n==1)
bysort frame_id (year): replace fires_ceo = 0 if (_n==_N)
bysort frame_id (year): generate owner_spell = sum(foreign != foreign[_n-1])
bysort frame_id (year): generate manager_spell = sum(hires_new_ceo | fires_ceo)
* so that index start from 1
replace manager_spell = 1 + manager_spell

egen start_as_domestic = max((owner_spell==1) & (foreign==0)), by(frame_id)
* only keep D, D-F owner spells
keep if start_as_domestic & owner_spell <= 2

compress
save "temp/firm_events.dta", replace

