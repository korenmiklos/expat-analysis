clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/attgt_att_gt", text replace

local pre 5
local post 5
local vars lnL lnQL lnK exporter RperK TFP_cd
local controls lnQ lnK lnL lnM exporter

use "`here'/temp/analysis_sample.dta", clear
keep if ever_foreign

count

rename has_expat_ceo expat_hire
generate local_hire = foreign_hire & !expat_hire
generate no_hire = foreign & !foreign_hire

*foreach treatment in no_hire local_hire expat_hire {
*    attgt `vars', treatment(`treatment') aggregate(gt) pre(`pre') post(`post') notyet limitcontrol(foreign == 0)
*}

attgt `vars', treatment(expat_hire) aggregate(gt) pre(`pre') post(`post') notyet limitcontrol(foreign == 0)


log close
