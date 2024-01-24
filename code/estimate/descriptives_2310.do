*Tables and figures for expat study

global here "/srv/sandbox/expat/almos"
use "$here/temp/analysis_sample.dta", clear

keep if ever_foreign_hire==1

drop if time_foreign<-4
drop if time_foreign>4 & time_foreign!=.

gen foreign_hire_local=(foreign_hire==1 & has_expat_ceo==0)
egen ever_foreign_hire_local=max(foreign_hire_local), by(frame_id_numeric)

*Descriptive statistics
gen firm_type_expat=(ever_expat==1)
gen emp_100=(emp_cl>=100)
gen tanass_growth=(tanass_18-l2.tanass_18)/l2.tanass_18
gen tanass_growth_10=(tanass_growth>.1) if !missing(tanass_growth)
gen tanass_growth_pos=(tanass_growth>0) if !missing(tanass_growth)

label var emp_100 "Employment over 100"
label var ever_expat "Expatriate"
label var tanass_growth_10 "Asset Growth over 10\%"
label var emp_cl "Employment"
label var TFP_cd "TFP"
label var exporter "Exporter"
label var industrial_firm "Industrial"

*Desciptives table
eststo clear
forval i = 0/1 {
quietly estpost sum industrial_firm emp_cl lnK lnQ lnKL TFP_cd exporter if firm_type_expat == `i' & time_foreign==-1
est store i`i'
}
esttab i0 i1 using "$here/output/table/desc_firmvars_expat.tex", main(mean) aux(sd) mtitle("Local CEO" "Expatriate CEO") label par replace nonum

*Selection regressions
reghdfe ever_expat  industrial lnQ lnKL TFP_cd exporter if time_foreign==-1, absorb(year) cluster(frame_id_numeric)
sum ever_expat if e(sample)
estadd scalar mean2 = r(mean)
est store est1


reghdfe ever_expat  lnQ lnKL TFP_cd exporter if time_foreign==-1, absorb(year teaor08_2d) cluster(frame_id_numeric)
sum ever_expat if e(sample)
estadd scalar mean2 = r(mean)
est store est1

esttab est1 using "$here/output/table/selection_reg_expat.tex", star(* .1 ** .05 *** .01) b(3) scalar("mean2 Mean Expatriate" ) noconstant nonote se replace label ar2

