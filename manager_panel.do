*Betöltés
set more off
clear all
capture log close
log using output/manager_panel, text replace
local variables	person_foreign frame_id manager_id pos5

use temp/managers

*duplicates report ceg_id rovat_id alrovat_id
*van eg cég, ahol a ceg_id rovat_id alrovat_id nem határozza meg egyértelműen a személyt - a ceg_id:110041043, ezért kell merge m:1
merge m:1 ceg_id rovat_id alrovat_id using temp/positions, keepusing(pos5) keep(master match)
drop _merge


replace year_from=year_from+1 if month_from>6|(month_from==6&day_from>20)
replace year_till=year_till-1 if month_till<6|(month_till==6&day_till<21)

tab year_from


* drop all unnecessary vars before expanding
keep `variables' ceg_id rovat_id alrovat_id year_from year_till 
compress
* admissible dates
local T1 1946
local T2 2018
local T3 2021

foreach X of var year_* {
	replace `X'=. if `X'<`T1' | `X'>`T3'
	replace `X'=`T2' if `X'<=`T3' & `X'>`T2'
}
replace year_till = year_from if year_till<year_from
gen diff=year_till-year_from+1
drop if diff<=0 | missing(diff)
tab diff
table year_from , c(mean diff)
 
expand diff

bys ceg_id rovat_id alrovat_id: gen year = year_from+_n-1

*Duplikációk összeejtése
*duplicates report frame_id manager_id year
*duplicates report frame_id manager_id year pos5
collapse (firstnm) person_foreign, by(frame_id manager_id year pos5)
tab person_foreign

save temp/manager_panel, replace
log close
