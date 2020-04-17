clear all

use "temp/firm_ceo_panel.dta"
capture drop _*

* NB: this is actual panel of CEO, so missing after period

merge m:1 frame_id year using "temp/balance-small.dta", nogen keep(match)
merge m:1 frame_id year using "temp/N_ceos.dta", nogen keep(match)
* drop very large firms
egen fp_tag = tag(frame_id manager_id ) 
egen total_CEOs = sum(fp_tag ), by(frame_id )
tab total_CEOs 

drop if total_CEOs>15
scalar dropped_too_many_CEOs = r(N_drop)

egen ceo_span = max(1+tenure), by(frame_id manager_id job_spell)
tab ceo_span
egen industry_ceo_span = median(ceo_span), by(industry_mode)
tab industry_ceo_span if fp_tag
gen byte slow = industry_ceo_span >= 10
tab industry_mode if slow

* create sample splits based on data in founder years
local continuous lnL lnKL lnQL
local dummy exporter slow
foreach X of var `continuous' {
	egen mean_`X' = mean(cond(spell==1,`X',.)), by(frame_id)
	egen median_`X' = median(mean_`X'), by(industry_mode)
	gen byte H_`X' = mean_`X' > median_`X'
	tab H_`X'
}
foreach X of var `dummy' {
	egen mean_`X' = mean(cond(spell==1,`X',.)), by(frame_id)
	gen byte H_`X' = mean_`X' > 0.5
	tab H_`X'
}
gen byte H_early = job_begin<=2000
gen byte H_young_firm = age<=10

codebook frame_id

*expat before 1990
replace expat=0 if job_begin<1990

* time invariant vars
foreach X of var expat foreign {
	egen ever_`X' = max(`X'==1), by(frame_id)
}

egen first_year_expat_original = min(cond(expat==1,job_begin,.)), by(frame_id)
egen first_year_foreign_original = min(cond(foreign==1,year,.)), by(frame_id)

*foreign visszahúzása expatba, valaha expat-tal, de soha foreign-mal bíró cégek teljes kidobása
replace foreign = 1 if (first_year_expat_original==(year-1)|first_year_expat_original==year)&foreign==0&ever_foreign==1
egen first_year_foreign = min(cond(foreign==1,year,.)), by(frame_id)

/*
NB: do not change expat coding because it is hard to do at this stage. just drop remaining firms that are never foreign yet have expats.

clonevar enter_year_original = job_begin
replace job_begin = first_year_foreign_original if ((enter_year_original-2)<first_year_foreign_original)&expat==1&ever_foreign==1
egen first_year_expat = min(cond(expat==1,job_begin,.)), by(frame_id)
*/

gen tenure_foreign = year-first_year_foreign

drop if ever_expat==1 & ever_foreign==0
scalar dropped_do3_expat_firmyears = r(N_drop)

* spell relation dummies
gen byte before = tenure < 0
gen byte during = tenure>=0
* NB: missing after years now
gen byte after = 0

* spell-to-spell transition
gen byte DD = (lag_expat==0)&(expat==0)
gen byte DE = (lag_expat==0)&(expat==1)
gen byte ED = (lag_expat==1)&(expat==0)
gen byte EE = (lag_expat==1)&(expat==1)

* newly arriving CEOs
* FIXME: review these dummies
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
gen byte foreign_hire = 1 if first_year_foreign <= job_begin
recode foreign_hire (. = 0)
gen during_foreign = during*foreign_hire

* zero out all treatment dummies for founders. they are alwyas just control
foreach X of var before during after DD DE ED EE {
	replace `X' = 0 if founder==1
}

*Cégév szerinti szűrés
drop if missing(lnL,lnQ,exporter)

*Tfp
tab year, gen(year_d)
egen firmyear_tag=tag(frame_id year)
bysort frame_id: egen teaor_mode = mode(teaor08_2d), maxmode
recode teaor_mode (6 75 = .)
gen lnVA = ln(sales-ranyag)

/*
FIXME: this is wrong for sure. only saves first stage. 
levelsof teaor_mode, local(levels)
foreach l of local levels {
  disp `l'
  qui prodest lnVA if teaor_mode == `l' & firmyear_tag, ///
            free(lnL) state(lnK) proxy(lnM)  ///
            met(lp) va control (year_d*) id(firm_person) t(year) fsres(tfp_lp_`l')
}

* Q: what is x?
gen  x =  .
levelsof teaor_mode, local(levels)
foreach l of local levels {

		replace x = tfp_lp_`l' if x == .
}

bysort frame_id year: egen  tfp_lp = max(x)

drop tfp_lp_* x year_d*
*/
*Teljes minta elmentése a kontrollokkal
compress
save "temp/analysis_sample.dta", replace
save_all_to_json

