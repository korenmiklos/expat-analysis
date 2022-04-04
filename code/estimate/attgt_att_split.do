clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/attgt_att_split", text replace

local pre 2
local post 5
local vars lnL lnQL lnK exporter RperK TFP_cd
local controls lnQ lnK lnL lnM exporter

use "`here'/temp/analysis_sample.dta", clear
keep if ever_foreign

count

rename has_expat_ceo expat_hire
generate local_hire = foreign_hire & !expat_hire
generate no_hire = foreign & !foreign_hire

foreach treatment in no_hire local_hire expat_hire {
    attgt `vars' if year <= 2003, treatment(`treatment') aggregate(att) pre(`pre') post(`post') notyet limitcontrol(foreign == 0) //ipw(`controls')
    count if e(sample) == 1
    eststo m`var', title("before 2004 `var'")
}

foreach treatment in no_hire local_hire expat_hire {
    attgt `vars' if year >= 2004, treatment(`treatment') aggregate(att) pre(`pre') post(`post') notyet limitcontrol(foreign == 0) //ipw(`controls')
    count if e(sample) == 1
    eststo m`var', title("after 2003 `var'")
}

esttab m* using "`here'/output/table_attgt_att_split.tex", mtitle b(3) se(3) replace
esttab m* using "`here'/output/table_attgt_att_split.txt", mtitle b(3) se(3) replace

log close
