keep if (year >= job_begin) & (year <= job_end)

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
tabulate change

generate N = 1
collapse (sum) N (firstnm) foreign (max) change, by(frame_id year manager_category expat)
egen hires_new_ceo = max(change), by(frame_id year)
drop change

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
bysort frame_id (year): generate owner_spell = sum(foreign != foreign[_n-1])
bysort frame_id (year): generate manager_spell = sum(hires_new_ceo)
* so that index start from 1
replace manager_spell = 1 + manager_spell

egen start_as_domestic = max((owner_spell==1) & (foreign==0)), by(frame_id)
* only keep D, D-F owner spells
keep if start_as_domestic & owner_spell <= 2

compress
save "temp/firm_events.dta", replace

