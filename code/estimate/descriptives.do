*Tables and figures for expat study

global here "/srv/sandbox/expat/almos"

global sample_desc ever_foreign==0 | time_foreign==-1
*Descriptive statistics

*Industrial distribution
gen teaor_aggr=1 if teaor08_2d>=1 < teaor08_2d<10
replace teaor_aggr=2 if teaor08_2d>=10 & teaor08_2d<40
replace teaor_aggr=3 if teaor08_2d>=40 & teaor08_2d!=.

table teaor_aggr firm_type if $sample_desc, statistic(percent, across(teaor_aggr)) 

*Size distribution
tempvar empsize
gen `empsize'=.
replace  `empsize'=1 if emp<51
replace  `empsize'=2 if emp>50 & emp<101
replace  `empsize'=3 if emp>100 & emp<251
replace  `empsize'=4 if emp>250 & emp<.

label define empsize 1 "20-50" 2 "51-100" 3 "101-150" 4 "251-"
label value `empsize' empsize

table `empsize' firm_type if `sample_desc', statistic(percent, across(`empsize')) 

gen tanass_growth=(tanass_18-l2.tanass_18)/l2.tanass_18

sum tanass_growth if ever_foreign==0, d
sum tanass_growth if time_foreign==1 & firm_type==2, d
sum tanass_growth if time_foreign==1 & firm_type==3, d
sum tanass_growth if time_foreign==1 & firm_type==4, d


*Desciptives table
eststo clear
forval i = 1/4 {
quietly estpost sum emp_cl lnQ lnK TFP_cd exporter if firm_type == `i' & ($sample_desc )
est store i`i'
}
esttab i1 i2 i3 i4 using "$here/output/table/desc_firmvars.tex", main(mean) aux(sd) mtitle("Domestic" "Foreign" "Local CEO" "Expatriate") label pare replace

*Selection regressions
gen large_firm=(emp>100)
gen year_90s=(year<2000)


egen tanass_growth_long=max(tanass_growth), by(frame_id_numeric)
gen tanass_growth_10=(tanass_growth_long>.1) if tanass_growth!=.

eststo clear
quietly reg ever_foreign industrial_firm large_firm TFP_cd  tanass_growth_10 exporter year_90s if $sample_desc==1, cluster(frame_id_numeric)
sum ever_foreign if e(sample)
estadd scalar mean2 = r(mean)
est store est1

quietly reg ever_foreign_hire  industrial_firm large_firm TFP_cd exporter year_90s if ever_foreign==1 & $sample_desc==1, cluster(frame_id_numeric)
sum ever_foreign_hire if e(sample)
estadd scalar mean2 = r(mean)
est store est2

quietly reg ever_expat  industrial_firm large_firm TFP_cd exporter year_90s if ever_foreign_hire==1 & $sample_desc==1, cluster(frame_id_numeric)
sum ever_expat if e(sample)
estadd scalar mean2 = r(mean)
est store est3

esttab est1 est2 est3 using "$here/output/table/selection_reg.tex", star(* .1 ** .05 *** .01) b(3) scalar("mean2 Mean depvar" ) noconstant nonote se replace label r2

*Correlation between expat and acquisition type
local outcome_sel lnK lnIK lnL lnKL

eststo clear
foreach X of varlist `outcome_sel'  {
	eststo: attgt `X', treatment(foreign) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/sel_dinamic_fo.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_sel'  {
	eststo: attgt `X', treatment(foreign_hire) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/sel_dinamic_fohire.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_sel'  {
	eststo: attgt `X', treatment(has_expat_ceo) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}

esttab using "$here/output/table/sel_dinamic_expat.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

*Expat effect
local outcome_effect lnQ exporter lnExport lnQdomestic TFP_cd

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X', treatment(foreign) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_fo.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X', treatment(foreign_hire) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_fohire.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X', treatment(has_expat_ceo) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}

esttab using "$here/output/table/effect_expat.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

*Heterogeneity of the expat effect

*Privatization vs Private acquisition

local outcome_effect lnQ exporter lnExport lnQdomestic TFP_cd

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X' if ever_so==1, treatment(foreign) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_so_fo.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X' if ever_so==1, treatment(foreign_hire) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_so_fohire.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X' if ever_so==1, treatment(has_expat_ceo) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_so_expat.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X' if ever_so==0, treatment(foreign) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_po_fo.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X' if ever_so==0, treatment(foreign_hire) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_po_fohire.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X' if ever_so==0, treatment(has_expat_ceo) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_po_expat.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

*Pre-acquisition productivity

local outcome_effect lnQ exporter lnExport lnQdomestic TFP_cd

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X' if high_tfp==1, treatment(foreign) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_high_tfp_fo.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X' if high_tfp==1, treatment(foreign_hire) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_high_tfp_fohire.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X' if  high_tfp==1, treatment(has_expat_ceo) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_high_tfp==1_expat.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X' if high_tfp==0, treatment(foreign) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_low_tfp_fo.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X' if high_tfp==0, treatment(foreign_hire) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_low_tfp_fohire.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

eststo clear
foreach X of varlist `outcome_effect'  {
	eststo: attgt `X' if high_tfp==0, treatment(has_expat_ceo) aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
esttab using "$here/output/table/effect_low_tfp_expat.xlsx", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2

*Vertical vs. horizontal integration
