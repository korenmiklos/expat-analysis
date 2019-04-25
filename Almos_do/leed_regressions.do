use "$datadir/analysis_sample_bertarifa.dta", clear

gen low = 1 if (voc | elem)
recode low (. = 0) if voc == 0 | elem == 0

foreach X of varlist univ high low  {
	eststo: qui reghdfe `X' foreign during after during_foreign during_expat [aw = inverse_weight_1] if $sample_acquisitions, a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir/Regression\employment_effect.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear

gen lnW = ln(brutto2)

foreach X of varlist univ high low  {
	eststo: qui reghdfe lnW foreign during after during_foreign during_expat [aw = inverse_weight_1] if $sample_acquisitions & `X', a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir/Regression\wage_effect.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear
