use "temp/analysis_sample.dta", clear
which xt2treatments
which e2frame
which reghdfe
which estout

global varlist_rhs "lnK lnL TFP lnQ export_share"
local graph_command graph twoway (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef xvar, lcolor(cranberry)), graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xscale(range (-4 4)) xtitle("Time since foreign acquisution (year)") yline(0)
local xt2treatments_options treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(-1) weighting(optimal)
local esttab_options b(3) se style(tex) replace nolegend label nonote
local folder output/figure

*Figures, full sample

eststo clear
foreach Y in $varlist_rhs {
	eststo: xt2treatments `Y', `xt2treatments_options'
	e2frame, generate(expat_fig)
	frame expat_fig: `graph_command'
	graph export "`folder'/expat_`Y'.pdf", replace
}

esttab using "output/table/dynamics_coeff.tex", `esttab_options'

*Figures, tradable/nontradable

forvalues s = 0/1 {
	eststo clear
	foreach Y in $varlist_rhs {
		eststo: xt2treatments `Y' if tradable_sector==`s', `xt2treatments_options'
		e2frame, generate(expat_fig)
		frame expat_fig: `graph_command'
		graph export "`folder'/expat_tradable`s'_`Y'.pdf", replace
	}
}

*Figures, export, export entry lnQd

xt2treatments exporter, `xt2treatments_options'
e2frame, generate(expat_fig)
frame expat_fig: `graph_command'
graph export "`folder'/expat_exporter.pdf", replace

xt2treatments exporter if exporter_pre==0, `xt2treatments_options'
e2frame, generate(expat_fig)
frame expat_fig: `graph_command'
graph export "`folder'/expat_export_entry.pdf", replace

xt2treatments lnQd if lnQd_exist_post==1, `xt2treatments_options'
e2frame, generate(expat_fig)
frame expat_fig: `graph_command'
graph export "`folder'/expat_lnQd.pdf", replace

forvalues i = 0/1 {
	xt2treatments exporter if tradable_sector==`i', `xt2treatments_options'
	e2frame, generate(expat_fig)
	frame expat_fig: `graph_command'
	graph export "`folder'/expat_tradable`i'_exporter.pdf", replace

	xt2treatments exporter if exporter_pre==0 & tradable_sector==`i', `xt2treatments_options'
	e2frame, generate(expat_fig)
	frame expat_fig: `graph_command'
	graph export "`folder'/expat_tradable`i'_export_entry.pdf", replace

	xt2treatments lnQd if lnQd_exist_post==1 & tradable_sector==`i', `xt2treatments_options'
	e2frame, generate(expat_fig)
	frame expat_fig: `graph_command'
	graph export "`folder'/expat_tradable`i'_lnQd.pdf", replace
}
