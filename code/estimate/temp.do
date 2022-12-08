



foreach var in foreign foreign_hire expat {
	
	forval i=1/5 {
	gen `var'_b`i'=(ever_`var'==1 & time_foreign==-`i')
	}
	
	forval i=0/5 {
	gen `var'_a`i'=(ever_`var'==1 & time_foreign==`i')
	}

order `var'_b5 `var'_b4 `var'_b3 `var'_b2 `var'_b1 `var'_a0 `var'_a1 `var'_a2 `var'_a3 `var'_a4 `var'_a5

recode `var'_b* `var'_a* (.=0) if ever_foreign==0
}

foreach var in foreign foreign_hire expat_hire {
	
	attgt TFP_cd, treatment(`var') aggregate(att) pre(5) post(5) notyet limitcontrol(foreign==0)
}
