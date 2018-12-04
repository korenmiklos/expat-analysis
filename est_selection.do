*Szelekció az akvicíziós mintában
xtset firm_person year
areg f1.expat $outcomes if ever_foreign==1&greenfield!=1, a(industry_year) cluster(frame_id)
do regram output/regression/selection 1 1
keep if ever_foreign==1
