*Matching
use "$datadir\analysis_sample.dta", clear
keep if firmyear_tag
egen fake_id = group(frame_id)
tsset fake_id year

gen byte treated = 1 if f.foreign == 1 & foreign == 0
recode treated (. = 0)

probit treated lnL lnQ l.lnL l.lnQ i.year i.teaor08_2d if treated | !ever_foreign
predict propscore 

keep if propscore < .
keep if treated | ever_foreign == 0

*Exact match
xtile quart_emp = emp, nq(4)

egen exactmatch = group(quart_emp teaor08_1d year)

*Match
gen treat_match = .
gen weight_match = .
levelsof exactmatch, local(gr)
foreach j of local gr  {
	psmatch2 treated if exactmatch == `j', kernel pscore(propscore) com cal(0.05)
	replace treat_match = _treated if treat_match == .
	replace weight_match = _weight if weight_match == .
}

*T tests 
foreach outcome of varlist log_emp log_sales emp_gr sales_gr log_tanass log_persexp {
	quietly sum `outcome' [aw = weight_match] if treat_match == 0
	gen m0 = r(mean)
	gen v0 = r(Var)
	quietly sum `outcome' [aw = weight_match] if treat_match == 1
	gen m1 = r(mean)
	gen v1 = r(Var)
	gen sdiff_`outcome' = (m1 - m0)/(v1 + v0)^0.5
	sum sdiff_`outcome'
	drop m0 m1 v0 v1
}

keep fake_id year treat_match weight_match
keep if weight_match < .
save "$datadir\pscore.dta", replace

*Create matching regression data

forval i = 1988/2015 {
	use "$datadir\pscore.dta", clear
	keep if year == `i'
	sort fake_id year
	quietly merge 1:m fake_id year using "$datadir\analysis_sample.dta"
	bysort fake_id: egen sample = max(_merge)
	keep if sample == 3
	gen treat_year = `i'
	save "$datadir\temp`i'.dta", replace
}


use "$datadir\temp1988.dta", clear
forval i = 1989/2015  {
	append using "$datadir\temp`i'.dta"
}

gen weight_matched = inverse_weight_1*weight_match
save "$datadir\merge_foreign.dta", replace
