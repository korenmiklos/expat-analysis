global here "/srv/sandbox/expat/almos"



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


preserve
keep if ever_foreign_hire==1

eststo clear
foreach X of varlist $outcome  {
	eststo: attgt `X', treatment(has_expat_ceo) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}

esttab using "$here/2wfe_expat_fh.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

restore

eststo clear
foreach X of varlist $outcome  {
	eststo: quietly reghdfe `X' has_expat_ceo if ever_foreign_hire==1, a(frame_id_numeric teaor08_2d##year) cluster(frame_id_numeric)
}

esttab using "$here/output/check_12_2022/fe_fh.xlsx", star(* .1 ** .05 *** .01)  b(3) se keep(has_expat_ceo) noconstant label replace  nonote  r2

*Selection regressions
gen large_firm=(emp>100)

reghdfe ever_foreign lnQL exporter industrial_firm large_firm year_90s if time_foreign==-1 | ever_foreign==0, noabsorb

reghdfe ever_foreign_hire lnQL exporter industrial_firm large_firm year_90s if time_foreign==-1 & ever_foreign==1, noabsorb

reghdfe ever_expat lnQL exporter industrial_firm large_firm year_90s if time_foreign==-1 & ever_foreign_hire==1, noabsorb

*Two state FE
preserve 
keep if ever_foreign==1
xtset frame_id_numeric year

foreach var in TFP_cd {
quietly xtreg `var' if foreign==0 & ever_foreign==1, fe
predict fe, u
egen `var'_fe=max(fe), by(frame_id_numeric)
drop fe
}

reghdfe TFP_cd_fe foreign foreign_hire has_expat_ceo, a(year) cluster(frame_id_numeric)

restore

*SO vs PO
egen ever_so=max(so2_with_mo2), by(frame_id_numeric)

reghdfe TFP_cd foreign foreign_hire has_expat_ceo if ever_so==1, a(frame_id_numeric teaor08_2d##year) cluster(frame_id_numeric)
reghdfe TFP_cd foreign foreign_hire has_expat_ceo if ever_so==0, a(frame_id_numeric teaor08_2d##year) cluster(frame_id_numeric)

eststo clear
foreach X of varlist $outcome  {
	eststo: attgt `X' if ever_so==0, treatment(foreign) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}

foreach X of varlist $outcome  {
	eststo: attgt `X' if ever_so==0, treatment(foreign_hire) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}

foreach X of varlist $outcome  {
	eststo: attgt `X' if ever_so==0, treatment(has_expat_ceo) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}

esttab using "$here/output/check_12_2022/wfe_po.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

*Csdid2
gen x=year if time_foreign==0 & ever_expat==1
egen first_expat=max(x), by(frame_id_numeric)
recode first_expat (.=0)

csdid2 TFP_cd,  ivar(frame_id_numeric) tvar(year) gvar(first_expat)
estat event
estat event, wboot plot
estat event, wboot revent(-5/5)

csdid2 lnQL,  ivar(frame_id_numeric) tvar(year) gvar(first_expat)
estat event

*estimate post-predict

ssc install frause

csdid2 TFP_cd, ivar(frame_id_numeric) tvar(year) gvar(first_expat) long
estat event, revent(-5/5)
lincom Post_avg-Pre_avg



