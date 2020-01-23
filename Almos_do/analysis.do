
***Descriptives, selection

*Number of firms with foreign ownership and foreign hire
codebook frame_id if foreign & $sample_acquisition_1
codebook frame_id if during_foreign_hire & $sample_acquisition_1
codebook frame_id if during_expat & $sample_acquisition_1

*Descriptives

*Firm characteristics
bysort foreign: sum emp lnQL TFP_lp [aw = inverse_weight] if $sample_acquisition_1 

*CEO tenure

histogram tenure if tenure >= 0 & tenure < 40 & $sample_acquisition_1, discrete fraction fcolor(gs13) lcolor(gs8) lpattern(solid) xtitle(Tenure) graphregion(color(white))
gr export "../output/selection/hist_tenure.pdf", replace
*CEO max tenure

gen x = tenure if year == first_exit_year & $sample_acquisition_1
replace x = 40 if tenure > 40 & tenure < .
histogram x, discrete fraction fcolor(gs13) lcolor(gs8) lpattern(solid) xtitle(Tenure) graphregion(color(white))
gr export "../output/selection/hist_tenuremax.pdf", replace
restore

*Number CEOs in firm-year
gen n = 1 if $sample_acquisition_1 & during
bysort frame_id year: egen n_ceo = sum(n)
replace n_ceo = . if n == .
preserve
duplicates drop frame_id year, force
histogram n_ceo if $sample_acquisition_1 & during, discrete fraction fcolor(gs13) lcolor(gs8) lpattern(solid) xtitle(Number CEO) graphregion(color(white))
gr export "../output/selection/hist_nceo.pdf", replace
restore


*Selection desc

sort firm_person year
global descvar emp lnQ lnQL TFP_lp exporter_5
estpost sum $descvar [aw = inverse_weight] if !ever_foreign & $sample_acquisition_1
est store d1
estpost sum $descvar [aw = inverse_weight] if foreign & !ever_foreign_hire & $sample_acquisition_1
est store d2
estpost sum $descvar [aw = inverse_weight] if during_foreign_first == 0 & (f.during_foreign_first == 1 | f2.during_foreign_first == 1) & f.during_expat_first == 0 & $sample_acquisition_1
est store d3
estpost sum $descvar [aw = inverse_weight] if !during_expat_first & (f.during_expat_first == 1 | f2.during_expat_first == 1) & $sample_acquisition_1
est store d4

esttab d1 d2 d3 d4 using "../output/selection/desc_firmvars_1.csv", main(mean) mtitle("Domestic" "Incumbent" "Local" "Expat") label pare replace

esttab d1 d2 d3 d4 using "../output/selection/desc_firmvars_1.csv", main(mean) aux(sd) mtitle("Domestic" "Incumbent" "Local" "Expat") label pare replace
eststo clear

sort firm_person year
gen type = 1 if !ever_foreign & $sample_acquisition_1
replace type = 2 if foreign & !ever_foreign_hire & $sample_acquisition_1
replace type = 3 if during_foreign_first == 0 & (f.during_foreign_first == 1 | f2.during_foreign_first == 1) & f.during_expat_first == 0 & $sample_acquisition_1
replace type = 4 if !during_expat_first & (f.during_expat_first == 1 | f2.during_expat_first == 1) & $sample_acquisition_1
label def val 1 "Domestic" 2 "Incumbent" 3 "F. hire local" 4 "F. hire expat."
label val type val 


graph bar (mean) emp, over(type, label(angle(forty_five))) cw bar(1, fcolor(gs13) lcolor(gs9)) 	graphregion(color(white)) ytitle(Employment) name(f_emp, replace)
gr export "../output/selection/g_selection_emp.pdf", replace


graph bar (mean) TFP_lp, over(type, label(angle(forty_five))) cw bar(1, fcolor(gs13) lcolor(gs9)) 	graphregion(color(white)) ytitle(TFP) name(f_TFP_lp, replace)
gr export "../output/selection/g_selection_TFP.pdf", replace

graph bar (mean) exporter_5, over(type, label(angle(forty_five))) cw bar(1, fcolor(gs13) lcolor(gs9)) 	graphregion(color(white)) ytitle(Exporter) name(f_exporter_5, replace)
gr export "../output/selection/g_selection_export.pdf", replace

*qui graph combine f_emp f_TFP_lp f_exporter_5, graphregion(color(white))
*gr export "$outputdir\selection\g_selection.pdf", replace


