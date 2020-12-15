here
local here = r(here)

use "`here'/temp/analysis_sample.dta", clear

local explanatory lnL exporter TFP_cd RperK ??
local dummies teaor08_2d##year
local options keep(lnL exporter TFP_cd RperK) tex(frag) dec(3)
local sample1 !foreign & owner_spell == 1

* selection into foreign acquisition
reghdfe ever_foreign `explanatory' if `sample1', a(`dummies') cluster(originalid)
outreg2 using "`here'/output/table/selection.tex", replace `options'

* selection into manager hire
reghdfe ever_foreign_hire `explanatory' if ever_foreign & `sample1', a(`dummies') cluster(originalid)
outreg2 using "`here'/output/table/selection.tex", append `options'

* selection into expat hire
reghdfe ever_expat `explanatory' if ever_foreign & ever_foreign_hire & `sample1', a(`dummies') cluster(originalid)
outreg2 using "`here'/output/table/selection.tex", append `options'

generate degree_control = ever_foreign + ever_foreign_hire + ever_expat 
label define dc 0 "Domestic" 1 "Foreign owner" 2 "Foreign hire" 3 "Expat hire"
label value degree_control dc

tabulate degree_control
*oprobit degree_control `explanatory'  i.teaor08_2d#year if `sample1', vce(cluster originalid)
*outreg2 using "`here'/output/table/selection.tex", append `options'
