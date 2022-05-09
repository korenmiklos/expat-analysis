here
local here = r(here)

use "`here'/temp/analysis_sample.dta", clear
keep if survival

rename has_expat_ceo expat_hire
generate local_hire = foreign_hire & !expat_hire
generate no_hire = foreign & !foreign_hire

xtset frame_id_numeric year
generate control = F.no_hire + 2*F.local_hire + 3*F.expat_hire

label define ctrl 1 "No hire" 2 "Local hire" 3 "Expat hire"
label values control ctrl

tabulate control, missing

local explanatory lnL lnKL lnMQ exporter TFP_cd
local dummies i.teaor08_2d i.year
local options keep(lnL lnKL lnMQ exporter TFP_cd) tex(frag) dec(3) nocons nonotes label
local sample1 time_foreign == -1

label variable lnL "Employment (log)"
label variable lnKL "Capital per worker (log)"
label variable lnMQ "Material share (log)"
label variable exporter "Exporter (dummy)"
label variable TFP_cd "TFP (log)"

mlogit control `explanatory' `dummies' if `sample1', baseoutcome(1) robust
outreg2 using "`here'/output/table/selection.tex", replace `options'

ologit control `explanatory' `dummies' if `sample1', robust
outreg2 using "`here'/output/table/selection.tex", append `options' ctitle(Ordered logit)
