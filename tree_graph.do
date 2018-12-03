local fname = e(depvar)
local title : variable label `fname'

slopegraph, ///
	from(0 0 0 0 1 _b[during_DE] 1 _b[during_DE]) ///
	to(1 _b[during_DD] 1 _b[during_DE] 2 _b[during_ED]+_b[during_DE] 2 _b[during_EE]+_b[during_DE]) ///
	style(p1 p2 p1 p2) ///
	label(Local-Local Local-Expat Expat-Local Expat-Expat) ///
	width_test(during_DD during_DE during_ED during_EE) ///
	star_test(1==1 during_DE==during_DD 1==1 during_EE==during_ED) ///
	connect(stepstair) ///
	format(scheme(538w) xlabel(none) xtitle("") ytitle(`title') legend(off) aspect(0.67))

graph export output/figure/`fname'_tree.png, width(800) replace
