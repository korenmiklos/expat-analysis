clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_ipw", text replace

use "`here'/temp/analysis_sample.dta", clear

rename ever_foreign ef
rename ever_foreign_hire efh
rename has_expat_ceo has_expat

count
count if ef & time_foreign <= 5

foreach var in foreign_only foreign_hire_only has_expat {
		attgt lnQL lnK lnL exporter lnQ, treatment(`var') aggregate(e) pre(5) post(5) reps(20) notyet limitcontrol(foreign == 0) ipw(lnQ lnK lnL lnM exporter)
		count if e(sample) == 1
		eststo m`var', title("`var'")
}

foreach var in foreign_hire_only has_expat {
		attgt lnQL lnK lnL exporter lnQ if efh, treatment(`var') aggregate(e) pre(5) post(5) reps(20) notyet limitcontrol(foreign == 0) ipw(lnQ lnK lnL lnM exporter)
		count if e(sample) == 1
		eststo mh`var', title("efh `var'")
}

esttab m* using "`here'/output/table_attgt_ipw.tex", mtitle b(3) se(3) replace
esttab m* using "`here'/output/table_attgt_ipw.txt", mtitle b(3) se(3) replace

log close
