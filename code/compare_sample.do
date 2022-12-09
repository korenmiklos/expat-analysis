use "temp/analysis_sample.dta"
keep frame_id_numeric year foreign has_expat_ceo
rename foreign new_foreign
rename has_expat_ceo new_expat

merge 1:1 frame_id_numeric year using "temp/analysis_sample-2022-05-05.dta", keepusing(foreign has_expat_ceo) nogen
rename foreign old_foreign
rename has_expat_ceo old_expat

compress
save "temp/compare_sample.dta", replace

foreach X of varlist _all {
	label variable `X' ""
}
tabulate old_foreign new_foreign, missing
tabulate old_expat new_expat, missing

