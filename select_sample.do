clear all
set more off
use "input/balance-small/balance-small.dta"
* proxy firm founding date with first balance sheet filed
egen foundyear = min(year), by(frame_id)

* limit sample before large merge
*Függő változók készítése
gen lnL=ln(emp)
gen lnM=ln(ranyag)
replace lnM = ln(ranyag8091) if year <= 1991
gen lnQ=ln(sales)
gen lnQL=lnQ-lnL
gen lnMQ = lnM - lnQ
gen byte exporter = export>0&export!=.
gen exporter_5 = (export/sales > .05 & export < .)
* FIXME: interpolate small holes

*Átlagos létszám változó
bys frame_id: egen avg_emp = mean(emp)
*Mintavétel cégszintű változók alapján, cégév a modellek előtt
local sample (avg_emp>=20) //&!missing(lnL,lnQ,exporter)
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
* FIXME: interpolate small holes

* keep only numeric part of frame_id
keep if substr(frame_id, 1, 2) == "ft"
generate long frame_id_numeric = real(substr(frame_id, 3, 8))
codebook frame_id*

drop frame_id

*foreign-at többször váltók kidobása
xtset frame_id_numeric year
*lyukak miatt [n_1]
*gen foreign_change=1 if l1.foreign==0&foreign==1
*gen foreign_change_rev=1 if l1.foreign==1&foreign==0
sort frame_id year
gen foreign_change=1 if foreign[_n-1]==0&foreign==1&frame_id[_n-1]==frame_id
gen foreign_change_rev=1 if foreign[_n-1]==1&foreign==0&frame_id[_n-1]==frame_id
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
display dropped_too_many_foreign_change

*divesztíció
recode foreign_change_rev (.=0)
bys frame_id (year): gen divest=sum(foreign_change_rev)
replace divest=1 if divest>0
drop foreign_change foreign_change_rev foreign_change_total foreign_change_rev_total

*Greenfield - foreign húzás után, de a sampling előtt
bys frame_id (year): gen relative_year=_n
gen foreign_infirst=1 if relative_year==1&foreign==1
bys frame_id: egen byte greenfield=max(foreign_infirst)

recode greenfield (.=0)

* extrapolate capital stock
xtset frame_id year

inspect tanass
tempvar gap 
generate `gap' = missing(tanass) | (tanass <= 0)
bysort frame_id (year): generate spell = sum(`gap' != `gap'[_n-1])

egen gap_length = count(1), by(frame_id spell)
egen max_spell = max(spell), by(frame_id)
* if gap_length <= 2, interpolate tanass with geometric average
bysort frame_id (year): replace tanass = sqrt(tanass[_n-1] * tanass[_n+1]) if gap_length==1 & `gap'==1
bysort frame_id (year): replace tanass = tanass[_n-1]^0.67 * tanass[_n+2]^0.33 if gap_length==2 & `gap'==1 & `gap'[_n-1]==0
bysort frame_id (year): replace tanass = tanass[_n-2]^0.33 * tanass[_n+1]^0.67 if gap_length==2 & `gap'==1 & `gap'[_n+1]==0
* at either end, extrapolate for 1 year
bysort frame_id (year): replace tanass = tanass[_n+1] if spell==1 & `gap'==1 & `gap'[_n+1]==0
bysort frame_id (year): replace tanass = tanass[_n-1] if spell==max_spell & `gap'==1 & `gap'[_n-1]==0

drop spell gap_length max_spell
replace tanass = round(tanass)
inspect tanass

gen lnK = ln(tanass)
gen lnKL = lnK - lnL
drop if missing(lnK) & year>1991

*TFP (Cobb-Douglas)
*FIXME: Replace CD with something fancy

bysort frame_id: egen teaor_mode = mode(teaor08_2d), maxmode
recode teaor_mode (6 75 = .) (7 = .) (66 = .) (84 = .) (19 = .) (51 = .)

levelsof teaor_mode, local(levels)
	foreach l of local levels {
	disp `l'
	qui reghdfe lnQ lnL lnK lnM if teaor_mode == `l', a(frame_id year foundyear) resid
	predict tfp_cd_`l', res
	}

gen  TFP_cd =  .
levelsof teaor_mode, local(levels)
foreach l of local levels {

		qui replace TFP_cd = tfp_cd_`l' if TFP_cd == .
}

drop tfp_cd_*


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
save "temp/balance-small.dta", replace
