*********Sample, macros

local datadir "../temp" 
local outputdir "../text"

use "`datadir'/analysis_sample.dta", clear

*merge import data
drop id
generate id = real(substr(frame_id, 3, 8))
merge m:1 id year using "../input/import-dummies/import-dummies.dta", nogen keep(match master)

*Sampling
scalar Tbefore = 4
scalar Tduring = 6
scalar Tafter = 4

gen byte analysis_window = (tenure>=-Tbefore-1)&(year-first_exit_year<=Tafter)
gen byte analysis_window_1 = (tenure>=-Tbefore-1)&(year <= first_exit_year)

global sample_baseline (analysis_window == 1)
global sample_baseline_1 (analysis_window_1 == 1)

global sample_manufacturing $sample_baseline & (manufacturing==1)
global sample_acquisition $sample_baseline & (greenfield==0)
global sample_acquisition_1 $sample_baseline_1 & (greenfield==0) & divest == 0
global sample_1990s $sample_acquisition & (enter_year>=1994 & enter_year<=1999)
global sample_2000s $sample_acquisition & (enter_year>=2000)
global sample_ever_foreign $sample_acquisition & (ever_foreign==1)

global samples baseline acquisitions

global outcome_perf lnQ lnQL TFP_lp 
global outcome_input lnK lnL lnMQ
global outcome_trade exporter_5 matimport capimport
global fixed_effects firm_person teaor08_2d##year age
global report foreign during_foreign during_expat
global switch_type during_foreign_DD during_foreign_ED during_foreign_DE during_foreign_EE
global switch_type_1 during_foreign_first during_expat_first during_DD_second  during_DE_second during_ED_second during_EE_second


tempvar n N1
gen `n' = 1
bysort frame_id year: egen `N1' = sum(`n') if $sample_baseline
gen inverse_weight = 1/`N1'

xtset firm_person year


gen lnML = lnM - lnL
gen lnMQ = lnM - lnQ

*TFP

*bysort frame_id: egen teaor_mode = mode(teaor08_2d), maxmode
*recode teaor_mode (6 75 = .)
*gen lnVA = ln(sales-ranyag)
quietly tab year, gen(year_d)

*Levinsohn-Petrin

keep if $sample_acquisition_1
egen x = tag(frame_id year)
keep if x 

levelsof teaor_mode, local(levels)
foreach l of local levels {
  disp `l'
  qui prodest lnVA if teaor_mode == `l', ///
            free(lnL) state(lnK) proxy(lnM)  ///
            met(lp) va att control (year_d*) id(firm_person) t(year) fsres(tfp_lp_`l')
}


gen  x =  .
levelsof teaor_mode, local(levels)
foreach l of local levels {

		replace x = tfp_lp_`l' if x == .
}

bysort frame_id year: egen  TFP_lp = max(x)

drop tfp_lp_* x

*Cobb-Douglas
keep if $sample_acquisition_1
egen x = tag(frame_id year)
keep if x 


recode teaor_mode (7 = .) (66 = .) (84 = .) (19 = .) (51 = .)
levelsof teaor_mode, local(levels)
foreach l of local levels {
  disp `l'
  qui reghdfe lnVA lnL lnK lnM [aw = inverse_weight] if teaor_mode == `l', a(firm_person year age_cat) resid
  predict tfp_cd_`l', res
  }


gen  TFP_cd =  .
levelsof teaor_mode, local(levels)
foreach l of local levels {

		qui replace TFP_cd = tfp_cd_`l' if TFP_cd == .
}

drop tfp_cd_*

keep frame_id year TFP_cd
sort frame_id year
tempfile TFP
save `TFP', replace

* what is this file? is it the same as "temp/analysis_sample.dta"?
use "`datadir'/analysis_sample_t.dta", clear
merge m:1 frame_id year using `TFP'

*Firm growth
gen sales_gr = lnQ - l.lnQ
label var sales_gr "Sales Growth"

* Foreign cleaning + Divestment dummy
gen x = (foreign == 1 & l.foreign == 0 & f.foreign == 0)
replace foreign = 0 if x
replace first_year_foreign = . if x
recode foreign (0 = 1) if l.foreign == 1 & year == 2015
recode foreign (0 = 1) if l.foreign == 1 & year == 2016
drop x
bysort firm_person: egen x = max(year) if foreign
bysort firm_person: egen last_year_foreign = max(x)
gen divest = (last_year_foreign < year)
drop x

*Exporter cleaning
recode exporter_5 (0 = 1) if l.exporter_5 == 1 & f.exporter_5 == 1

*Managers hired by foreign owners
drop foreign_hire during_foreign after_foreign before_foreign during_expat ever_foreign_hire
gen byte foreign_hire = (first_year_foreign <= enter_year)
gen during_foreign = during*foreign_hire
gen byte after_foreign = after*foreign_hire
gen byte before_foreign = before*foreign_hire

bysort frame_id: egen ever_foreign_hire = max(foreign_hire)

gen during_expat = during_foreign*expat


*First foreign manager
bysort frame_id: egen enter_year_min = min(enter_year) if foreign & $sample_acquisition_1
gen foreign_hire_first = (enter_year_min == enter_year & foreign)
gen during_foreign_first = during_foreign*foreign_hire_first
gen during_expat_first = during_foreign*foreign_hire_first*expat
recode during_foreign_first during_expat_first (. = 0)

*Later hires
gen during_foreign_second = during_foreign
replace during_foreign_second = 0 if during_foreign_first
gen during_expat_second = during_expat
replace during_expat_second = 0 if during_expat_first

foreach X of varlist DD ED DE EE {
	gen during_`X'_second = during_foreign_second*`X'
	}
	


