clear all
capture log close
log using output/variables, text replace

*Balance sheet-tel kapcsolás
use input/balance-small/balance-sheet-1992-2016-small, clear
drop if frame_id==""

merge 1:1 frame_id year using temp/firm_ceo_panel, keep(master match)
drop _merge


egen id=group(frame_id)
xtset id year	

*Expat CEO létezik változó készítése
gen byte expat = N_expat>0&!missing(N_expat)
ren fo3 foreign

* time invariant vars
foreach X of var expat foreign {
	egen first_year_`X' = min(cond(`X'==1,year,.)), by(frame_id)
	egen ever_`X' = max(`X'==1), by(frame_id)
}

*foreign átalakítása 
recode foreign (.=0)

*foreign-at többször váltók kidobása
xtset id year
gen foreign_change=1 if l1.foreign==0&foreign==1
gen foreign_change_rev=1 if l1.foreign==1&foreign==0
bys frame_id: egen foreign_change_total=total(foreign_change)
bys frame_id: egen foreign_change_rev_total=total(foreign_change_rev)
drop if foreign_change_total>1|foreign_change_rev_total>1
scalar dropped_too_many_foreign_change = r(N_drop)
drop foreign_change foreign_change_rev foreign_change_total foreign_change_rev_total


*foreign visszahúzása expatba, valaha expat-tal, de soha foreign-mal bíró cégek teljes kidobása
replace foreign=1 if first_year_expat<=year&foreign==0&ever_foreign==1
drop first_year_foreign
egen first_year_foreign = min(cond(foreign==1,year,.)), by(frame_id)

drop if ever_expat==1 & ever_foreign==0
scalar dropped_do3_expat_firmyears = r(N_drop)


* newly arriving CEOs
local T 4
gen age_since_foreign = year - first_year_foreign
foreach X in domestic expat {
	gen byte new_`X' = tenure_`X' <=`T'
	* exclude founders joining the firm in years [0,1]
	replace new_`X' = 0 if tenure_`X' >= firm_age-1
	
	* new managers at foreign firms
	gen byte fnew_`X' = new_`X' & foreign==1
	* only include managers joining in years [-1,...) since foreign
	replace fnew_`X' = 0 if tenure_`X' > age_since_foreign+1
}
gen fold_expat = expat==1 & fnew_expat==0
gen byte new = new_domestic | new_expat
gen byte fnew = fnew_domestic | fnew_expat

*foreign_switch interakció létrehozása
gen byte foreign_new = foreign & new

*Greenfield - foreign húzás után, de a sampling előtt
bys frame_id (year): gen relative_year=_n
gen foreign_infirst=1 if relative_year==1&foreign==1
bys frame_id: egen byte greenfield=max(foreign_infirst)

recode greenfield (.=0)


*Függő változók készítése
gen lnL=ln(emp)
gen lnK=ln(final_netgep)
gen lnM=ln(ranyag)
gen lnQ=ln(sales)
gen lnQL=lnQ-lnL
gen lnKL=lnK-lnL
gen byte exporter = export>0&export!=.
replace exporter=0 if export==.


*Industry_year dummy
egen industry_year = group(teaor08_2d year)


*Industry dummy
gen byte ind = inlist(teaor08_1d,"B","C","D","E")
egen ind_year=group(ind year)


*Manufacaturing dummy
gen manufacturing=0
replace manufacturing=1 if teaor08_1d=="C"


*Átlagos létszám változó
bys frame_id: egen avg_emp = mean(emp)


*Életkor változó
gen age=year-foundyear
gen age_cat=.
replace age_cat=1 if age==0
replace age_cat=2 if age==1
replace age_cat=3 if age==2
replace age_cat=4 if age>=3&age<=5
replace age_cat=5 if age>=6&age<=8
replace age_cat=6 if age>8


*Mintavétel létszám és a K-n kvül a többi függő változó nem missing alapján
local sample (avg_emp>=20)&!missing(lnL,lnQ,exporter)
keep if `sample'
scalar dropped_size_or_missing = r(N_drop)


*Pénzügyi szektorban működő vállalatok kiszűrése
bys frame_id: egen industry_mode=mode(teaor08_2d)
drop if industry_mode==64|industry_mode==65|industry_mode==66
scalar dropped_finance = r(N_drop)


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


*Investment változó készítése
areg lnK, a(industry_year)
predict res, res
sum res, d


xtset id year
g d_res=res-l1.res
g inv=0


replace inv=1 if d_res>=0.1&d_res!=.
replace inv=-1 if d_res<=-0.1&d_res!=.
replace inv=. if d_res==.


*Teljes minta elmentése a kontrollokkal
compress
save temp/analysis_sample, replace
save_all_to_json
log close

