clear all
set more off

* find root folder
here
local here = r(here)

log using "`here'/output/balance", text replace

use "`here'/input/merleg-expat/balance-small.dta"

* keep only numeric part of frame_id
keep if substr(frame_id, 1, 2) == "ft"
generate long frame_id_numeric = real(substr(frame_id, 3, 8))
codebook frame_id*
drop frame_id
xtset frame_id_numeric year

merge m:1 frame_id_numeric year using "`here'/temp/ever_foreign.dta", keepusing(ever_foreign) keep(1 3) nogen

* calculating time_foreign - part I
count

preserve
sort frame_id_numeric year
merge m:1 frame_id_numeric year using "`here'/temp/ever_foreign.dta", keepusing(ever_foreign)
*clonevar foreign_check = fo3
*recode foreign_check (. = 0)
*tempvar t_year
*gen `t_year' = year if foreign_check == 1 & foreign_check[_n-1] == 0 
*bys frame_id_numeric: egen first_year_foreign = max(`t_year')
*gen time_foreign = year - first_year_foreign
*replace time_foreign = . if foreign_check == 0 & time_foreign > 0
egen first_year_foreign = min(cond(fo3==1, year, .)), by(frame_id_numeric)
generate time_foreign = year - first_year_foreign
*egen there_in_1995 = min(cond(year==1995, year, .)), by(frame_id_numeric )
*generate time_foreign = year - there_in_1995
contract time_foreign if _merge == 3
gen type = "balance"
save "`here'/temp/event_time_foreign_balance.dta", replace
restore

preserve
sort frame_id_numeric year
egen first_year_foreign = min(cond(fo3==1, year, .)), by(frame_id_numeric)
generate time_foreign = year - first_year_foreign
contract time_foreign
gen type = "balance-all"
save "`here'/temp/event_time_all_balance.dta", replace
restore

* foreign fill 
rename fo3 foreign
tab year foreign, missing
inspect foreign
*inspect jetok_18 if missing(foreign)
recode foreign (.=0)

* drop greenfield
bys frame_id_numeric (year): gen owner_spell = sum(foreign != foreign[_n-1])
bys frame_id_numeric: egen start_as_domestic = max((owner_spell == 1) & (foreign == 0))
keep if start_as_domestic
drop owner_spell start_as_domestic

* limit sample before large merge - sampling based on firm-level variables, firm-year done later
* average employment and financial firms deleted
* break the tie when mode is not unique

egen first_year_foreign = min(cond(foreign==1, year, .)), by(frame_id_numeric)
generate time_foreign = year - first_year_foreign
forval i = 0/3 {
	gen foreign`i' = (time_foreign == `i')
}
forval i = 1/3 {
	gen foreign_`i' = (time_foreign == -`i')
}
gen count = 1

sort frame_id_numeric year
gen x = year - year[_n-1] if frame_id_numeric == frame_id_numeric[_n-1]
gen hole2 = (x > 2 & x != .)
gen hole1 = (x > 1 & x != .)

tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole1 hole2, stat(sum) save
mat total = r(StatTotal)
tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole1 hole2 if ever_foreign == 1, stat(sum) save
mat total = (total \ r(StatTotal))

bys frame_id_numeric: egen avg_emp = mean(emp)
bys frame_id_numeric: egen industry_mode = mode(teaor08_2d), minmode
local sample ((avg_emp >= 20) & (industry_mode != 64 & industry_mode != 65 & industry_mode != 66))
drop if !`sample'
scalar dropped_size_or_finance = r(N_drop)
display dropped_size_or_finance

drop hole* x
sort frame_id_numeric year
gen x = year - year[_n-1] if frame_id_numeric == frame_id_numeric[_n-1]
gen hole2 = (x > 2 & x != .)
gen hole1 = (x > 1 & x != .)

tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole1 hole2, stat(sum) save
mat total = (total \ r(StatTotal))
tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole1 hole2 if ever_foreign == 1, stat(sum) save
mat total = (total \ r(StatTotal))

* proxy firm founding date with first balance sheet filed
tempvar foundyear
bys frame_id_numeric: egen `foundyear' = min(year)
replace foundyear = `foundyear' if missing(foundyear)
drop `foundyear'

