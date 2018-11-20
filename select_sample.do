clear all
use input/balance-small/balance-sheet-1992-2016-small

* limit sample before large merge
*Függő változók készítése
gen lnL=ln(emp)
gen lnK=ln(final_netgep)
gen lnM=ln(ranyag)
gen lnQ=ln(sales)
gen lnQL=lnQ-lnL
gen lnKL=lnK-lnL
gen byte exporter = export>0&export!=.
replace exporter=0 if export==.
*Átlagos létszám változó
bys frame_id: egen avg_emp = mean(emp)
*Mintavétel létszám és a K-n kvül a többi függő változó nem missing alapján
local sample (avg_emp>=20)&!missing(lnL,lnQ,exporter)
keep if `sample'
scalar dropped_size_or_missing = r(N_drop)

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
drop if foreign_change_total>1|foreign_change_rev_total>1
scalar dropped_too_many_foreign_change = r(N_drop)
drop foreign_change foreign_change_rev foreign_change_total foreign_change_rev_total

*Greenfield - foreign húzás után, de a sampling előtt
bys frame_id (year): gen relative_year=_n
gen foreign_infirst=1 if relative_year==1&foreign==1
bys frame_id: egen byte greenfield=max(foreign_infirst)

recode greenfield (.=0)




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
gen age_cat=.
replace age_cat=1 if age==0
replace age_cat=2 if age==1
replace age_cat=3 if age==2
replace age_cat=4 if age>=3&age<=5
replace age_cat=5 if age>=6&age<=8
replace age_cat=6 if age>8




*Pénzügyi szektorban működő vállalatok kiszűrése
bys frame_id: egen industry_mode=mode(teaor08_2d)
drop if industry_mode==64|industry_mode==65|industry_mode==66
scalar dropped_finance = r(N_drop)

save_all_to_json
save temp/balance-small, replace
