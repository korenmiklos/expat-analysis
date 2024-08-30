use "temp/analysis_sample.dta", clear
which xt2treatments
which e2frame
which reghdfe
which estout

global varlist_rhs "TFP lnQd lnK lnL lnQ export_share "
local lnQd_condition "lnQd_exist_post=="
local graph_command graph twoway (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef xvar, lcolor(cranberry)), graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xscale(range (-4 4)) xtitle("Time since CEO hire (year)") yline(0)
local xt2treatments_options treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(-1) weighting(optimal)
local esttab_options b(3) se style(tex) replace nolegend label nonote
local folder output/figure

*Figures, full sample

eststo clear
foreach Y in $varlist_rhs {
	eststo: xt2treatments `Y' if ``Y'_condition' 1, `xt2treatments_options'
	e2frame, generate(expat_fig)
	frame expat_fig: `graph_command'
	graph export "`folder'/expat_`Y'.pdf", replace
}

esttab using "output/table/dynamics_coeff.tex", `esttab_options'

*Figures, tradable/nontradable

forvalues s = 0/1 {
	eststo clear
	foreach Y in $varlist_rhs {
		eststo: xt2treatments `Y' if ``Y'_condition' 1 & tradable_sector==`s', `xt2treatments_options'
		e2frame, generate(expat_fig)
		frame expat_fig: `graph_command'
		graph export "`folder'/expat_tradable`s'_`Y'.pdf", replace
	}
}
