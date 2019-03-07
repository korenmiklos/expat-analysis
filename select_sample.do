clear all
use input/balance-small/balance-sheet-1992-2016-small

collapse (firstnm) year, by(frame_id)
drop year
tempfile add
save `add'

use input/balance-small/balance_sheet80_14, clear
keep if year<1992
drop if frame_id==""
merge m:1 frame_id using `add'
keep if _merge==3
count
tempfile eighties
save `eighties'

use input/balance-small/balance-sheet-1992-2016-small, clear
count
append using `eighties'
count

* limit sample before large merge
*Függő változók készítése
gen lnL=ln(emp)
gen lnM=ln(ranyag)
gen lnQ=ln(sales)
gen lnQL=lnQ-lnL
gen byte exporter = export>0&export!=.
replace exporter=0 if export==.
*Átlagos létszám változó
bys frame_id: egen avg_emp = mean(emp)
*Mintavétel létszám és a K-n kvül a többi függő változó nem missing alapján
local sample (avg_emp>=20)&!missing(lnL,lnQ,exporter)
count
tempvar before
gen `before' = r(N)
keep if `sample'
count
tempvar after
gen `after' = r(N)
scalar dropped_size_or_missing = `before'-`after'
di dropped_size_or_missing
*scalar dropped_size_or_missing = r(N_drop)


ren fo3 foreign
*foreign átalakítása 
recode foreign (.=0)

egen id = group(frame_id)



*foreign-at többször váltók kidobása
xtset id year
gen foreign_change=1 if l1.foreign==0&foreign==1
gen foreign_change_rev=1 if l1.foreign==1&foreign==0
bys frame_id: egen foreign_change_total=total(foreign_change)
bys frame_id: egen foreign_change_rev_total=total(foreign_change_rev)
count
tempvar before
gen `before' = r(N)
drop if foreign_change_total>1|foreign_change_rev_total>1
count
tempvar after
gen `after' = r(N)
scalar dropped_too_many_foreign_change = `before'-`after'
di dropped_too_many_foreign_change
*scalar dropped_too_many_foreign_change = r(N_drop)

*divesztíció
recode foreign_change_rev (.=0)
bys frame_id (year): gen div=sum(foreign_change_rev)
replace div=1 if div>0
drop foreign_change foreign_change_rev foreign_change_total foreign_change_rev_total

*Greenfield - foreign húzás után, de a sampling előtt
bys frame_id (year): gen relative_year=_n
gen foreign_infirst=1 if relative_year==1&foreign==1
bys frame_id: egen byte greenfield=max(foreign_infirst)

recode greenfield (.=0)

* extrapolate capital stock
xtset id year
local condition  final_netgep==0 & !missing(L.final_netgep) & L.final_netgep>0
count if `condition'
scalar replaced_capital = r(N)
replace final_netgep = L.final_netgep if `condition'
gen lnK=ln(final_netgep)
gen lnKL=lnK-lnL
drop if missing(lnK)&year>1991



*Industry_year dummy
egen industry_year = group(teaor08_2d year)


*Industry dummy
gen byte ind = inlist(teaor08_1d,"B","C","D","E")
egen ind_year=group(ind year)


*Manufacaturing dummy
gen manufacturing=0
replace manufacturing=1 if teaor08_1d=="C"




*Életkor változó
gen age=year-foundyear

clonevar age_cat = age
recode age_cat 20/24=20 25/29=25 30/39=30 40/49=40 50/max=50
tab age_cat



*Pénzügyi szektorban működő vállalatok kiszűrése
* break the tie when mode is not unique
bys frame_id: egen industry_mode=mode(teaor08_2d), minmode
count
tempvar before
gen `before' = r(N)
drop if industry_mode==64|industry_mode==65|industry_mode==66
count
tempvar after
gen `after' = r(N)
scalar dropped_finance = `before'-`after'
di dropped_finance
*scalar dropped_finance = r(N_drop)

save_all_to_json
drop __*
save temp/balance-small, replace
