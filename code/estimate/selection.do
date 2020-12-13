here
local here = r(here)

use "`here'/temp/analysis_sample.dta", clear

local explanatory lnL exporter TFP_cd RperK ??
local dummies teaor08_2d industry_year
local options keep(lnL exporter TFP_cd RperK)

* selection into foreign acquisition
reghdfe ever_foreign `explanatory' if !foreign & owner_spell == 1, a(`dummies') cluster(originalid)
outreg2 using "`here'/output/table/selection.tex", replace `options'

* selection into manager hire
reghdfe ever_foreign_hire `explanatory' if ever_foreign & time_foreign == last_before_acquisition, a(`dummies') cluster(originalid)
outreg2 using "`here'/output/table/selection.tex", append `options'

* selection into expat hire
reghdfe ever_expat `explanatory' if ever_foreign & ever_foreign_hire & time_foreign == last_before_acquisition, a(`dummies') cluster(originalid)
outreg2 using "`here'/output/table/selection.tex", append `options'

generate degree_control = ever_foreign + ever_foreign_hire + ever_expat 
label define dc 0 "Domestic" 1 "Foreign owner" 2 "Foreign hire" 3 "Expat hire"
label value degree_control dc

tabulate degree_control
oprobit degree_control `explanatory' i.teaor08_2d i.industry_year if !foreign & owner_spell == 1, vce(cluster originalid)
outreg2 using "`here'/output/table/selection.tex", append `options'
