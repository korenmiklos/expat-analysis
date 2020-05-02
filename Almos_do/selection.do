use "$datadir\analysis_sample_t.dta", clear

*Number of firms
codebook frame_id if ever_foreign & $sample_acquisition
codebook frame_id if $sample_acquisition & during_foreign
codebook frame_id if $sample_acquisition & during_expat

*Descriptives

sum 

forval i = 1/3 {
quietly estpost sum age emp lnQL if indic == `i' & $sample_acquisition
est store i`i'
}
esttab i1 i2 i3 using "$outputdir\selection\firm_level_desc.tex", ///
cell(mean(fmt(%9.2f)) sd(par fmt(%9.2f)) n) mtitle("Alw. DO" "FO not Expat" "FO & Expat") ///
label replace

*Selection of managers

eststo: reghdfe ever_foreign_hire lnK lnQL exporter_5 [aw = inverse_weight] if $sample_acquisition_1 & ever_foreign & !foreign, a(teaor08_2d year age) cluster(frame_id)
eststo: reghdfe ever_expat lnK lnQL exporter_5 [aw = inverse_weight] if $sample_acquisition_1 & ever_foreign_hire & !foreign, a(teaor08_2d year age) cluster(frame_id)

esttab using "$outputdir\effect\selection.tex", r2 star(* .1 ** .05 *** .01) se b(3) noconstant nonote alignment(D{.}{.}{-1}) label replace 
eststo clear
