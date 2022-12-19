



foreach var in foreign foreign_hire expat {
	
	forval i=1/5 {
	gen `var'_b`i'=(ever_`var'==1 & time_foreign==-`i')
	}
	
	forval i=0/5 {
	gen `var'_a`i'=(ever_`var'==1 & time_foreign==`i')
	}

order `var'_b5 `var'_b4 `var'_b3 `var'_b2 `var'_b1 `var'_a0 `var'_a1 `var'_a2 `var'_a3 `var'_a4 `var'_a5

recode `var'_b* `var'_a* (.=0) if ever_foreign==0
}

foreach var in foreign foreign_hire expat_hire {
	
	attgt TFP_cd, treatment(`var') aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}


*Test regressions
global outcome lnQ lnQL TFP_cd exporter lnK lnL lnM
global here "/srv/sandbox/expat/almos"


eststo clear
foreach X of varlist $outcome  {
	eststo: quietly reghdfe `X' foreign foreign_hire has_expat_ceo, a(frame_id_numeric teaor08_2d##year) cluster(frame_id_numeric)
}

esttab using "$here/fe.xlsx", star(* .1 ** .05 *** .01)  b(3) se keep(foreign foreign_hire has_expat_ceo) noconstant label replace  nonote  r2


eststo clear
foreach X of varlist $outcome  {
	eststo: attgt `X', treatment(has_expat_ceo) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}

esttab using "$here/2wfe_expat.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2


eststo clear
foreach X of varlist $outcome  {
	eststo: attgt `X', treatment(has_expat_ceo) aggregate(prepost) pre(5) post(5) notyet limitcontrol(foreign==0)
}

esttab using "$here/2wfe_expat_prepost.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2


eststo clear
foreach X of varlist $outcome  {
	eststo: attgt `X', treatment(foreign_hire) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}

esttab using "$here/output/check_12_2022/wfe_foreign_hire.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist $outcome  {
	eststo: attgt `X', treatment(foreign) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}

esttab using "$here/2wfe_foreign.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

*Event time

eststo clear
foreach X of varlist $outcome  {
	eststo: attgt `X', treatment(foreign) aggregate(e) pre(5) post(5) notyet limitcontrol(foreign==0)
}

esttab using "$here/output/check_12_2022/2wfe_foreign_e.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist $outcome  {
	eststo: attgt `X', treatment(foreign_hire) aggregate(e) pre(5) post(5) notyet limitcontrol(foreign==0)
}

esttab using "$here/output/check_12_2022/2wfe_foreign_hire_e.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist $outcome  {
	eststo: attgt `X', treatment(has_expat_ceo) aggregate(e) pre(5) post(5) notyet limitcontrol(foreign==0)
}

esttab using "$here/output/check_12_2022/2wfe_expat_e.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

*Weighting
probit ever_expat i.teaor08_2d i.year if time_foreign<0 | ever_foreign==0 
*r2=0.83
probit ever_expat lnQ i.teaor08_2d i.year if time_foreign<0 | ever_foreign==0 
*r2=0.99
probit ever_expat lnQ lnL lnK i.teaor08_2d i.year if time_foreign<0 | ever_foreign==0 
*r2=0.105
probit ever_expat lnQ lnL lnK lnM TFP_cd i.teaor08_2d i.year if time_foreign<0 | ever_foreign==0 
*r2=0.111

foreach X in lnQ lnL lnK lnM TFP_cd {
	gen `X'2=`X'^2
}

probit ever_expat lnQ lnL lnK lnM TFP_cd exporter lnQ2 lnL2 lnK2 lnM2 TFP_cd2 i.teaor08_2d i.year if time_foreign<0 | ever_foreign==0 
*r2=0.123

probit ever_expat lnQ lnL lnK lnM TFP_cd exporter young medium lnQ2 lnL2 lnK2 lnM2 TFP_cd2 i.teaor08_2d i.year if time_foreign<0 | ever_foreign==0 
*r2=0.134, young=0-5years, medium=6-10years

gen so=(so2_with_mo2==1 | so3==1)
probit ever_expat lnQ lnL lnK lnM TFP_cd exporter young medium so lnQ2 lnL2 lnK2 lnM2 TFP_cd2 i.teaor08_2d i.year if time_foreign<0 | ever_foreign==0 
*r2=0.135

qui tab year, gen(year_d)
qui tab teaor08_2d, gen(ind_d)

eststo clear
foreach X of varlist $outcome  {
	eststo: attgt `X', treatment(foreign) aggregate(e) pre(5) post(5) notyet limitcontrol(foreign==0) ipw(lnQ lnL lnK lnM TFP_cd exporter young medium so lnQ2 lnL2 lnK2 lnM2 TFP_cd2 ind_d* year_d*)
}

esttab using "$here/output/check_12_2022/2wfe_foreign_e_w.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist $outcome  {
	eststo: attgt `X', treatment(foreign_hire) aggregate(e) pre(5) post(5) notyet limitcontrol(foreign==0) ipw(lnQ lnL lnK lnM TFP_cd exporter young medium so lnQ2 lnL2 lnK2 lnM2 TFP_cd2 ind_d* year_d*)
}

esttab using "$here/output/check_12_2022/2wfe_foreign_hire_e_w.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist $outcome  {
	eststo: attgt `X', treatment(has_expat_ceo) aggregate(e) pre(5) post(5) notyet limitcontrol(foreign==0) ipw(lnQ lnL lnK lnM TFP_cd exporter young medium so lnQ2 lnL2 lnK2 lnM2 TFP_cd2 ind_d* year_d*)
}

esttab using "$here/output/check_12_2022/2wfe_expat_e_w.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2
