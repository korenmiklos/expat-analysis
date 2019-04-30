use "$datadir\analysis_sample_bertarifa.dta", clear

keep if brutto2 < .
label var foreign "Foreign"

gen low = 1 if voc | elem
recode low (. = 0) if voc == 0 | elem == 0

gen lnW = ln(brutto2)

*Composite weight

egen person_firm_year_tag = tag(manager_id frame_id year)
tempvar n x
gen `n' = 1
bysort frame_id year: egen N1 = sum(`n') if $sample_baseline_1 & person_firm_year_tag
gen w = 1/N1
bysort frame_id year: egen inverse_weight_1 = max(w)
drop w N1

gen x = inverse_weight_1*wght
bysort frame_id manager_id year: egen weight_composite = max(x)



foreach X of varlist univ high low  {
	eststo: qui reghdfe `X' foreign during during_foreign during_expat [aw = inverse_weight_1] if $sample_acquisitions_1, a($fixed_effects) cluster(frame_id)
}


foreach X of varlist univ high low  {
	eststo: qui reghdfe lnW foreign during during_foreign during_expat [aw = inverse_weight_1] if $sample_acquisitions_1 & `X', a($fixed_effects) cluster(frame_id)
}
esttab using "$outputdir\Regression\emp_wage_effect.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote alignment(D{.}{.}{-1}) replace label
eststo clear
