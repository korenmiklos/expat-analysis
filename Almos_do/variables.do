*********Sample, macros

global datadir "C:\Users\Almos\Documents\Research\Expat\Expat_git\temp" 
global outputdir "C:\Users\Almos\Documents\Research\Expat\Expat_git\text"

use "$datadir\analysis_sample.dta", clear

*Sampling
scalar Tbefore = 4
scalar Tduring = 6
scalar Tafter = 4

gen byte analysis_window = (tenure>=-Tbefore-1)&(year-first_exit_year<=Tafter)

global sample_baseline (analysis_window==1)
global sample_manufacturing $sample_baseline & (manufacturing==1)
global sample_acquisitions $sample_baseline & (greenfield==0)
global sample_1990s $sample_acquisitions & (enter_year>=1994 & enter_year<=1999)
global sample_2000s $sample_acquisitions & (enter_year>=2000)
global sample_ever_foreign $sample_acquisitions & (ever_foreign==1)

global samples baseline acquisitions

global outcomes_1 lnQ lnQL TFP 
global outcomes_2 lnK lnL lnKL lnML exporter_5
global fixed_effects firm_person teaor08_2d##year age_cat_1
global report foreign during_foreign during_expat

tempvar n 
gen `n' = 1
bysort frame_id year: egen N1 = sum(`n') if $sample_baseline
gen inverse_weight_1 = 1/N1

* verify founders are not in analysis sample
foreach X of var during* after* {
	replace `X'=0 if founder==1
}

xtset firm_person year



*New age category variable
gen age_cat_1 = .

replace age_cat_1 = age_cat if age_cat <= 10
replace age_cat_1 = 11 if age_cat > 10 & age_cat <= 15
replace age_cat_1 = 12 if age_cat > 15 & age_cat <= 20
replace age_cat_1 = 13 if age_cat > 20 & age_cat <= 30
replace age_cat_1 = 14 if age_cat > 30 & age_cat <= 40
replace age_cat_1 = 15 if age_cat > 40 & age_cat < . 

gen lnML = lnM - lnL

*Firm-year tag
egen firmyear_tag = tag(frame_id year)

gen exporter_5 = 1 if export/sales > .05 & export < .
recode exporter_5 (. = 0)

*TFP
egen temp_ind = group(teaor08_2d year)
gen TFP = .
forval i = 1/84  {
quietly reg lnQ lnL lnK lnM
predict x, res
replace TFP = x if temp_ind == `i'
drop x
}
drop temp_ind


*Managers hired by foreign owners
gen byte foreign_hire = (first_year_foreign <= enter_year)
gen during_foreign = during*foreign_hire
bysort frame_id: egen ever_foreign_hire = max(foreign_hire)
global sample_ever_switch $sample_ever_foreign & (ever_foreign_hire == 1)

*foreign_hire and expat 

*Before and after variables
gen byte after_foreign = after*foreign_hire
gen byte before_foreign = before*foreign_hire
replace before = 0 if tenure < -3
replace before_foreign = 0 if tenure < -4
replace before_expat = 0 if tenure < -4

*New
gen during_foreign_new = during_foreign*new
gen during_expat_new = during_expat*new

*Types of switches
foreach X of varlist DD DE ED EE {

	gen during_foreign_`X' = during_foreign*`X'
}

global switch_type during_foreign_DD during_foreign_ED during_foreign_DE during_foreign_EE

*Dynamics

tempvar ten
gen `ten' = -tenure

forval i = 1/5 {
	gen before_`i' = before if `ten' == `i'
	gen before_foreign_`i' = before_foreign if `ten' == `i'
	gen before_expat_`i' = before_expat if `ten' == `i'
}

forval i = 0/5 {
	gen during_`i' = during if tenure == `i'
	gen during_foreign_`i' = during_foreign if tenure == `i'
	gen during_expat_`i' = during_expat if tenure == `i'
}

*replace during_5 = during if tenure > 5 & tenure < .
*replace during_foreign_5 = during_foreign if tenure > 5 & tenure < .
*replace during_expat_5 = during_expat if tenure > 5 & tenure < .

recode before_4 before_3 before_2 before_1 ///
		during_0 during_1 during_2 during_3 during_4 during_5 ///
		before_foreign_5 before_foreign_4 before_foreign_3 before_foreign_2 before_foreign_1 ///
		during_foreign_0 during_foreign_1 during_foreign_2 during_foreign_3 during_foreign_4 during_foreign_5 ///
		before_expat_5 before_expat_4 before_expat_3 before_expat_2 before_expat_1 ///
		during_expat_0 during_expat_1 during_expat_2 during_expat_3 during_expat_4 during_expat_5 (. = 0)

global dynamics before_4 before_3 before_2 before_1 ///
				during_0 during_1 during_2 during_3 during_4 during_5 ///
				before_foreign_4 before_foreign_3 before_foreign_2 before_foreign_1 ///
				during_foreign_0 during_foreign_1 during_foreign_2 during_foreign_3 during_foreign_4 during_foreign_5 ///
				before_expat_4 before_expat_3 before_expat_2 before_expat_1 ///
				during_expat_0 during_expat_1 during_expat_2 during_expat_3 during_expat_4 during_expat_5
				 
				 
				 
label var age "Firm Age"
labe var emp "Employment"
label var lnL "Emp."
label var lnKL "K/L"
label var lnK "Capital"
label var lnQL "Labor Prod."
label var exporter "Exporter"
label var lnQ "Output"

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
