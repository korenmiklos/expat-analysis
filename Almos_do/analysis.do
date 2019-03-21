
*Descriptives

forval i = 1/3 {
quietly estpost sum age emp lnQL if indic == `i' & $sample_acquisitions
est store i`i'
}
esttab i1 i2 i3 using "$outputdir\descriptives\firm_level_desc.tex", ///
cell(mean(fmt(%9.2f)) sd(par fmt(%9.2f)) n) mtitle("Alw. DO" "FO not Expat" "FO & Expat") ///
label replace



*********Regressions 

*Foreign effect
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign [aw = inverse_weight_1] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\foreign_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(foreign) noconstant nonote alignment(D{.}{.}{-1}) replace label
eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign [aw = inverse_weight_1] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\foreign_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(foreign) noconstant nonote alignment(D{.}{.}{-1}) replace label
eststo clear

*Direct effect
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign during after during_foreign during_expat [aw = inverse_weight_1] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\direct_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign during during_foreign during_expat [aw = inverse_weight_1] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\direct_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear

*Selection, direct, long-term effects
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign during after during_foreign after_foreign ///
	during_expat after_expat [aw = inverse_weight_1] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\long_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(foreign during* after*) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign during after during_foreign after_foreign ///
	during_expat after_expat [aw = inverse_weight_1] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\long_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(foreign during* after*) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear

*Dynamics
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign after $dynamics [aw = inverse_weight_1] if $sample_acquisitions & tenure <6, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\dynamic_effect_10.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_4 before_3 before_2 before_1 ///
during_0 during_1 during_2 during_3 during_4 during_5) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
esttab using "$outputdir\Regression\dynamic_effect_11.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_foreign_* during_foreign_*) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
esttab using "$outputdir\Regression\dynamic_effect_12.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_expat_* during_expat_*) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 

eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign after $dynamics [aw = inverse_weight_1] if $sample_acquisitions & tenure <6, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\dynamic_effect_20.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_4 before_3 before_2 before_1 ///
during_0 during_1 during_2 during_3 during_4 during_5) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
esttab using "$outputdir\Regression\dynamic_effect_21.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_foreign_* during_foreign_*) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
esttab using "$outputdir\Regression\dynamic_effect_22.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_expat_* during_expat_*) ///
noconstant nonote alignment(D{.}{.}{-1}) replace
eststo clear

*Types of switches
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign during after $switch_type [aw = inverse_weight_1] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\switch_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign DD $switch_type [aw = inverse_weight_1] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\switch_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear


*Dynamics figure

preserve

local var 
foreach var in lnQ lnQL exporter_5  {

	eststo: qui reghdfe `var' foreign after $dynamics [aw = inverse_weight_1] if $sample_acquisitions & tenure <6, a($fixed_effects) cluster(frame_id)


	forval i = 4(-1)1 {
	gen c_`var'_bf_`i' = _b[before_foreign_`i']
	gen se_`var'_bf_`i' = _se[before_foreign_`i']
	gen c_`var'_be_`i' = _b[before_expat_`i']
	gen se_`var'_be_`i' = _se[before_expat_`i']
	}
	
	forval i = 0/5 {
	local j = `i' + 5
	gen c_`var'_foreign_`j' = _b[during_foreign_`i']
	gen se_`var'_foreign_`j' = _se[during_foreign_`i']
	gen c_`var'_expat_`j' = _b[during_expat_`i']
	gen se_`var'_expat_`j' = _se[during_expat_`i']
	}
	
rename c_`var'_bf_4 c_`var'_foreign_1
rename c_`var'_bf_3 c_`var'_foreign_2
rename c_`var'_bf_2 c_`var'_foreign_3
rename c_`var'_bf_1 c_`var'_foreign_4
rename se_`var'_bf_4 se_`var'_foreign_1
rename se_`var'_bf_3 se_`var'_foreign_2
rename se_`var'_bf_2 se_`var'_foreign_3
rename se_`var'_bf_1 se_`var'_foreign_4

rename c_`var'_be_4 c_`var'_expat_1
rename c_`var'_be_3 c_`var'_expat_2
rename c_`var'_be_2 c_`var'_expat_3
rename c_`var'_be_1 c_`var'_expat_4
rename se_`var'_be_4 se_`var'_expat_1
rename se_`var'_be_3 se_`var'_expat_2
rename se_`var'_be_2 se_`var'_expat_3
rename se_`var'_be_1 se_`var'_expat_4

}

duplicates drop c_lnQL_foreign_5, force
keep c_* se_*
gen x = 1

tsset x
reshape long c_lnQ_foreign_ se_lnQ_foreign_ c_lnQ_expat_ se_lnQ_expat_ ///
c_lnQL_foreign_ se_lnQL_foreign_ c_lnQL_expat_ se_lnQL_expat_ ///
c_exporter_5_foreign_ se_exporter_5_foreign_ c_exporter_5_expat_ se_exporter_5_expat_, i(x)

drop x
rename _j event
replace event = event - 5

local var 
foreach var in lnQ_foreign lnQ_expat lnQL_foreign lnQL_expat exporter_5_foreign exporter_5_expat {
	gen `var'_low =  c_`var'_ - 1.96*se_`var'_
	gen `var'_high = c_`var'_ + 1.96*se_`var'_
	}

gen c_lnQL_expat_1 = c_lnQL_foreign + c_lnQL_expat

save "$datadir\dynamics_figure.dta", replace

foreach var in lnQ lnQL exporter_5 {

	graph twoway (rcap `var'_foreign_low `var'_foreign_high event) (line c_`var'_foreign event), /// 
	graphregion(color(white)) xlabel(-4(1)5) legend(off) xline(-0.5) xtitle("Event Time") ///
	title("Foreign Hire") saving(`var'_gf)
	*gr export "$outputdir\regression\gr_`var'_foreign.pdf", replace 

	graph twoway (rcap `var'_expat_low `var'_expat_high event) (line c_`var'_expat_ event), /// 
	graphregion(color(white)) xlabel(-4(1)5) legend(off) xline(-0.5) xtitle("Event Time") ///
	title("Expatriate") saving(`var'_gx)
	*gr export "$outputdir\regression\gr_`var'_expat.pdf", replace 

	gr combine `var'_gf.gph `var'_gx.gph, ycommon xsize(8)	
	gr export "$outputdir\regression\gr_`var'.pdf", replace 
	
	}
	
	restore

	
graph twoway (rcap lnQL_foreign_low lnQL_foreign_high event) (line c_lnQL_foreign event), /// 
	graphregion(color(white)) xlabel(-4(1)5) legend(off) xline(-0.5) xtitle("Event Time") ///
	title("`var' - Foreign Hire") saving(gf)
	
graph twoway (rcap lnQL_expat_low lnQL_expat_high event) (line c_lnQL_expat_ event), /// 
	graphregion(color(white)) xlabel(-4(1)5) legend(off) xline(-0.5) xtitle("Event Time") ///
	title("`var' - Expat") saving(gx)
	
	