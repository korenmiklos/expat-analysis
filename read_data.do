clear all
capture log close
log using output/read_data, text replace

import delimited input/manager_position/pos5.csv, varnames(1) clear
drop if pos5==9
gen rovat_id=13
keep ceg_id rovat_id alrovat_id pos5
compress
save temp/positions, replace

import delimited input/motherlode/manage.csv, varnames(1) clear

*Külföldi-magyar dummy
keep if inlist(manager_type,"FO-P","HU-P")
gen byte person_foreign = manager_type=="FO-P"

*Source darabolása
gen byte rovat_id=real(substr(source,1,2))
gen long ceg_id=real(substr(source,4,10))
* there can be more than 999 alrovats
gen int alrovat_id=real(substr(source,15,5))


*Panelify
replace valid_till="2018-12-31" if valid_till==""

* ruthless loops. otherwise, prone to error.
foreach X in from till {
	gen year_`X'=real(substr(valid_`X',1,4))
	gen month_`X'=real(substr(valid_`X',6,2))
	gen day_`X'=real(substr(valid_`X',9,2))
}

* drop unnecessary strings before merging
drop source valid_from valid_till manager_type
compress
save temp/managers, replace

log close
