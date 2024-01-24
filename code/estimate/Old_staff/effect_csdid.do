*Selection on outcomes, effect

global here "/srv/sandbox/expat/almos"


*Create variables for csdid
foreach var_treat in foreign foreign_hire expat {

	tempvar x
	gen `x'=year if time_foreign==0 & ever_`var_treat'==1
	egen first_`var_treat'=max(`x'), by(frame_id_numeric)
	recode first_`var_treat' (.=0)
}

*Inputs

local varlist_input "lnK lnIK lnL lnKL"
local varlist_treat "foreign foreign_hire expat"

eststo clear
foreach var_treat in `varlist_treat' {
foreach var_outcome in `varlist_input' {
	
	quietly csdid2 `var_outcome' if foreign==0 | ever_`var_treat'==1, ivar(frame_id_numeric) tvar(year) gvar(first_`var_treat') long2
	display " "
	display " "	
	display "`var_outcome'"
	display "`var_treat'"
	estat event, revent(-5/5)
	lincomest Post_avg-Pre_avg
	est store t_`var_outcome'
	
}
esttab t_lnK t_lnIK t_lnL t_lnKL using "$here/output/table/`var_treat'_input.tex", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

}

eststo clear
foreach var_outcome in `varlist_input' {
	
	quietly csdid2 `var_outcome' if ever_foreign_hire==1 & (foreign_hire==0 | ever_expat)==1, ivar(frame_id_numeric) tvar(year) gvar(first_expat) long2

	display " "
	display " "	
	display "`var_outcome'"
	estat event, revent(-5/5)
	lincomest Post_avg-Pre_avg
	est store t_fh_`var_outcome'
}
esttab t_fh_lnK t_fh_lnIK t_fh_lnL t_fh_lnKL using "$here/output/table/input_fh.tex", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2


*Outputs

local varlist_output "lnQ exporter lnQd lnExport"
local varlist_treat "foreign foreign_hire expat"

eststo clear
foreach var_treat in `varlist_treat' {
foreach var_outcome in `varlist_output' {
	
	quietly csdid2 `var_outcome' if foreign==0 | ever_`var_treat'==1, ivar(frame_id_numeric) tvar(year) gvar(first_`var_treat') long2
	display " "
	display " "	
	display "`var_outcome'"
	display "`var_treat'"
	estat event, revent(-5/5)
	lincomest Post_avg-Pre_avg
	est store t_`var_outcome'
	
}
esttab t_lnQ t_exporter t_lnQd t_lnExport using "$here/output/table/`var_treat'_output.tex", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote

}
local varlist_output "lnQ exporter lnQd lnExport"
local varlist_treat "foreign foreign_hire expat"

eststo clear
foreach var_outcome in `varlist_output' {
	
	quietly csdid2 `var_outcome' if ever_foreign_hire==1 & (foreign_hire==0 | ever_expat)==1, ivar(frame_id_numeric) tvar(year) gvar(first_expat) long2

	display " "
	display " "	
	display "`var_outcome'"
	estat event, revent(-5/5)
	lincomest Post_avg-Pre_avg
	est store t_fh_`var_outcome'
}
esttab t_fh_lnQ t_fh_exporter t_fh_lnQd t_fh_lnExport using "$here/output/table/output_fh.tex", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote


*Productivity
local varlist_prod "lnQL TFP_cd"
local varlist_treat "foreign foreign_hire expat"

eststo clear
foreach var_treat in `varlist_treat' {
foreach var_outcome in `varlist_prod' {
	
	quietly csdid2 `var_outcome' if foreign==0 | ever_`var_treat'==1, ivar(frame_id_numeric) tvar(year) gvar(first_`var_treat') long2
	display " "
	display " "	
	display "`var_outcome'"
	display "`var_treat'"
	estat event, revent(-5/5)
	lincomest Post_avg-Pre_avg
	est store t_`var_outcome'
	
}
esttab t_lnQL t_TFP_cd using "$here/output/table/`var_treat'_prod.tex", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

}

eststo clear
foreach var_outcome in `varlist_prod' {
	
	quietly csdid2 `var_outcome' if ever_foreign_hire==1 & (foreign_hire==0 | ever_expat)==1, ivar(frame_id_numeric) tvar(year) gvar(first_expat) long2

	display " "
	display " "	
	display "`var_outcome'"
	estat event, revent(-5/5)
	lincomest Post_avg-Pre_avg
	est store t_fh_`var_outcome'
}
esttab t_lnQL t_TFP_cd using "$here/output/table/prod_fh.tex", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2
