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

foreach var_outcome in `varlist_input' {
foreach var_treat in `varlist_treat' {
	
	quietly csdid2 `var_outcome', ivar(frame_id_numeric) tvar(year) gvar(first_`var_treat') long2
	display " "
	display " "	
	display "`var_outcome'"
	display "`var_treat'"
	estat event, revent(-5/5)
	lincom Post_avg-Pre_avg
	
}
}

foreach var_outcome in `varlist_input' {
	
	quietly csdid2 `var_outcome' if ever_foreign_hire==1, ivar(frame_id_numeric) tvar(year) gvar(first_expat) long2

	display " "
	display " "	
	display "`var_outcome'"
	estat event, revent(-5/5)
	lincom Post_avg-Pre_avg
}


*Outputs

local varlist_output "lnQ exporter lnQd lnExport"
local varlist_treat "foreign foreign_hire expat"

foreach var_outcome in `varlist_output' {
foreach var_treat in `varlist_treat' {
	
	quietly csdid2 `var_outcome', ivar(frame_id_numeric) tvar(year) gvar(first_`var_treat') long2
	display " "
	display " "	
	display "`var_outcome'"
	display "`var_treat'"
	estat event, revent(-5/5)
	lincom Post_avg-Pre_avg
	
}
}

foreach var_outcome in `varlist_output' {
	
	quietly csdid2 `var_outcome' if ever_foreign_hire==1, ivar(frame_id_numeric) tvar(year) gvar(first_expat) long2

	display " "
	display " "	
	display "`var_outcome'"
	estat event, revent(-5/5)
	lincom Post_avg-Pre_avg
}


*Productivity
local varlist_prod "lnQL TFP_cd"
local varlist_treat "foreign foreign_hire expat"

foreach var_outcome in `varlist_prod' {
foreach var_treat in `varlist_treat' {
	
	quietly csdid2 `var_outcome', ivar(frame_id_numeric) tvar(year) gvar(first_`var_treat') long2
	display " "
	display " "	
	display "`var_outcome'"
	display "`var_treat'"
	estat event, revent(-5/5)
	lincom Post_avg-Pre_avg
	
}
}

foreach var_outcome in `varlist_prod' {
	
	quietly csdid2 `var_outcome' if ever_foreign_hire==1, ivar(frame_id_numeric) tvar(year) gvar(first_expat) long2

	display " "
	display " "	
	display "`var_outcome'"
	estat event, revent(-5/5)
	lincom Post_avg-Pre_avg
}