* deflate nominal values - FIXME: add ppi before 1992
foreach x in sales export tanass jetok ranyag ranyag8091 immat {
	cap drop `x'_18
	gen double `x'_18 = `x' / ppi18
	replace `x'_18 = `x' if year < 1992 // FIXME: till ppi before 1992 is not filled up - just to not delete those rows because of missing ln dependent variables
	}

* creating dependent variables
gen lnL = ln(emp)
gen lnM = ln(ranyag_18)
replace lnM = ln(ranyag8091_18) if year <= 1991
gen lnQ = ln(sales_18)
gen lnQL = lnQ-lnL
gen lnMQ = lnM - lnQ
gen byte exporter = export_18 > 0 & export_18 != .
gen export_share = export_18 / sales
gen exporter_5 = (export_share > .05 & export_share != .)
replace exporter_5 = . if export_share == .

*tabstat foreign foreign_0 foreign_1 count, stat(sum) save
*mat total = (total \ r(StatTotal))

* interpolate small holes
tab foreign
tempvar before
bys foreign: egen `before' = count(1)
sort frame_id_numeric year
replace foreign = 1 if l.foreign == 1 & l2.foreign == 1 & f.foreign == 1 & f2.foreign == 1
replace foreign = 0 if l.foreign == 0 & l2.foreign == 0 & f.foreign == 0 & f2.foreign == 0
bys frame_id_numeric (year): egen minyear = min(year)
bys frame_id_numeric (year): egen maxyear = max(year)
replace foreign = 1 if l.foreign == 1 & f.foreign == 1 & f2.foreign == 1 & year == (minyear + 1)
replace foreign = 1 if l.foreign == 1 & l2.foreign == 1 & f.foreign == 1 & year == (minyear + 1)
replace foreign = 0 if l.foreign == 0 & f.foreign == 0 & f2.foreign == 0 & year == (maxyear - 1)
replace foreign = 0 if l.foreign == 0 & l2.foreign == 0 & f.foreign == 0 & year == (maxyear - 1)
tempvar after
bys foreign: egen `after' = count(1)
scalar foreign_interpolate = `before'-`after'
display foreign_interpolate

drop hole* x
sort frame_id_numeric year
gen x = year - year[_n-1] if frame_id_numeric == frame_id_numeric[_n-1]
gen hole2 = (x > 2 & x != .)
gen hole1 = (x > 1 & x != .)

tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole1 hole2, stat(sum) save
mat total = (total \ r(StatTotal))
tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole1 hole2 if ever_foreign == 1, stat(sum) save
mat total = (total \ r(StatTotal))

* extrapolate capital stock
inspect tanass_18
tempvar gap 
generate `gap' = missing(tanass_18) | (tanass_18 <= 0)
bysort frame_id_numeric (year): generate spell = sum(`gap' != `gap'[_n-1])

egen gap_length = count(1), by(frame_id_numeric spell)
egen max_spell = max(spell), by(frame_id_numeric)
* if gap_length <= 2, interpolate tanass with geometric average
bysort frame_id_numeric (year): replace tanass_18 = sqrt(tanass_18[_n-1] * tanass_18[_n+1]) if gap_length==1 & `gap'==1
bysort frame_id_numeric (year): replace tanass_18 = tanass_18[_n-1]^0.67 * tanass_18[_n+2]^0.33 if gap_length==2 & `gap'==1 & `gap'[_n-1]==0
bysort frame_id_numeric (year): replace tanass_18 = tanass_18[_n-2]^0.33 * tanass_18[_n+1]^0.67 if gap_length==2 & `gap'==1 & `gap'[_n+1]==0
* at either end, extrapolate for 1 year
bysort frame_id_numeric (year): replace tanass_18 = tanass_18[_n+1] if spell==1 & `gap'==1 & `gap'[_n+1]==0
bysort frame_id_numeric (year): replace tanass_18 = tanass_18[_n-1] if spell==max_spell & `gap'==1 & `gap'[_n-1]==0

