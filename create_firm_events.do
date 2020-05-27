keep if (year >= job_begin) & (year <= job_end)
generate byte change = (job_begin==year)
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

compress
save "temp/firm_events.dta", replace

merge 1:1 frame_id_numeric year using "temp/balance-small.dta", keep(match)

save "temp/analysis_sample_firm.dta", replace
