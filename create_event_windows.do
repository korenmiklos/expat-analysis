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
	foreach X of var expat foreign {
		egen ever_`X' = max(`X'==1), by(frame_id)
	}

	egen first_year_expat_original = min(cond(expat==1,job_begin,.)), by(frame_id)
	egen first_year_foreign_original = min(cond(foreign==1,year,.)), by(frame_id)

	*foreign visszahúzása expatba, valaha expat-tal, de soha foreign-mal bíró cégek teljes kidobása
	replace foreign = 1 if (first_year_expat_original == (year - 1) | first_year_expat_original == year) & foreign == 0 & ever_foreign == 1
	egen first_year_foreign = min(cond(foreign == 1, year, .)), by(frame_id)

	clonevar enter_year_original = job_begin
	* NB: this was buggy, also replaced later expats
	* FIXME: do foreign/expat synchronization in firm_ceo_panel instead
	replace job_begin = first_year_foreign_original if (enter_year_original == first_year_foreign - 2) & expat == 1 & ever_foreign == 1
	egen first_year_expat = min(cond(expat == 1, job_begin, .)), by(frame_id)

	drop *_year_*_original

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

