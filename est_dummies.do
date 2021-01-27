here
local here = r(here)

use "`here'/temp/analysis_sample.dta", replace

*Regressions to try out the dummies (can be deleted later)

reghdfe lnQL foreign foreign_hire has_expat, a(frame_id_numeric year##teaor08_2d) cluster(frame_id_numeric)
outreg2 using "`here'/output/table/dummies.tex", replace `options'

reghdfe lnQL foreign foreign_hire_local_* foreign_hire_expat_*, a(frame_id_numeric year##teaor08_2d) cluster(frame_id_numeric)
outreg2 using "`here'/output/table/dummies.tex", append `options'

*reghdfe lnQL foreign foreign_hire_local_1 foreign_hire_expat_1 foreign_hire_local_2 foreign_hire_expat_2 foreign_hire_local_3 foreign_hire_expat_3 foreign_hire_local_4plus foreign_hire_expat_4plus, a(frame_id_numeric year##teaor08_2d) cluster(frame_id_numeric)

reghdfe lnQL foreign foreign_hire_local_1 foreign_hire_expat_1 foreign_hire_local_2 foreign_hire_expat_2 foreign_hire_local_3plus foreign_hire_expat_3plus, a(frame_id_numeric year##teaor08_2d) cluster(frame_id_numeric)
outreg2 using "`here'/output/table/dummies.tex", append `options'

reghdfe lnQL foreign foreign_hire_local_1 foreign_hire_expat_1 foreign_hire_LL_2 foreign_hire_EL_2 foreign_hire_LE_2 foreign_hire_EE_2 foreign_hire_local_3plus foreign_hire_expat_3plus, a(frame_id_numeric year##teaor08_2d) cluster(frame_id_numeric)
outreg2 using "`here'/output/table/dummies.tex", append `options'
