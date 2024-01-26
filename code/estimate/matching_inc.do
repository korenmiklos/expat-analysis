global here "/srv/sandbox/expat/almos"

use "$here/temp/analysis_sample.dta", clear

gen foreign_hire_inc=(foreign==1 & foreign_hire==0)
egen ever_foreign_hire_inc=max(foreign_hire_inc), by(frame_id_numeric)

keep if ever_foreign_hire_inc==1 | ever_foreign==0

save "$here/temp/match_temp.dta", replace

*Matching

*Propensity score
gen treat_1=(time_foreign==-1 & ever_foreign==1 & ever_foreign_hire==0)
recode treat_1 (0=.) if ever_foreign==1

*Variables for probit
gen growth=lnK-l2.lnK

	foreach X in lnL lnQ growth lnQL {
	xtile `X'_cub=`X', nq(3)
}

xtile lnEx_cub=lnEx if exporter>0, nq(3)
recode lnEx_cub (.=0)

*probit treat_1 i.lnL_cub i.lnQ_cub i.growth_cub i.lnQL_cub exporter i.lnEx_cub i.year i.teaor08_2d
probit treat_1 i.lnL_cub i.lnQ_cub i.lnQL_cub exporter i.lnEx_cub i.year i.teaor08_2d
predict x if e(sample)
quietly sum x
scalar max=r(max)
gen propscore=x/max
quietly sum propscore if treat_1==1
scalar pmin=r(min)
drop if propscore<pmin
keep if propscore<.

*Potential matches
tempvar control
gen `control'=(propscore<. & l.propscore<. & f.propscore<.)
gen match_potential=(treat_1==1 | `control'==1)
keep if propscore < . & match_potential == 1

*Exact match
xtile emp_match = avg_emp, nq(2)
xtile growth_match=growth, nq(2)
gen teaor_1d=int(teaor08_2d/10)
gen teaor_aggr=0
replace teaor_aggr=1 if teaor08_2d>=5 & teaor08_2d<45

egen exactmatch=group(year teaor_aggr growth_match)

*Match
gen treat_match = .
gen weight_match = .
levelsof exactmatch, local(gr)
foreach j of local gr  {
	psmatch2 treat_1 if exactmatch == `j', n(2) pscore(propscore) com 
	*cal(0.1)
	replace treat_match = _treated if exactmatch==`j'
	replace weight_match = _weight if exactmatch==`j'
}

keep frame_id_numeric year treat_match weight_match
keep if weight_match < .
sort frame_id_numeric year
save "$here/temp/pscore.dta", replace

*Merge weights to original data
use "$here/temp/match_temp.dta", clear
sort frame_id_numeric year
merge 1:1 frame_id_numeric year using "$here/temp/pscore.dta"

egen weight=sum(weight_match), by(frame_id_numeric)
replace weight=. if weight<0.01
keep if weight<.


*Common trends
sort frame_id_numeric year
tempvar zero zero_ext
gen `zero'=year if l.treat_match==1 | l.treat_match==0
egen `zero_ext'=max(`zero'), by(frame_id_numeric)
gen trend=year-`zero_ext'

keep if trend>=-4 & trend<=4
gen trend_plus=trend+4

save "$here/temp/analysis_sample_match_inc", replace


