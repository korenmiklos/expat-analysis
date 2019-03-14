
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