*Selection regressions
eststo: quietly reghdfe foreign_preyear lnK lnQL exporter_5 [aw = inverse_weight] if $sample_acquisition_1, a(teaor08_2d##year) cluster(id)
sum foreign_preyear if e(sample)
estadd scalar mean2 = r(mean)
est store est1

eststo: quietly reghdfe local_first lnK lnQL exporter_5 [aw = inverse_weight] if foreign_preyear == 1 & expat_first == 0 & $sample_acquisition_1, a(teaor08_2d##year) cluster(id)
sum local_first if e(sample)
estadd scalar mean2 = r(mean)
est store est2

eststo: quietly reghdfe expat_first lnK lnQL exporter_5 [aw = inverse_weight] if foreign_preyear == 1 & local_first == 0 & $sample_acquisition_1, a(teaor08_2d##year) cluster(id)
sum expat_first if e(sample)
estadd scalar mean2 = r(mean)
est store est3

esttab est1 est2 est3 using "../output/selection/selection_regression.tex", star(* .1 ** .05 *** .01) b(3) keep(lnK sales_gr lnQL exporter_5) ///
scalar("mean2 Mean depvar" ) noconstant nonote se replace label r2
eststo clear


*********Regressions in the paper

*Foreign effect
foreach X of varlist $outcome_perf {
	eststo: qui reghdfe `X' foreign [aw = inverse_weight] if $sample_acquisition_1, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/foreign_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(foreign) noconstant nonote replace label
eststo clear

*Direct effect
foreach X of varlist $outcome_perf {
	eststo: qui reghdfe `X' foreign during during_foreign during_expat [aw = inverse_weight] if $sample_acquisition_1, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/direct_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote label replace 
eststo clear

*Direct effect, tenure <= 5
foreach X of varlist $outcome_perf {
	eststo: qui reghdfe `X' foreign during during_foreign during_expat [aw = inverse_weight] if $sample_acquisition_1 & tenure <= 5, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/direct_effect_1_ten.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote label replace 
eststo clear

foreach X of varlist $outcome_input {
	eststo: qui reghdfe `X' foreign during during_foreign during_expat [aw = inverse_weight] if $sample_acquisition_1, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/direct_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote replace label
eststo clear


foreach X of varlist $outcome_trade {
	eststo: qui reghdfe `X' foreign during during_foreign during_expat [aw = inverse_weight] if $sample_acquisition_1, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/direct_effect_trade.tex", r2 star(* .11 ** .05 *** .01) se b(3) keep($report) noconstant nonote replace label
eststo clear

*Direct, long-term effects
foreach X of varlist $outcome_perf {
	eststo: qui reghdfe `X' foreign during after during_foreign after_foreign ///
	during_expat after_expat div [aw = inverse_weight] if $sample_acquisition, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/long_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report after_foreign after_expat) noconstant nonote replace label
eststo clear

foreach X of varlist $outcome_perf {
	eststo: qui reghdfe `X' foreign during after during_foreign after_foreign ///
	during_expat after_expat div [aw = inverse_weight] if $sample_acquisition, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/long_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report after_foreign after_expat) noconstant nonote replace label
eststo clear

*Types of switches
foreach X of varlist $outcome_perf {
	eststo: qui reghdfe `X' foreign $switch_type [aw = inverse_weight] if $sample_acquisition_1, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/switch_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) noconstant nonote replace label ///
keep(foreign $switch_type)
eststo clear

*Direct effect, difference between first hires and later ones
foreach X of varlist $outcome_perf {
	eststo: qui reghdfe `X' foreign during_foreign_first during_foreign_second during_expat_first during_expat_second [aw = inverse_weight] if $sample_acquisition_1, a($fixed_effects) cluster(frame_id)
}
*esttab using "$outputdir\effect\direct_effect_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote label replace 
eststo clear

foreach X of varlist $outcome_perf {
	eststo: qui reghdfe `X' foreign $switch_type_1 during [aw = inverse_weight] if $sample_acquisition_1, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/direct_effect_1_switch.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($switch_type_1) noconstant nonote label replace 
eststo clear

foreach X of varlist $outcome_input {
	eststo: qui reghdfe `X' foreign $switch_type_1 during [aw = inverse_weight] if $sample_acquisition_1, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/direct_effect_input_switch.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($switch_type_1) noconstant nonote label replace 
eststo clear

foreach X of varlist $outcome_trade {
	eststo: qui reghdfe `X' foreign $switch_type_1 during [aw = inverse_weight] if $sample_acquisition_1, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/direct_effect_trade_switch.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($switch_type_1) noconstant nonote label replace 
eststo clear

*Dynamics figure

preserve

local var 
foreach var in $outcome_perf {

	qui reghdfe `var' foreign $dynamics [aw = inverse_weight] if ///
	$sample_acquisition_1 & tenure <= 5, a($fixed_effects) cluster(frame_id)


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
c_TFP_lp_foreign_ se_TFP_lp_foreign_ c_TFP_lp_expat_ se_TFP_lp_expat_, i(x)

drop x
rename _j event
replace event = event - 5

local var
foreach var in lnQ_foreign lnQ_expat lnQL_foreign lnQL_expat TFP_lp_foreign TFP_lp_expat {
	gen `var'_low =  c_`var'_ - 1.96*se_`var'_
	gen `var'_high = c_`var'_ + 1.96*se_`var'_
	}

*gen c_lnQL_expat_1 = c_lnQL_foreign + c_lnQL_expat

save "../temp/dynamics_figure.dta", replace

foreach var in $outcome_perf {

	graph twoway (rcap `var'_foreign_low `var'_foreign_high event) (line c_`var'_foreign event), /// 
	graphregion(color(white)) xlabel(-4(1)5) legend(off) xline(-0.5) xtitle("Event Time") ///
	title("Foreign Hire") saving(`var'_gf, replace)
	*gr export "$outputdir\effect\gr_`var'_foreign.pdf", replace 

	graph twoway (rcap `var'_expat_low `var'_expat_high event) (line c_`var'_expat_ event), /// 
	graphregion(color(white)) xlabel(-4(1)5) legend(off) xline(-0.5) xtitle("Event Time") ///
	title("Expatriate") saving(`var'_gx, replace)
	*gr export "$outputdir\effect\gr_`var'_expat.pdf", replace 

	gr combine `var'_gf.gph `var'_gx.gph, ycommon xsize(8)	
	gr export "../output/effect/gr_`var'.pdf", replace 
	
	}
	eststo clear
	restore

	
	
*Dynamics, switch type

preserve

local var 
local var2

foreach var in $outcome_perf {

	qui reghdfe `var' foreign $switch_type_dynamics [aw = inverse_weight] if ///
	$sample_acquisition_1 & tenure <= 5, a($fixed_effects) cluster(frame_id)

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

save "../temp/dynamics_types_figure.dta", replace


foreach var in $outcomes_1 {

foreach var2 in DD ED DE EE {

	graph twoway (rcap `var'_foreign_`var2'_low `var'_foreign_`var2'_high event) (line c_`var'_foreign_`var2'_ event), /// 
	graphregion(color(white)) xlabel(-4(1)5) legend(off) xline(-0.5) xtitle("Event Time") ///
	saving(`var'_gf, replace)
	gr export "../output/effect/gr_`var'_`var2'.pdf", replace 

	}
	}
	eststo clear
	restore

	
	
	
***Other regressions

*Dynamics
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign $dynamics [aw = inverse_weight] if $sample_acquisition_1 & (tenure <= 5), a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/dynamic_effect_10.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_4 before_3 before_2 before_1 ///
during_0 during_1 during_2 during_3 during_4 during_5) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
esttab using "../output/effect/dynamic_effect_11.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_foreign_* during_foreign_*) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
esttab using "../output/effect/dynamic_effect_12.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_expat_* during_expat_*) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear


*Switch dynamics
foreach X of varlist $outcomes_1 {
	eststo: qui reghdfe `X' foreign during $switch_type_dynamics [aw = inverse_weight] if $sample_acquisition_1 & (tenure <= 5), a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/switch_effect_dyn_1.tex", r2 star(* .1 ** .05 *** .01) se b(3) noconstant nonote alignment(D{.}{.}{-1}) replace label ///
keep(foreign $switch_type)
eststo clear


foreach X of varlist $outcomes_imputs {
	eststo: qui reghdfe `X' foreign [aw = inverse_weight] if $sample_acquisition & (before | during), a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/foreign_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(foreign) noconstant nonote alignment(D{.}{.}{-1}) replace label
eststo clear

foreach X of varlist $outcomes_inputs {
	eststo: qui reghdfe `X' foreign during during_foreign during_expat [aw = inverse_weight] if $sample_acquisition & (before | during), a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/direct_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep($report) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign during after during_foreign after_foreign ///
	during_expat after_expat [aw = inverse_weight] if $sample_acquisition, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/long_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(foreign during* after*) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign DD $switch_type [aw = inverse_weight] if $sample_acquisition, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/switch_effect_2.tex", r2 star(* .1 ** .05 *** .01) se b(3) noconstant nonote alignment(D{.}{.}{-1}) replace 
eststo clear

foreach X of varlist $outcomes_2 {
	eststo: qui reghdfe `X' foreign after $dynamics [aw = inverse_weight] if $sample_acquisition & tenure <6, a($fixed_effects) cluster(frame_id)
}
esttab using "../output/effect/effect\dynamic_effect_20.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_4 before_3 before_2 before_1 ///
during_0 during_1 during_2 during_3 during_4 during_5) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
esttab using "../output/effect/dynamic_effect_21.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_foreign_* during_foreign_*) ///
noconstant nonote alignment(D{.}{.}{-1}) replace 
esttab using "../output/effect/dynamic_effect_22.tex", r2 star(* .1 ** .05 *** .01) se b(3) keep(before_expat_* during_expat_*) ///
noconstant nonote alignment(D{.}{.}{-1}) replace
eststo clear
	
	
