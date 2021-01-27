clear all
use "input/ceo-panel/ceo-panel.dta"

collapse (count) N = position, by(frame_id year imputed first_year_of_firm last_year_of_firm)
reshape wide N, i(frame_id year) j(imputed)
mvencode N?, mv(0)

generate byte imputed = (N0 == 0) & (N1 > 0)

* take random sample of imputed firm-years
* those with longer imputed spells have higher chance to get in the sample
keep if imputed
set seed 8954
sample 100, count

keep frame_id
duplicates drop

generate u = uniform()
sort u
drop u

export delimited "temp/imputed-sample.csv", replace
