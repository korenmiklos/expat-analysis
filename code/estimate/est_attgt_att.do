clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_att", text replace

use "`here'/temp/analysis_sample.dta", clear

rename ever_foreign ef
rename ever_foreign_hire efh
rename has_expat_ceo has_expat

foreach var in foreign_only foreign_hire_only has_expat {
	attgt lnQL lnK lnL exporter lnQ, treatment(`var') aggregate(att) reps(20) notyet limitcontrol(foreign == 0)
	count if e(sample) == 1
	eststo m`var', title("`var'")
}

foreach var in foreign_hire_only has_expat {
		attgt lnQL lnK lnL exporter lnQ if efh, treatment(`var') aggregate(att) reps(20) notyet limitcontrol(foreign == 0)
		count if e(sample) == 1
		eststo mh`var', title("efh `var'")
}

esttab m* using "`here'/output/table_attgt_att.tex", mtitle b(3) se(3) replace
esttab m* using "`here'/output/table_attgt_att.txt", mtitle b(3) se(3) replace

log close
