local i = 1
foreach X of var $outcomes {
	foreach sample in $samples {
		di "`X': `sample'"
		xtreg `X' foreign during after during_expat after_expat i.ind_year i.age_cat if ${sample_`sample'} [aw=inverse_weight], i(firm_person ) fe vce(cluster id)
		* FIXME: use eststo and esttab here
		
		local fname = e(depvar)
		local title : variable label `fname'

		slopegraph, ///
			from(0 0 1 _b[during] 0 0 1 _b[during]+_b[during_expat]) ///
			to(1 _b[during] 2 _b[after] 1 _b[during]+_b[during_expat] 2 _b[after]+_b[after_expat]) ///
			style(p1 p1 p2 p2) ///
			label("Local-during" "Local-after" "Expat-during" "Expat-after" ) ///
			width_test(during after==during during_expat after_expat==during_expat) ///
			star_test(1==1 1==1 during_expat after_expat) ///
			connect(stepstair) ///
			format(scheme(538w) xlabel(none) xtitle("") ytitle("") title(`title') legend(off) aspect(.5) plotregion(style(none)) xsize(16) ysize(10))

		graph export output/figure/`sample'_`fname'_slope.png, width(1600) replace
	}
	local i = `i' + 1
}
