clear all

use "temp/balance-small.dta"
keep frame_id year foreign
tempfile sample
save `sample', replace

use "temp/firm_ceo_panel.dta", clear
capture drop _*

scalar T1 = 1988
scalar T2 = 2018
expand T2-T1+1
bys frame_id manager_id job_spell: gen year = _n-1+T1

* only keep years when the firm is alive, without merging actual balance data
merge m:1 frame_id year using `sample', nogen keep(match)

codebook frame_id

*expat before 1990
replace expat=0 if job_begin<1990

***********************
* time invariant vars *
***********************
	egen first_year_expat = min(cond(expat==1,job_begin,.)), by(frame_id)
	egen first_year_foreign_original = min(cond(foreign==1,year,.)), by(frame_id)
	
	* which of the two happened first?
	generate manager_after_owner = first_year_expat - first_year_foreign_original
	* event time relative to that
	generate event_time = year - first_year_expat
	
	generate first_year_foreign = first_year_foreign_original
	
	* if foreign manager arrives up to 2 years before 1 year later than foreign owner, use foreign manager as arrival date. this is easier to implement
	replace first_year_foreign = first_year_expat if inlist(manager_after_owner, -2, -1, 1)
	
	replace foreign = 1 if (manager_after_owner == -2) & inlist(event_time, 0, 1)
	replace foreign = 1 if (manager_after_owner == -1) & inlist(event_time, 0)
	replace foreign = 0 if (manager_after_owner == +1) & inlist(event_time, -1)

	drop *_year_*_original event_time manager_after_owner

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


* tenure at the firm in current job spell
generate tenure = year - job_begin

* save firm-year dummy of whether there is an expat at the firm
preserve
	collapse (max) max_expat = expat, by(frame_id year)
	label variable max_expat "Firm has expat CEO (dummy)"
	save "temp/firm_year_expat.dta", replace
restore

* limit sample by event window
keep if tenure >= -5 & tenure <= 10

compress
save "temp/event_windows.dta", replace
save_all_to_json

