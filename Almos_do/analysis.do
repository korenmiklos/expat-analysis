
*Descriptives

forval i = 1/3 {
quietly estpost sum age emp lnQL if indic == `i' & $sample_acquisitions
est store i`i'
}
esttab i1 i2 i3 using "$outputdir\descriptives\firm_level_desc.tex", ///
cell(mean(fmt(%9.2f)) sd(par fmt(%9.2f)) n) mtitle("Alw. DO" "FO not Expat" "FO & Expat") ///
label replace


*********Regressions in the paper

*Foreign effect
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign [aw = inverse_weight] if $sample_acquisitions_1 & (before | during), a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\foreign_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(foreign) noconstant nonote alignment(D{.}{.}{-1}) replace label
eststo clear

*Direct effect
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign during during_foreign during_expat [aw = inverse_weight] if $sample_acquisitions_1, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\direct_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote alignment(D{.}{.}{-1}) label replace 
eststo clear

*Direct effect, tenure <= 5
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign during during_foreign during_expat [aw = inverse_weight] if $sample_acquisitions_1 & tenure <= 5, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\direct_effect_1_ten.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote alignment(D{.}{.}{-1}) label replace 
eststo clear

*Direct effect, difference between first hires and later ones
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign during during_foreign during_first_fhire during_expat during_first_fhire_expat [aw = inverse_weight] if $sample_acquisitions_1, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\direct_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote alignment(D{.}{.}{-1}) label replace 
eststo clear


foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign during during_foreign during_expat [aw = inverse_weight] if $sample_acquisitions_1, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\direct_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote alignment(D{.}{.}{-1}) replace label
eststo clear

*Direct, long-term effects
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign during after during_foreign after_foreign ///
	during_expat after_expat div [aw = inverse_weight] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\long_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report after_foreign after_expat) noconstant nonote alignment(D{.}{.}{-1}) replace label
eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign during after during_foreign after_foreign ///
	during_expat after_expat div [aw = inverse_weight] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\long_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report after_foreign after_expat) noconstant nonote alignment(D{.}{.}{-1}) replace label
eststo clear

*Types of switches
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign $switch_type [aw = inverse_weight] if $sample_acquisitions_1, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\switch_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) noconstant nonote alignment(D{.}{.}{-1}) replace label ///
keep(foreign $switch_type)
eststo clear

*Dynamics figure

preserve

local var 
foreach var in $outcomes_1 {

	qui reghdfe `var' foreign $dynamics [aw = inverse_weight] if ///
	$sample_acquisitions_1 & tenure <= 5, a($fixed_effects) cluster(frame_id)


	forval i = 1/4 {
	gen c_`var'_foreign_`i' = _b[before_foreign_`i']
	gen se_`var'_foreign_`i' = _se[before_foreign_`i']
	gen c_`var'_expat_`i' = _b[before_expat_`i']
	gen se_`var'_expat_`i' = _se[before_expat_`i']
	}
	
	forval i = 0/5 {
	local j = `i' + 5
	gen c_`var'_foreign_`j' = _b[during_foreign_`i']
	gen se_`var'_foreign_`j' = _se[during_foreign_`i']
	gen c_`var'_expat_`j' = _b[during_expat_`i']
	gen se_`var'_expat_`j' = _se[during_expat_`i']
	}
}

keep if _n == 1
keep c_* se_*
gen x = 1

tsset x

reshape long c_lnQ_foreign_ se_lnQ_foreign_ c_lnQ_expat_ se_lnQ_expat_ ///
c_lnQL_foreign_ se_lnQL_foreign_ c_lnQL_expat_ se_lnQL_expat_ ///
c_TFP_foreign_ se_TFP_foreign_ c_TFP_expat_ se_TFP_expat_, i(x)

drop x
rename _j event
replace event = event - 5

local var
foreach var in lnQ_foreign lnQ_expat lnQL_foreign lnQL_expat TFP_foreign TFP_expat {
	gen `var'_low =  c_`var'_ - 1.96*se_`var'_
	gen `var'_high = c_`var'_ + 1.96*se_`var'_
	}

*gen c_lnQL_expat_1 = c_lnQL_foreign + c_lnQL_expat

save "$datadir\dynamics_figure.dta", replace

