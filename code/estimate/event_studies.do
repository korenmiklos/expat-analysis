clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/event_studies", text replace

local pre 3
local post 8

use "`here'/temp/analysis_sample.dta", clear
keep if ever_foreign

rename ever_foreign ef
rename ever_foreign_hire efh
rename has_expat_ceo has_expat

count
count if ef & time_foreign <= 5

generate foreign_hire_only = foreign_hire & !has_expat

foreach var in foreign_hire_only has_expat {
    foreach y in lnQL lnK lnL exporter lnQ {
        * do loop bc event_study_plot cannot yet do multiple equations 
		attgt `y' if efh, treatment(`var') aggregate(e) pre(`pre') post(`post') notyet limitcontrol(foreign == 0)
		count if e(sample) == 1
		eststo mh`var', title("efh `var'")
        do "`here'/code/util/event_study_plot.do"
        graph export "`here'/output/figure/event_study/`var'_`y'.png", replace
    }
}

/*esttab m* using "`here'/output/.tex", mtitle b(3) se(3) replace
esttab m* using "`here'/output/table_attgt.txt", mtitle b(3) se(3) replace*/

log close
