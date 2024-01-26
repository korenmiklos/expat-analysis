

	
	
*Role of continuous ik, net entry

use "$here/temp/analysis_sample.dta", clear
keep if time_foreign==-1 | time_foreign==1
keep if year>1996
gen n=1 if time_foreign==1
replace n=-1 if time_foreign==-1
egen N=total(n), by(frame_id_numeric)
keep if N==0
drop n N

gen immat_18_mill=immat_18/1000

gen n=1 if immat_18_mill>0
egen N=total(n), by(frame_id_numeric)

preserve
keep if ever_foreign==1 & ever_foreign_hire==0

gen x0=immat_18_mill if time_foreign==-1
gen x10=immat_18_mill if time_foreign==1 & N==2
gen x11=immat_18_mill if time_foreign==1 & N==1

egen IK_aggr_0=total(x0)
egen IK_aggr_10=total(x10)
egen IK_aggr_11=total(x11)
egen IK_N=total(has_IK), by(time_foreign)
sum IK_aggr_0 IK_aggr_10 IK_aggr_11
tab IK_N time_foreign

restore

preserve
keep if ever_foreign_hire==1 & ever_expat==0

gen x0=immat_18_mill if time_foreign==-1
gen x10=immat_18_mill if time_foreign==1 & N==2
gen x11=immat_18_mill if time_foreign==1 & N==1

egen IK_aggr_0=total(x0)
egen IK_aggr_10=total(x10)
egen IK_aggr_11=total(x11)
egen IK_N=total(has_IK), by(time_foreign)
sum IK_aggr_0 IK_aggr_10 IK_aggr_11
tab IK_N time_foreign

restore

preserve
keep if ever_expat==1

gen x0=immat_18_mill if time_foreign==-1
gen x10=immat_18_mill if time_foreign==1 & N==2
gen x11=immat_18_mill if time_foreign==1 & N==1

egen IK_aggr_0=total(x0)
egen IK_aggr_10=total(x10)
egen IK_aggr_11=total(x11)
egen IK_N=total(has_IK), by(time_foreign)
sum IK_aggr_0 IK_aggr_10 IK_aggr_11
tab IK_N time_foreign

restore	


*IK average pre and post

use "$here/temp/analysis_sample.dta", clear
keep if year>1996

gen immat_18_mill=immat_18/1000

*Create average values
tempvar x y

gen `x'=immat_18_mill if time_foreign>-2 & time_foreign<0
egen IK_pre=mean(`x'), by(frame_id_numeric)

gen `y'=immat_18_mill if time_foreign>-1 & time_foreign<3
egen IK_post=mean(`y'), by(frame_id_numeric)


keep if time_foreign==-1 | time_foreign==1

*drop firms that do not have both years
gen n=1
egen N=total(n), by(frame_id_numeric)
keep if N==2
drop n N

gen n=-1 if time_foreign==-1 & IK_pre>0
replace n=1 if time_foreign==1 & IK_post>0
egen N=total(n), by(frame_id_numeric)

tab N

*Foreign 
preserve

keep if ever_foreign==1 & ever_foreign_hire==0

gen x0=IK_pre if time_foreign==-1 & N==-1
gen x10=IK_pre if time_foreign==-1 & N==0
gen x11=IK_post if time_foreign==1 & N==0
gen x1=IK_post if time_foreign==1 & N==1

egen IK_aggr_0_1=total(x0)
egen IK_aggr_0_2=total(x10)
egen IK_aggr_1_2=total(x11)
egen IK_aggr_1_0=total(x1)

sum x*

sum IK_aggr*

restore

*Foreign hire
preserve

keep if ever_foreign_hire==1 & ever_expat==0

gen x0=IK_pre if time_foreign==-1 & N==-1
gen x10=IK_pre if time_foreign==-1 & N==0
gen x11=IK_post if time_foreign==1 & N==0
gen x1=IK_post if time_foreign==1 & N==1

egen IK_aggr_0_1=total(x0)
egen IK_aggr_0_2=total(x10)
egen IK_aggr_1_2=total(x11)
egen IK_aggr_1_0=total(x1)

sum x*

sum IK_aggr*

restore

*Expat
preserve

keep if ever_expat==1

gen x0=IK_pre if time_foreign==-1 & N==-1
gen x10=IK_pre if time_foreign==-1 & N==0
gen x11=IK_post if time_foreign==1 & N==0
gen x1=IK_post if time_foreign==1 & N==1

egen IK_aggr_0_1=total(x0)
egen IK_aggr_0_2=total(x10)
egen IK_aggr_1_2=total(x11)
egen IK_aggr_1_0=total(x1)

sum x*

sum IK_aggr*

restore


*IK decomposition


preserve

keep if ever_foreign==1 & ever_foreign_hire==0

egen IK_aggr_0=total(IK_pre)
egen IK_aggr_1=total(IK_post)
egen IK_N=total(has_IK), by(time_foreign)

tab IK_N time_foreign
sum IK_aggr_0 IK_aggr_1 

restore

preserve

keep if ever_foreign_hire==1 & ever_expat==0

egen IK_aggr_0=total(IK_pre)
egen IK_aggr_1=total(IK_post)
egen IK_N=total(has_IK), by(time_foreign)

tab IK_N time_foreign
sum IK_aggr_0 IK_aggr_1 

restore

preserve

keep if ever_expat==1

egen IK_aggr_0=total(IK_pre)
egen IK_aggr_1=total(IK_post)
egen IK_N=total(has_IK), by(time_foreign)

tab IK_N time_foreign
sum IK_aggr_0 IK_aggr_1 

restore

