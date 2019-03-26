clear all
capture log close
log using output/variables, text replace

use temp/firm_ceo_panel
drop _*

scalar T1 = 1980
scalar T2 = 2016
expand T2-T1+1
bys frame_id manager_id: gen year = _n-1+T1

tempfile expand
save `expand', replace

merge m:1 frame_id year using temp/balance-small, nogen keep(match)
merge m:1 frame_id year using temp/N_ceos, nogen keep(match)
* drop very large firms
egen fp_tag = tag(frame_id manager_id ) 
egen total_CEOs = sum(fp_tag ), by(frame_id )
tab total_CEOs 

drop if total_CEOs>15
scalar dropped_too_many_CEOs = r(N_drop)

gen ceo_span = first_exit_year-enter_year+1
tab ceo_span
egen industry_ceo_span = median(ceo_span), by(industry_mode)
tab industry_ceo_span
gen byte slow = industry_ceo_span>4

tab industry_mode if slow

* create sample splits based on data in founder years
local continuous lnL lnKL lnQL
local dummy exporter slow
foreach X of var `continuous' {
	egen mean_`X' = mean(cond(founder==1 & year<=first_exit_year,`X',.)), by(frame_id)
	egen median_`X' = median(mean_`X'), by(industry_mode)
	gen byte H_`X' = mean_`X' > median_`X'
	tab H_`X'
}
foreach X of var `dummy' {
	egen mean_`X' = mean(cond(founder==1 & year<=first_exit_year,`X',.)), by(frame_id)
	gen byte H_`X' = mean_`X' > 0.5
	tab H_`X'
}
gen byte H_early = enter_year<=2000
gen byte H_young_firm = age<=10

codebook frame_id

*expat before 1990
replace expat=0 if enter_year<1990

* time invariant vars
foreach X of var expat foreign {
	egen ever_`X' = max(`X'==1), by(frame_id)
}

egen first_year_expat_original = min(cond(expat==1,enter_year,.)), by(frame_id)
egen first_year_foreign_original = min(cond(foreign==1,year,.)), by(frame_id)

*foreign visszahúzása expatba, valaha expat-tal, de soha foreign-mal bíró cégek teljes kidobása
replace foreign=1 if (first_year_expat_original==(year-1)|first_year_expat_original==year)&foreign==0&ever_foreign==1
egen first_year_foreign = min(cond(foreign==1,year,.)), by(frame_id)

clonevar enter_year_original=enter_year
replace enter_year=first_year_foreign_original if ((enter_year_original-2)<first_year_foreign_original)&expat==1&ever_foreign==1
egen first_year_expat = min(cond(expat==1,enter_year,.)), by(frame_id)

gen tenure_foreign = year-first_year_foreign

drop if ever_expat==1 & ever_foreign==0
scalar dropped_do3_expat_firmyears = r(N_drop)

egen enter_year_min=min(enter_year), by(frame_id)
replace foundyear=enter_year_min if foundyear>enter_year_min
drop enter_year_min

* spell relation dummies
gen byte before = year<enter_year
gen byte during = year>=enter_year & year<=first_exit_year
gen byte after = year>first_exit_year
gen tenure = year-enter_year

* spell-to-spell transition
gen byte DD = (lag_expat==0)&(expat==0)
gen byte DE = (lag_expat==0)&(expat==1)
gen byte ED = (lag_expat==1)&(expat==0)
gen byte EE = (lag_expat==1)&(expat==1)

* newly arriving CEOs
local T 4
gen byte domestic = (expat==0)
foreach X of var domestic expat DD DE ED EE {
	gen byte new_`X' = (tenure <=`T') & (tenure>=0) & (`X'==1)
	
	* new managers at foreign firms
	gen byte fnew_`X' = new_`X' & foreign==1
	* only include managers joining in years [-1,...) since foreign
	replace fnew_`X' = 0 if tenure > tenure_foreign+1

	foreach Y of var tenure before during after {
		gen `Y'_`X' = (`X'==1)*`Y'
		foreach Z of var H_* {
			gen `Y'_`X'_`Z' = (`X'==1)*`Y'*(`Z'==1)
		}
	}
}
gen fold_expat = expat==1 & tenure>`T'
gen byte new = new_domestic | new_expat
gen byte fnew = fnew_domestic | fnew_expat

*foreign_switch interakció létrehozása
gen byte foreign_new = foreign & new

** do stats here
tempvar tag
foreach X of var foreign new expat new_expat fnew fnew_expat {
	count if `X'==1
	scalar N_it_`X' = r(N)
	
	* by firms
	egen `tag' = tag(frame_id `X')
	count if `X'==1 & `tag'==1
	scalar N_i_`X' = r(N)
	drop `tag'
}

*Firm_tag
egen firm_tag=tag(frame_id)
egen firm_person = group(frame_id manager_id)

*Foreign hire
gen byte foreign_hire = 1 if first_year_foreign <= enter_year
recode foreign_hire (. = 0)
gen during_foreign = during*foreign_hire

* zero out all treatment dummies for founders. they are alwyas just control
foreach X of var before during after DD DE ED EE {
	replace `X' = 0 if founder==1
}

*Cégév szerinti szűrés
drop if missing(lnL,lnQ,exporter)

*Teljes minta elmentése a kontrollokkal
compress
save temp/analysis_sample, replace
save_all_to_json
log close
