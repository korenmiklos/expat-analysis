foreach X of var exporter lnQL {
	local i = 1
	foreach Z of var H_* {
		xtreg `X' foreign during_domestic after_domestic during_expat after_expat during_domestic_`Z' after_domestic_`Z' during_expat_`Z' after_expat_`Z' i.ind_year i.age_cat if $sample_acquisitions [aw=inverse_weight], i(firm_person ) fe vce(cluster id)
		local r2_w = `e(r2_w)'
		test during_expat_`Z'==during_domestic_`Z'
		local p = `r(p)'	
		do regram output/regression/`X'_heterogeneity `i' `Z' R2_within "`r2_w'" p_value "`p'"
		local i = `i'+1
	}
}
