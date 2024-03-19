clear all
set more off

* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/balance", text replace

use "`here'/input/merleg-expat/balance-small.dta" 

* keep only numeric part of frame_id
keep if substr(frame_id, 1, 2) == "ft"
generate long frame_id_numeric = real(substr(frame_id, 3, 8))
codebook frame_id*
drop frame_id
xtset frame_id_numeric year

* use fo2 instead of fo3
merge 1:1 originalid year using "`here'/input/balance-sheet-80-19-plus-vars/balance-80-19-plus-vars.dta", keep(1 3) nogen
tab fo2 fo3, missing

* foreign fill 
rename fo3 foreign
tab year foreign, missing
inspect foreign
*inspect jetok_18 if missing(foreign)
recode foreign (.=0)

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


* limit sample before large merge - sampling based on firm-level variables, firm-year done later
* average employment and financial firms deleted
* break the tie when mode is not unique

bys frame_id_numeric: egen avg_emp = mean(emp)
bys frame_id_numeric: egen industry_mode = mode(teaor08_2d), minmode


* drop agriculture firms
drop if industry_mode < 5 
generate industrial = (industry_mode < 40)
local sample ((avg_emp >= 20) & (industry_mode != 64 & industry_mode != 65 & industry_mode != 66))
drop if !`sample'

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

* minimal employment cleaning
replace emp = 1 if emp <= 0 | missing(emp)
mvencode export_18, mv(0) override

* creating dependent variables
gen lnL = ln(emp)
gen lnM = ln(ranyag_18)
replace lnM = ln(ranyag8091_18) if year <= 1991
gen lnQ = ln(sales_18)
gen lnQL = lnQ - lnL
gen lnMQ = lnM - lnQ
generate lnEx = ln(export_18)
generate lnQd = ln(sales_18 - export_18)

gen byte exporter = export_18 > 0 & export_18 != .
gen export_share = export_18 / sales_18
gen exporter_5 = (export_share > .05 & export_share != .)
replace exporter_5 = . if export_share == .

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

foreach var in lnK lnQ lnL lnM {
	drop if missing(`var')
}

count

* industry dummy and age
gen byte industrial_firm = inlist(teaor08_1d, "B", "C", "D", "E")
gen age = year - foundyear

* missing export means 0 export
mvencode export exporter exporter_5, mv(0) override
generate domestic_sales = sales - export
replace domestic_sales = 0 if domestic_sales < 0 | missing(domestic_sales)

count

cap drop __*
save "`here'/temp/balance-small-clean.dta", replace
log close
