global here "/srv/sandbox/expat/almos"
use "/srv/sandbox/expat/miklos/temp/analysis_sample.dta", clear


*Figures, full sample

eststo clear
foreach Y in $varlist_rhs {
	
	eststo: xt2treatments `Y', treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(-1) weighting(optimal)

	e2frame, generate(expat_fig)

	frame expat_fig: graph twoway (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) ///
	(connected coef xvar, lcolor(cranberry)), ///
	graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xscale(range (-4 4)) xtitle("Event time") yline(0)

	gr export "$here/output/twfe/expat_`Y'.pdf", replace

}

esttab using "$here/output/table/dynamics_coeff.tex", b(3) se  style(tex) replace nolegend label nonote

*Figures, tradable/nontradable

forval s=0/1 {
	eststo clear
	foreach Y in $varlist_rhs {

	eststo: xt2treatments `Y' if tradable_sector==`s', treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(-1) weighting(optimal)

	e2frame, generate(expat_fig)

	frame expat_fig: graph twoway (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) ///
	(connected coef xvar, lcolor(cranberry)), ///
	graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xscale(range (-4 4)) xtitle("Event time") yline(0)
	
	gr export "$here/output/twfe/expat_tradable`s'_`Y'.pdf", replace


	}
}

*Figures, export, export entry lnQd

xt2treatments exporter, treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(-1) weighting(optimal) 

e2frame, generate(expat_fig)

frame expat_fig: graph twoway (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) ///
(connected coef xvar, lcolor(cranberry)), ///
graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xscale(range (-4 4)) xtitle("Event time") yline(0)

gr export "$here/output/twfe/expat_exporter.pdf", replace


xt2treatments exporter if exporter_pre==0, treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(-1) weighting(optimal)
e2frame, generate(expat_fig)

frame expat_fig: graph twoway (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) ///
(connected coef xvar, lcolor(cranberry)), ///
graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xscale(range (-4 4)) xtitle("Event time") yline(0)

gr export "$here/output/twfe/expat_export_entry.pdf", replace


xt2treatments lnQd if lnQd_exist_post==1, treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) baseline(-1) weighting(optimal)

e2frame, generate(expat_fig)

frame expat_fig: graph twoway (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) ///
(connected coef xvar, lcolor(cranberry)), ///
graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xscale(range (-4 4)) xtitle("Event time") yline(0)

gr export "$here/output/twfe/expat_lnQd.pdf", replace

forval i=0/1 {
	
	xt2treatments exporter if tradable_sector==`i', treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) ///
	baseline(-1) weighting(optimal)

	e2frame, generate(expat_fig)

	frame expat_fig: graph twoway (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) ///
	(connected coef xvar, lcolor(cranberry)), ///
	graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xscale(range (-4 4)) xtitle("Event time") yline(0)
	
	gr export "$here/output/twfe/expat_tradable`i'_exporter.pdf", replace

	xt2treatments exporter if exporter_pre==0 & tradable_sector==`i', treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) ///
	baseline(-1) weighting(optimal) graph

	e2frame, generate(expat_fig)

	frame expat_fig: graph twoway (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) ///
	(connected coef xvar, lcolor(cranberry)), ///
	graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xscale(range (-4 4)) xtitle("Event time") yline(0)
	
	gr export "$here/output/twfe/expat_tradable`i'_export_entry.pdf", replace

	xt2treatments lnQd if lnQd_exist_post==1 & tradable_sector==`i', treatment(has_expat_ceo) control(local_ceo) pre(4) post(4) ///
	baseline(-1) weighting(optimal) graph
	
	e2frame, generate(expat_fig)

	frame expat_fig: graph twoway (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) ///
	(connected coef xvar, lcolor(cranberry)), ///
	graphregion(color(white)) xlabel(-4(1)4) legend(off) xline(-0.5) xscale(range (-4 4)) xtitle("Event time") yline(0)
	
	gr export "$here/output/twfe/expat_tradable`i'_lnQd.pdf", replace

}


