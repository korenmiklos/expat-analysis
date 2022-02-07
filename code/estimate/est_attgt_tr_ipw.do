clear all
* find root folder
here
local here = r(here)

cap log close
log using "`here'/output/est_attgt_tr_ipw", text replace

use "`here'/temp/analysis_sample.dta", clear

rename ever_foreign ef
rename ever_foreign_hire efh
rename has_expat_ceo has_expat

count
count if ef & time_foreign <= 5

foreach type in e att gt {
	attgt lnQL lnK lnL exporter lnQ, treatment(has_expat) treatment2(foreign_hire_only) aggregate(`type') pre(5) post(5) reps(20) ipw(lnQ lnK lnL lnM exporter)
	count if e(sample) == 1
	eststo m, title("ef")

	attgt lnQL lnK lnL exporter lnQ if efh, treatment(has_expat) treatment2(foreign_hire_only) aggregate(`type') pre(5) post(5) reps(20) ipw(lnQ lnK lnL lnM exporter)
	count if e(sample) == 1
	eststo mh, title("efh")

	attgt lnQL lnK lnL exporter lnQ, treatment(foreign_hire_only) treatment2(has_expat) aggregate(`type') pre(5) post(5) reps(20) ipw(lnQ lnK lnL lnM exporter)
	count if e(sample) == 1
	eststo mi, title("ef inverse")

	attgt lnQL lnK lnL exporter lnQ if efh, treatment(foreign_hire_only) treatment2(has_expat) aggregate(`type') pre(5) post(5) reps(20) ipw(lnQ lnK lnL lnM exporter)
	count if e(sample) == 1
	eststo mhi, title("efh inverse")
	
	esttab m* using "`here'/output/table_attgt_tr_ipw_`type'.tex", mtitle b(3) se(3) replace
	esttab m* using "`here'/output/table_attgt_tr_ipw_`type'.txt", mtitle b(3) se(3) replace
}
	
log close
