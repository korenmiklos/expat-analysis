*Tables and figures for expat study


label var industrial_pre "Industrial Firm"
label var emp "Employment"
label var TFP "TFP"
label var exporter "Exporter"


global here "/srv/sandbox/expat/almos"

*Descriptive statistics

*Desciptives table
eststo clear

quietly estpost sum industrial_pre emp lnK lnQ lnKL TFP exporter if ever_local==1 & (time_foreign==-1 | time_foreign==-2 | time_foreign==-3)
est store local

quietly estpost sum industrial_pre emp lnK lnQ lnKL TFP exporter if ever_expat==1 & (time_foreign==-1 | time_foreign==-2 | time_foreign==-3)
est store expat

esttab local expat using "$here/output/table/desc_firmvars.tex", main(mean) aux(sd) mtitle("Local CEO" "Expatriate CEO") label pare replace

*Selection regression

reghdfe ever_expat lnL lnKL TFP exporter if time_foreign==-1 | time_foreign==-2 | time_foreign==-3, absorb(year##teaor08_2d) cluster(frame_id_numeric)
sum ever_expat if e(sample)
estadd scalar mean2 = r(mean)
est store est1

esttab est1  using "$here/output/table/selection_reg.tex", star(* .1 ** .05 *** .01) b(3) scalar("mean2 Mean depvar" ) noconstant nonote se replace label r2