*Dynamics

gen before_1 = before if tenure == -4
gen before_2 = before if tenure == -3
gen before_3 = before if tenure == -2
gen before_4 = before if tenure == -1
recode before_1 before_2 before_3 before_4 (. = 0)

forval i = 1/4 {

	gen before_foreign_`i' = before_foreign*before_`i'
	gen before_expat_`i' = before_expat*before_`i'
}

forval i = 0/5 {
	gen during_`i' = during if tenure == `i'
	gen during_foreign_`i' = during_foreign*during_`i'
	gen during_expat_`i' = during_expat*during_`i'
}
recode during_0 - during_expat_5 (. = 0)

*replace during_5 = during if tenure > 5 & tenure < .
*replace during_foreign_5 = during_foreign if tenure > 5 & tenure < .
*replace during_expat_5 = during_expat if tenure > 5 & tenure < .

global dynamics before_1 before_2 before_3 before_4 ///
				during_0 during_1 during_2 during_3 during_4 during_5 ///
				before_foreign_1 before_foreign_2 before_foreign_3 before_foreign_4 ///
				during_foreign_0 during_foreign_1 during_foreign_2 during_foreign_3 during_foreign_4 during_foreign_5 ///
				before_expat_1 before_expat_2 before_expat_3 before_expat_4 ///
				during_expat_0 during_expat_1 during_expat_2 during_expat_3 during_expat_4 during_expat_5
				 

				 
*Types of switches

foreach X of varlist DD DE ED EE {

	gen before_foreign_`X' = before_foreign*`X'
	gen during_foreign_`X' = during_foreign*`X'
}

label var during_foreign_DD "Local-Local"
label var during_foreign_DE "Local-Expat"
label var during_foreign_ED "Expat-Local"
label var during_foreign_EE "Expat-Expat"


				 
*Types of switches dynamics

foreach X of varlist DD DE ED EE {

forval i = 1/4 {

	gen before_foreign_`X'_`i' = before_foreign_`X'*before_`i'
}

forval i = 0/5 {

	gen during_foreign_`X'_`i' = during_foreign_`X' if tenure == `i'
}
}

recode before_foreign_DD_1- during_foreign_EE_5 (. = 0)

global switch_type_dynamics ///
before_1 before_2 before_3 before_4 during_0 during_1 during_2 during_3 during_4 during_5 ///
before_foreign_DD_1 before_foreign_DD_2 before_foreign_DD_3 before_foreign_DD_4 during_foreign_DD_* ///
before_foreign_ED_1 before_foreign_ED_2 before_foreign_ED_3 before_foreign_ED_4 during_foreign_ED_* ///
before_foreign_DE_1 before_foreign_DE_2 before_foreign_DE_3 before_foreign_DE_4 during_foreign_DE_* ///
before_foreign_EE_1 before_foreign_EE_2 before_foreign_EE_3 before_foreign_EE_4 during_foreign_EE_*

gen Q_mill = sales14/1000000
gen QL = sales14/emp*1000000

label var age "Firm Age"
labe var emp "Employment"
label var lnL "Emp."
label var lnKL "K/L"
label var lnK "Capital"
label var lnQL "Labor Prod."
label var exporter "Exporter"
label var lnQ "Output"
label var lnM "Materials"
label var TFP_lp "TFP"
label var TFP_cd "TFP"

label var foreign "Foreign Owned"
label var during "Local Man."
label var during_foreign "Foreign Hired CEO"
label var during_expat "Expatriate"
label var after_foreign "Foreign Hired CEO Post"
label var after_expat "Expatriate Post"
label var exporter_5 "Exporter"
label var matimport "Import mat."
label var capimport "Import capital"

label var ever_foreign_hire "Foreign hire"
label var ever_expat "Expat"

* I see. But how can we read before it is saved?
save "`datadir'/analysis_sample_t.dta", replace


*old stuff

*For selection: previous year to foreign, first hires
*redo when data issues are clarified

gen foreign_first = 1 if tenure_foreign == 0
recode foreign_first (. = 0)

gen local_first = 0
replace local_first = 1 if tenure_foreign == 0 & (during_foreign == 1 | f1.during_foreign == 1)
recode local_first (. = 0)

gen expat_first = 0
replace expat_first = 1 if tenure_foreign == 0 & (during_expat == 1 | f1.during_expat == 1)
recode expat_first (. = 0)

bysort frame_id year: egen x = max(expat_first)
bysort frame_id year: egen xx = max(local_first)

sort firm_person year
gen foreign_first_f = (f.tenure_foreign == 0)
gen expat_first_f = f.x
gen local_first_f = f.xx

replace local_first_f = 0 if expat_first_f == 1
drop x*
