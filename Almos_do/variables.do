*********Sample, macros

global datadir "C:\Users\Almos\Documents\Research\Expat\Expat_git\temp" 
global outputdir "C:\Users\Almos\Documents\Research\Expat\Expat_git\text"

use "$datadir\analysis_sample.dta", clear

*Sampling
scalar Tbefore = 4
scalar Tduring = 6
scalar Tafter = 4

gen byte analysis_window = (tenure>=-Tbefore-1)&(year-first_exit_year<=Tafter)
gen byte analysis_window_1 = (tenure>=-Tbefore-1)&(year <= first_exit_year)

global sample_baseline (analysis_window==1)
global sample_baseline_1 (analysis_window_1 == 1)

global sample_manufacturing $sample_baseline & (manufacturing==1)
global sample_acquisitions $sample_baseline & (greenfield==0)
global sample_acquisitions_1 $sample_baseline_1 & (greenfield==0)
global sample_1990s $sample_acquisitions & (enter_year>=1994 & enter_year<=1999)
global sample_2000s $sample_acquisitions & (enter_year>=2000)
global sample_ever_foreign $sample_acquisitions & (ever_foreign==1)

global samples baseline acquisitions

global outcomes_perf lnQ lnQL TFP 
global outcomes_inputs lnK lnL lnKL lnML
global outcomes_trade exporter_5 matimport capimport
global fixed_effects firm_person teaor08_2d##year age_cat_1
global report foreign during_foreign during_expat

tempvar n N1
gen `n' = 1
bysort frame_id year: egen `N1' = sum(`n') if $sample_baseline
gen inverse_weight = 1/`N1'

* verify founders are not in analysis sample
foreach X of var during* after* {
	replace `X'=0 if founder==1
}

xtset firm_person year

rename tfp_lp TFP

*New age category variable
gen age_cat_1 = .

replace age_cat_1 = age_cat if age_cat <= 10
replace age_cat_1 = 11 if age_cat > 10 & age_cat <= 15
replace age_cat_1 = 12 if age_cat > 15 & age_cat <= 20
replace age_cat_1 = 13 if age_cat > 20 & age_cat <= 30
replace age_cat_1 = 14 if age_cat > 30 & age_cat <= 40
replace age_cat_1 = 15 if age_cat > 40 & age_cat < . 

gen lnML = lnM - lnL

*TFP

bysort frame_id: egen teaor_mode = mode(teaor08_2d), maxmode
recode teaor_mode (6 75 = .)
gen lnVA = ln(sales-ranyag)

levelsof teaor_mode, local(levels)
foreach l of local levels {
  disp `l'
  qui prodest lnVA if teaor_mode == `l' & firmyear_tag, ///
            free(lnL) state(lnK) proxy(lnM)  ///
            met(lp) va att control (year_d*) id(firm_person) t(year) fsres(tfp_lp_`l')
}


gen  x =  .
levelsof teaor_mode, local(levels)
foreach l of local levels {

		replace x = tfp_lp_`l' if x == .
}

bysort frame_id year: egen  tfp_lp = max(x)

drop tfp_lp_* x


*Managers hired by foreign owners

*gen byte foreign_hire = (first_year_foreign <= enter_year)
*gen during_foreign = during*foreign_hire
gen byte after_foreign = after*foreign_hire
gen byte before_foreign = before*foreign_hire

bysort frame_id: egen ever_foreign_hire = max(foreign_hire)


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

global switch_type during_foreign_DD during_foreign_ED during_foreign_DE during_foreign_EE
				 
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


label var age "Firm Age"
labe var emp "Employment"
label var lnL "Emp."
label var lnKL "K/L"
label var lnK "Capital"
label var lnQL "Labor Prod."
label var exporter "Exporter"
label var lnQ "Output"
label var TFP "TFP"

label var foreign "Foreign Owned"
label var during "Local Man."
label var during_foreign "Foreign Hired CEO"
label var during_expat "Expatriate"
label var after_foreign "Foreign Hired CEO Post"
label var after_expat "Expatriate Post"
label var exporter_5 "Exporter"

gen indic = .
replace indic = 1 if !ever_foreign 
replace indic = 2 if ever_foreign & !ever_expat
replace indic = 3 if ever_foreign & ever_expat

label define firmtype 1 "Always Domestic" 2 "Foreign not Expat" 3 "Foreign & Expat"
label values indic firmtype





