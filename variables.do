clear all
capture log close
log using output/variables, text replace

use temp/firm_ceo_panel

scalar T1 = 1989
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

drop if founder==1
scalar dropped_founders = r(N_drop)

codebook frame_id

drop age_cat
clonevar age_cat = age
recode age_cat 20/24=20 25/29=25 30/39=30 40/49=40 50/max=50
tab age_cat


* time invariant vars
foreach X of var expat foreign {
	egen first_year_`X' = min(cond(`X'==1,year,.)), by(frame_id)
	egen ever_`X' = max(`X'==1), by(frame_id)
}

gen tenure_foreign = year-first_year_foreign


*foreign visszahúzása expatba, valaha expat-tal, de soha foreign-mal bíró cégek teljes kidobása
replace foreign=1 if first_year_expat<=year&foreign==0&ever_foreign==1
drop first_year_foreign
egen first_year_foreign = min(cond(foreign==1,year,.)), by(frame_id)

drop if ever_expat==1 & ever_foreign==0
scalar dropped_do3_expat_firmyears = r(N_drop)

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
foreach X in domestic expat DD DE ED EE {
	gen byte new_`X' = (tenure <=`T') & (tenure>=0) & (`X'==1)
	
	* new managers at foreign firms
	gen byte fnew_`X' = new_`X' & foreign==1
	* only include managers joining in years [-1,...) since foreign
	replace fnew_`X' = 0 if tenure > tenure_foreign+1

	foreach Y of var tenure before during after {
		gen `Y'_`X' = (`X'==1)*`Y'
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

*Teljes minta elmentése a kontrollokkal
compress
save temp/analysis_sample, replace
save_all_to_json
log close

