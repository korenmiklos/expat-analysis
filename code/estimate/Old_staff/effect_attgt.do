**************
*Prepare data
**************

global here "/srv/sandbox/expat/almos"
use "$here/temp/analysis_sample.dta", clear
keep if ever_foreign_hire==1
drop if time_foreign<-10
drop if time_foreign>10 & time_foreign!=.

gen trend_plus=time_foreign+100

gen x=exporter if time_foreign==-1 | time_foreign==-2
egen exporter_pre=max(x), by(frame_id_numeric)
drop x

gen local_ceo=(has_expat_ceo==0  & foreign_hire==1)
egen ever_local=max(local), by(frame_id_numeric)


*Tradeable-nontradeable grouping

*Create teaor in year -1, drop agriculture

tempvar x
gen `x'=teaor08_2d if time_foreign==-1
egen teaor08_2d_pre=max(`x'), by(frame_id_numeric)

egen teaor08_1d_num=group(teaor08_1d)

tempvar x
gen `x'=teaor08_1d_num if time_foreign==-1
egen teaor08_1d_pre=max(`x'), by(frame_id_numeric)

drop if teaor08_2d_pre<5

gen industrial_pre=(teaor08_2d_pre<40)

*TFP
drop TFP_cd

quietly reg lnQ lnK lnL lnM i.teaor08_2d##year if industrial_firm==1
predict TFP if e(sample), res
quietly reg lnQ lnK lnL lnM i.teaor08_2d##year if industrial_firm==0
predict TFP_temp if e(sample), res
replace TFP=TFP_temp if TFP==.
drop TFP_temp


*Regressions on foreign_hire sample, local and expat separately

*Samples
global local_sample "ever_local==1 | foreign==0"
global expat_sample "ever_expat==1 | foreign==0"

global varlist_rhs "lnQ TFP lnK lnL lnKL exporter lnEx lnQd"


*Local-expat, whole sample

preserve
keep if $local_sample==1

foreach Y in $varlist_rhs {

attgt `Y', treatment(local_ceo) aggregate(prepost) pre(3) post(5) notyet

}
restore

preserve
keep if $expat_sample==1

foreach Y in $varlist_rhs {

attgt `Y', treatment(has_expat_ceo) aggregate(prepost) pre(3) post(5) 

}
restore



quietly xthdidregress ra (lnQ) (has_expat_ceo), group(frame_id_numeric) vce(cluster frame_id_numeric)
eventstudy, pre(3) post(4) baseline(-3) generate(event_expat)

quietly xthdidregress ra (lnQ) (local_ceo), group(frame_id_numeric) vce(cluster frame_id_numeric)
eventstudy, pre(3) post(4) baseline(-3) generate(event_local)

frame event_expat: frlink 1:1 time, frame(event_local) generate(local)
frame event_expat: frget coef_local=coef upper_local=upper lower_local=lower, from(local)

frame event_expat: graph twoway (rarea lower upper time, fcolor(red%10) lcolor(red%10)) (line coef time, color(red)) (rarea lower_local upper_local time, fcolor(gs10%10) lcolor(gs5%10)) (line coef_local time, color(grey)), graphregion(color(white)) xlabel(-3(1)4) legend(off) xline(-0.5) xtitle("Event time") yline(0) 

gr export "$here/output/twfe/expat_TFP_cd_fh.png", replace











preserve
keep if ever_expat==1 | foreign==0

attgt lnQ, treatment(has_expat_ceo) aggregate(prepost) pre(3) post(5) 
attgt lnQ, treatment(has_expat_ceo) aggregate(e) pre(3) post(5) baseline(-3) 
restore



*With treatment2
local varlist_rhs "lnK lnIK exporter TFP_cd"


foreach type in att e  {
	
preserve
keep if ever_foreign_hire==1

foreach var_rhs in `varlist_rhs' {
	
	display " "	
	display "`var_rhs'"
	
	quietly attgt `var_rhs', treatment(has_expat_ceo) aggregate(e) pre(3) post(5) treatment2(foreign_hire)
	est store t_`var_rhs'
	
}
	
esttab t_lnK t_lnIK t_exporter t_TFP_cd using "$here/output/table/fh_sample_`type'.tex", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2
restore

}	



*Baseline
local varlist_rhs "lnK lnIK exporter TFP_cd"

eststo clear

foreach type in att e  {
	
foreach var_rhs in `varlist_rhs' {
	
	display " "	
	display "foreign"
	display "`var_rhs'"
	
	quietly attgt `var_rhs', treatment(foreign) aggregate(`type') pre(3) post(5) notyet
	est store t_`var_rhs'

}

esttab t_lnK t_lnIK t_exporter t_TFP_cd using "$here/output/table/foreign_`type'_baseline.tex", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2
eststo clear

preserve
keep if foreign==0 | ever_foreign_hire==1
	
foreach var_rhs in `varlist_rhs' {
	
	display " "	
	display "foreign_hire"
	display "`var_rhs'"
	
	quietly attgt `var_rhs', treatment(foreign_hire) aggregate(`type') pre(3) post(5) notyet
	est store t_`var_rhs'
	
}
	
esttab t_lnK t_lnIK t_exporter t_TFP_cd using "$here/output/table/foreign_hire_`type'_baseline.tex", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2
eststo clear

restore

preserve
keep if foreign==0 | ever_expat==1

foreach var_rhs in `varlist_rhs' {
	
	display " "	
	display "expat"
	display "`var_rhs'"
	
	quietly attgt `var_rhs', treatment(has_expat_ceo) aggregate(`type') pre(3) post(5) notyet
	est store t_`var_rhs'
	
}
	
esttab t_lnK t_lnIK t_exporter t_TFP_cd using "$here/output/table/expat_`type'_baseline.tex", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2
eststo clear	

restore
	
}




