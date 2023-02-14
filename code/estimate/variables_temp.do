
*Industry classification

egen teaor08_1d_num=group(teaor08_1d)

label define ind_1 1 "Agriculture" 2 "Mining" 3 "Manufacturing" 4 "Energy" 5 "Water, Waste Management" 6 "Construction" 7 "Trade, Repair" 8 "Transportation" 9 "Hotels, Restaurants" 10 "Finance" 11 "Real Estate" 12 "Professional Services" 13 "Admin., Support Service" 14 "State Admin., Defense" 15 "Education" 16 "Health" 17 "Arts, Recreation" 18 "Other Services" 
*Infocommmunication is missing (J)

label values teaor08_1d_num ind_1


*Firm type
gen firm_type=1 if ever_foreign==0
replace firm_type=2 if ever_foreign==1 & ever_foreign_hire==0
replace firm_type=3 if ever_foreign_hire==1 & ever_expat==0
replace firm_type=4 if ever_expat==1

label define type 1 "Domestic" 2 "Foreign" 3 "Local hire" 4 "Expat", replace
label values firm_type type

*log vars
gen lnIK=ln(immat_18)
gen lnQd=ln(sales_18-export_18)
gen lnExport=ln(export_18)

*Pre-acq productivity
gen high_tfp=.
forval i=1985/2018 {
	
	quietly sum TFP_cd if year==`i', d
	gen median_tfp=r(p50) if year==`i'
	replace high_tfp=1 if TFP_cd>=median_tfp & TFP_cd!=. & year==`i'
	replace high_tfp=0 if TFP_cd<median_tfp & TFP_cd!=. & year==`i'	
	drop median_tfp
}

	


