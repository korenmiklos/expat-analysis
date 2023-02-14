***Descriptive stats and selection regressions

global here "/srv/sandbox/expat/almos"

gen status=1 if ever_foreign==0
replace status=2 if ever_foreign==1 & ever_foreign_hire==0
replace status=3 if ever_foreign_hire==1 & ever_expat==0
replace status=4 if ever_expat==1

label variable lnL "Employment (log)"
label variable lnKL "Capital per worker (log)"
label variable lnMQ "Material share (log)"
label variable exporter "Exporter (dummy)"
label variable TFP_cd "TFP (log)"

*Desc stats
eststo clear
forval i = 1/4 {
estpost sum industrial emp_cl lnK lnIK lnQ exporter TFP_cd if status==`i' & (time_foreign<0 | time_foreign==.)
est store t`i'
}
esttab t1 t2 t3 t4 using "$here/output/table/descriptive.tex", main(mean) aux(sd) mtitle("Domestic" "No CEO Change" "CEO Change" "CEO Expatriate") label pare replace

*Selection regressions
gen large_firm=(emp>100)
gen year_90s=(year<2000)

local controls industrial_firm large_firm lnQL lnKL lnIK exporter year_90s

eststo clear
eststo clear
quietly reg ever_foreign `controls' if time_foreign<0 | ever_foreign==0
est store t1

quietly reg ever_foreign_hire `controls' if time_foreign<0 & ever_foreign==1
est store t2

quietly reg ever_expat `controls' if time_foreign<0 & ever_foreign_hire==1
est store t3

esttab t1 t2 t3 using "$here/output/table/selection.tex", star(* .1 ** .05 *** .01)  b(3) se noconstant label replace  nonote  r2


