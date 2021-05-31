clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/analysis_sample", text replace

use "`here'/temp/balance-small-clean.dta"
drop foreign

sort frame_id_numeric year
gen x_before = year - year[_n-1] if frame_id_numeric == frame_id_numeric[_n-1]
gen hole10_before = (x_before > 10 & x_before != .)
gen hole2_before = (x_before > 2 & x_before != .)
gen hole1_before = (x_before > 1 & x_before != .)

foreach var of varlist hole* {
	tab `var'
}

drop x_before hole*

merge 1:1 frame_id year using "`here'/temp/firm_events.dta", keep(match) nogen
*merge 1:1 frame_id year using "`here'/temp/firm_events.dta", keep(1 3) //nogen
*merge 1:1 frame_id year using "`here'/temp/firm_events.dta"

sort frame_id_numeric year
gen x_after = year - year[_n-1] if frame_id_numeric == frame_id_numeric[_n-1]
gen hole10_after_m = (x_after > 10 & x_after != .)
gen hole2_after_m = (x_after > 2 & x_after != .)
gen hole1_after_m = (x_after > 1 & x_after != .)

foreach var of varlist hole* {
	tab `var'
}

*tab _merge

drop x_after hole*

preserve
use "`here'/temp/balance-small-clean.dta", clear
drop foreign
merge 1:1 frame_id year using "`here'/temp/firm_events.dta", keep(1 3)
sort frame_id_numeric year
gen x_after = year - year[_n-1] if frame_id_numeric == frame_id_numeric[_n-1]
gen hole10_after_mm = (x_after > 10 & x_after != .)
gen hole2_after_mm = (x_after > 2 & x_after != .)
gen hole1_after_mm = (x_after > 1 & x_after != .)

foreach var of varlist hole* {
	tab `var'
}
drop x_after hole*
restore

preserve
use "`here'/temp/balance-small-clean.dta", clear
merge 1:1 frame_id year using "`here'/temp/firm_events.dta", keep(2 3)
sort frame_id_numeric year
gen x_after = year - year[_n-1] if frame_id_numeric == frame_id_numeric[_n-1]
gen hole10_after_um = (x_after > 10 & x_after != .)
gen hole2_after_um = (x_after > 2 & x_after != .)
gen hole1_after_um = (x_after > 1 & x_after != .)

foreach var of varlist hole* {
	tab `var'
}
drop x_after hole*
restore

* not so elegant
merge m:1 frame_id_numeric year using "`here'/temp/ever_foreign.dta", keepusing(ever_foreign) keep(1 3) gen(filter)
drop ever_foreign

rename foreign_ceo foreign
rename ever_foreign_ceo ever_foreign
drop foreign_nceo ever_foreign_nceo

do "code/create/calc_hole.do"
tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole*, stat(sum) save
mat total = r(StatTotal)
tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole* if filter == 3, stat(sum) save
mat total = (total \ r(StatTotal))

*nceo overriden to have zeros
mvencode *_nceo, mv(0) override

* many foreign changes deleted
bys frame_id_numeric (year): gen owner_spell = sum(foreign != foreign[_n-1])
bys frame_id_numeric (year): egen owner_spell_total = total(foreign != foreign[_n-1])

drop if owner_spell_total > 3 // FIXME: doublecheck the length of spells
scalar dropped_too_many_foreign_change = r(N_drop)
display dropped_too_many_foreign_change

do "code/create/calc_hole.do"
tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole*, stat(sum) save
mat total = (total \ r(StatTotal))
tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole* if filter == 3, stat(sum) save
mat total = (total \ r(StatTotal))

* divestiture
bys frame_id_numeric (year): gen divest = sum(cond(owner_spell != owner_spell[_n-1] & foreign == 0 & _n != 1, 1, 0))
replace divest = 1 if divest > 0

* only keep D, D-F owner spells
bys frame_id_numeric: egen start_as_domestic = max((owner_spell == 1) & (foreign == 0))
*keep if start_as_domestic & owner_spell <= 2
keep if start_as_domestic
keep if owner_spell <= 2

do "code/create/calc_hole.do"
tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole*, stat(sum) save
mat total = (total \ r(StatTotal))
tabstat foreign foreign_3 foreign_2 foreign_1 foreign0 foreign1 foreign2 foreign3 count hole* if filter == 3, stat(sum) save
mat total = (total \ r(StatTotal))

mat list total

* check foreign end expat numbers
egen firm_tag = tag(frame_id_numeric)

count if ever_foreign
count if ever_foreign & firm_tag
count if ever_expat_ceo & firm_tag
count if ever_expat_nceo & firm_tag

count if has_expat_nceo == 1
count if has_expat_nceo == 1 & foreign == 0
count if has_expat_ceo == 1
count if has_expat_ceo == 1 & foreign == 0 // FIXME - should be 0
count if ever_expat_nceo == 1 & ever_foreign == 0
count if ever_expat_ceo == 1 & ever_foreign == 0

*do "`here'/code/create/event_dummies_firmlevel.do"

*merge 1:1 originalid year using "input/fo3-owner-names/country_codes.dta", keep(match master) nogen
* "same country" only applies to expats at foreign firms
*replace country_same = 0 if (has_expat == 0) | (foreign == 0)

egen industry_year = group(teaor08_1d year)
*egen last_before_acquisition = max(cond(time_foreign<0, time_foreign, .)), by(originalid)
*egen ever_same_country = max(country_same), by(originalid)

*do "`here'/code/create/countries.do"

*for descriptives (number of firms and firm-years in final data)
codebook frame_id_numeric
count if firm_tag
count

mata : mat_total_analysis = st_matrix("total")
mata: mata matsave "temp/matrix-analysis" mat_total_analysis, replace

drop first_year_foreign time_foreign foreign_* foreign? count x

bys frame_id_numeric: egen first_year_foreign_new = min(cond(foreign == 1, year,.))
generate time_foreign_new = year - first_year_foreign_new
gen foreign0_new = (time_foreign_new == 0)
count if foreign0_new == 1
drop *new

compress
save "`here'/temp/analysis_sample.dta", replace
log close

* frame_id_numeric codes for ever_foreign
preserve
keep if ever_foreign
duplicates drop frame_id_numeric year, force
save "`here'/temp/ever_foreign.dta", replace
restore

* create holes id list
preserve
keep if hole1 == 1 & ever_foreign == 1
keep originalid frame_id_numeric year
count
save "`here'/temp/holes_ever_foreign.dta", replace
set seed 123
sample 20, count
export delimited using "`here'/temp/holes_sample.csv", replace
restore

*for descriptives (number of ceo-s and nceo-s in final data, number of ceo and nceo job-spells in final data) - part III
*foreach type in ceo nceo {
*	use "`here'/temp/analysis_sample.dta", clear
*	merge 1:m frame_id_numeric year using "`here'/temp/raw_`type'.dta", nogen keep(match)
*	count
*	egen company_manager_id = group(frame_id_numeric manager_id)
*	codebook manager_id
*	codebook company_manager_id
*	save "`here'/temp/analysis_sample_manager_`type'.dta", replace
*}
