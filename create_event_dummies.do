gen tenure_foreign = year - first_year_foreign

gen byte before = tenure < 0
gen byte during = tenure >= 0
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
	replace `X' = 0 if manager_category == 1
}
