local i = 1
foreach X of var $outcomes {
	foreach sample in $samples {
		* simple, descriptive regressions first, including founders, but not before/after years
		reg `X' foreign expat i.ind_year i.age_cat if ${sample_`sample'} & year>=enter_year & year<=first_exit_year [aw=inverse_weight], vce(cluster id)
		do regram output/regression/`sample'_OLS `i' `X'

		xtreg `X' foreign expat i.ind_year i.age_cat if ${sample_`sample'} & year>=enter_year & year<=first_exit_year [aw=inverse_weight], i(id) fe vce(cluster id)
		local r2_w = `e(r2_w)'
		do regram output/regression/`sample'_FE `i' `X' R2_within "`r2_w'"
	}
	local i = `i' + 1
}
