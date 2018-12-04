local i = 1
foreach X of var $outcomes {
	xtreg `X' foreign during_?? after_?? i.ind_year i.age_cat if $sample_acquisitions [aw=inverse_weight], i(firm_person ) fe vce(cluster id)
	local r2_w = `e(r2_w)'
	do regram output/regression/acquisitions_change `i' `X' R2_within "`r2_w'"
	do tree_graph

	local i = `i' + 1
}