foreach var in $outcomes_1 {

	graph twoway (rcap `var'_foreign_low `var'_foreign_high event) (line c_`var'_foreign event), /// 
	graphregion(color(white)) xlabel(-4(1)5) legend(off) xline(-0.5) xtitle("Event Time") ///
	title("Foreign Hire") saving(`var'_gf, replace)
	*gr export "$outputdir\regression\gr_`var'_foreign.pdf", replace 

	graph twoway (rcap `var'_expat_low `var'_expat_high event) (line c_`var'_expat_ event), /// 
	graphregion(color(white)) xlabel(-4(1)5) legend(off) xline(-0.5) xtitle("Event Time") ///
	title("Expatriate") saving(`var'_gx, replace)
	*gr export "$outputdir\regression\gr_`var'_expat.pdf", replace 

	gr combine `var'_gf.gph `var'_gx.gph, ycommon xsize(8)	
	gr export "$outputdir\regression\gr_`var'.pdf", replace 
	
	}
	eststo clear
	restore

	
	
*Dynamics, switch type

preserve

local var 
local var2

foreach var in $outcomes_1 {

	qui reghdfe `var' foreign $switch_type_dynamics [aw = inverse_weight] if ///
	$sample_acquisitions_1 & tenure <= 5, a($fixed_effects) cluster(frame_id)

foreach var2 in DD ED DE EE {
	
	forval i = 1/4 {
	gen c_`var'_foreign_`var2'_`i' = _b[before_foreign_`var2'_`i']
	gen se_`var'_foreign_`var2'_`i' = _se[before_foreign_`var2'_`i']
	}
	
	forval i = 0/5 {
	local j = `i' + 5
	gen c_`var'_foreign_`var2'_`j' = _b[during_foreign_`var2'_`i']
	gen se_`var'_foreign_`var2'_`j' = _se[during_foreign_`var2'_`i']
	} 
	}
}

keep if _n == 1
keep c_* se_*
gen x = 1

tsset x

reshape long ///
c_lnQ_foreign_DD_ se_lnQ_foreign_DD_ c_lnQL_foreign_DD_ se_lnQL_foreign_DD_ c_TFP_foreign_DD_ se_TFP_foreign_DD_ ///
c_lnQ_foreign_ED_ se_lnQ_foreign_ED_ c_lnQL_foreign_ED_ se_lnQL_foreign_ED_ c_TFP_foreign_ED_ se_TFP_foreign_ED_ ///
c_lnQ_foreign_DE_ se_lnQ_foreign_DE_ c_lnQL_foreign_DE_ se_lnQL_foreign_DE_ c_TFP_foreign_DE_ se_TFP_foreign_DE_ ///
c_lnQ_foreign_EE_ se_lnQ_foreign_EE_ c_lnQL_foreign_EE_ se_lnQL_foreign_EE_ c_TFP_foreign_EE_ se_TFP_foreign_EE_, i(x)

drop x
rename _j event
replace event = event - 5

local var
foreach var in lnQ_foreign_DD lnQ_foreign_ED lnQ_foreign_DE lnQ_foreign_EE  ///
			   lnQL_foreign_DD lnQL_foreign_DE lnQL_foreign_ED lnQL_foreign_EE ///
			   TFP_foreign_DD TFP_foreign_DE TFP_foreign_ED TFP_foreign_EE {
			   
	gen `var'_low =  c_`var'_ - 1.96*se_`var'_
	gen `var'_high = c_`var'_ + 1.96*se_`var'_
	}

*gen c_lnQL_expat_1 = c_lnQL_foreign + c_lnQL_expat

save "$datadir\dynamics_types_figure.dta", replace


foreach var in $outcomes_1 {

foreach var2 in DD ED DE EE {

	graph twoway (rcap `var'_foreign_`var2'_low `var'_foreign_`var2'_high event) (line c_`var'_foreign_`var2'_ event), /// 
	graphregion(color(white)) xlabel(-4(1)5) legend(off) xline(-0.5) xtitle("Event Time") ///
	saving(`var'_gf, replace)
	gr export "$outputdir\regression\gr_`var'_`var2'.pdf", replace 

	}
	}
	eststo clear
	restore

	
	
	
***Other regressions

*Dynamics
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign $dynamics [aw = inverse_weight] if $sample_acquisitions_1 & (tenure <= 5), a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\dynamic_effect_10.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_4 before_3 before_2 before_1 ///
during_0 during_1 during_2 during_3 during_4 during_5) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
esttab using "$outputdir\Regression\dynamic_effect_11.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_foreign_* during_foreign_*) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
esttab using "$outputdir\Regression\dynamic_effect_12.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_expat_* during_expat_*) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear


*Switch dynamics
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign during $switch_type_dynamics [aw = inverse_weight] if $sample_acquisitions_1 & (tenure <= 5), a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\switch_effect_dyn_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) noconstant nonote alignment(D{.}{.}{-1}) replace label ///
keep(foreign $switch_type)
eststo clear


foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign [aw = inverse_weight] if $sample_acquisitions & (before | during), a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\foreign_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(foreign) noconstant nonote alignment(D{.}{.}{-1}) replace label
eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign during during_foreign during_expat [aw = inverse_weight] if $sample_acquisitions & (before | during), a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\direct_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign during after during_foreign after_foreign ///
	during_expat after_expat [aw = inverse_weight] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\long_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(foreign during* after*) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign DD $switch_type [aw = inverse_weight] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\switch_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign after $dynamics [aw = inverse_weight] if $sample_acquisitions & tenure <6, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\dynamic_effect_20.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_4 before_3 before_2 before_1 ///
during_0 during_1 during_2 during_3 during_4 during_5) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
esttab using "$outputdir\Regression\dynamic_effect_21.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_foreign_* during_foreign_*) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
esttab using "$outputdir\Regression\dynamic_effect_22.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_expat_* during_expat_*) ///
noconstant nonote alignment(D{.}{.}{-1}) replace
eststo clear
	
	