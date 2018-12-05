clear all
capture log close
* `1' sets which estimates to run: descriptive, manager_level, heterogeneity, event_study
confirm exist `1'

log using output/estimate_`1', text replace


use temp/analysis_sample

*Dinamika
scalar Tbefore = 4
scalar Tduring = 6
scalar Tafter = 4

gen byte analysis_window = (tenure>=-Tbefore-1)&(year-first_exit_year<=Tafter)

global sample_baseline (analysis_window==1)
global sample_manufacturing $sample_baseline & (manufacturing==1)
global sample_acquisitions $sample_baseline & (greenfield==0)
global sample_1990s $sample_acquisitions & (enter_year>=1994 & enter_year<=1999)
global sample_2000s $sample_acquisitions & (enter_year>=2000)
global sample_ever_foreign $sample_acquisitions & (ever_foreign==1)

global samples baseline acquisitions

global outcomes lnL lnKL lnQL exporter
label var lnL "Employment (log)"
label var lnKL "Capital per worker (log)"
label var lnQL "Revenue per worker (log)"
label var exporter "Firm is an exporter (dummy)"

egen person_tag = tag(frame_id manager_id)
egen N = sum(person_tag), by(frame_id)
gen inverse_weight = 1/N

* verify founders are not in analysis sample
foreach X of var during* after* {
	replace `X'=0 if founder==1
}

xtset firm_person year

do est_`1'

log close
