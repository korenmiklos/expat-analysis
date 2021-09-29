clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/event_studies", text replace

local pre 3
local post 8
local vars lnL lnQL lnK exporter

use "`here'/temp/analysis_sample.dta", clear
keep if ever_foreign

count

rename has_expat_ceo expat_hire
generate domestic_hire = foreign_hire & !expat_hire
generate no_hire = foreign & !foreign_hire


foreach treatment in no_hire domestic_hire expat_hire {
    attgt `vars', treatment(`treatment') aggregate(e) pre(`pre') post(`post') notyet limitcontrol(foreign == 0)
    count if e(sample) == 1
    do "`here'/code/util/event_study_plot.do"
    foreach outcome in `vars' {
        graph display `outcome'
        graph export "`here'/output/figure/event_study/`treatment'_`outcome'.png", replace
        graph drop `outcome'
    }
}

/*esttab m* using "`here'/output/.tex", mtitle b(3) se(3) replace
esttab m* using "`here'/output/table_attgt.txt", mtitle b(3) se(3) replace*/

log close