drop spell gap_length max_spell
replace tanass_18 = round(tanass_18)
inspect tanass_18

gen lnK = ln(tanass_18)
gen lnKL = lnK - lnL
generate RperK = immat / (immat + tanass)
replace RperK = 0 if RperK < 0 | missing(immat)
label variable RperK "Share of immaterial assets [0,1]"

* firm-year deletions
count if missing(lnK, lnQ, lnL, lnM, foreign) & year > 1991
count if missing(lnK, lnQ, lnL, lnM, foreign)
*drop if missing(lnK, lnQ, lnL, lnM, foreign) // ASK: whether year condition needed
*count

foreach var in lnK lnQ lnL lnM {

	drop if missing(`var')

	drop hole* x
	sort frame_id_numeric year
	gen x = year - year[_n-1] if frame_id_numeric == frame_id_numeric[_n-1]
	gen hole2 = (x > 2 & x != .)
	gen hole1 = (x > 1 & x != .)

	tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole1 hole2, stat(sum) save
	mat total = (total \ r(StatTotal))
	tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole1 hole2 if ever_foreign == 1, stat(sum) save
	mat total = (total \ r(StatTotal))
}

*drop if missing(foreign)
*tabstat foreign foreign_0 foreign_1 count, stat(sum) save
*mat total = (total \ r(StatTotal))

drop count hole* x
mat list total
count

* TFP (Cobb-Douglas)
* FIXME: Replace CD with something fancy
recode industry_mode (6 75 7 66 84 19 51 = .)

levelsof industry_mode, local(levels)
	foreach l of local levels {
	disp `l'
	qui reghdfe lnQ lnL lnK lnM if industry_mode == `l', a(frame_id_numeric year foundyear) resid
	predict tfp_cd_`l', res
	}

gen  TFP_cd =  .
levelsof industry_mode, local(levels)
foreach l of local levels {

		qui replace TFP_cd = tfp_cd_`l' if TFP_cd == .
}

drop tfp_cd_*

* industry dummy and age
gen byte industrial_firm = inlist(teaor08_1d,"B","C","D","E")
gen age = year - foundyear
count

* missing export means 0 export
mvencode export exporter exporter_5, mv(0) override
generate domestic_sales = sales - export
replace domestic_sales = 0 if domestic_sales < 0 | missing(domestic_sales)

* calculating time_foreign - part II
count

preserve
sort frame_id_numeric year
merge m:1 frame_id_numeric year using "`here'/temp/ever_foreign.dta", keepusing(ever_foreign)
drop first_year_foreign time_foreign
egen first_year_foreign = min(cond(foreign==1, year, .)), by(frame_id_numeric)
generate time_foreign = year - first_year_foreign
contract time_foreign if _merge == 3
gen type = "clean"
save "`here'/temp/event_time_foreign_clean.dta", replace
restore

preserve
sort frame_id_numeric year
drop first_year_foreign time_foreign
egen first_year_foreign = min(cond(foreign==1, year, .)), by(frame_id_numeric)
generate time_foreign = year - first_year_foreign
contract time_foreign
gen type = "clean-all"
save "`here'/temp/event_time_all_clean.dta", replace
restore

count

matrix rownames total = "beginning" "sampling" "interpolating fo3 holes" "missing lnK" "missing lnQ" "missing lnL" "missing lnM"
mata : mat_total_balance = st_matrix("total")
mata: mata matsave "temp/matrix-balance" mat_total_balance, replace

save_all_to_json
cap drop __*
save "`here'/temp/balance-small-clean.dta", replace
log close
