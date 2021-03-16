*cd C:\Users\Almos\Documents\Research\Expat\Expat_git\expat-analysis
*clear all
*here
*local here = r(here)

*use "`here'/temp/analysis_sample.dta", clear

tsset frame_id_numeric year

*******Check number of ceos******************
bys frame_id_numeric: egen max_n_ceo = max(n_ceo)
bys frame_id_numeric: egen min_n_ceo = min(n_ceo)
gen diff = max_n_ceo-min_n_ceo

reghdfe n_ceo foreign has_expat lnL, a(teaor08_2d##year) cluster(frame_id_numeric)

******Event-time variable foreign**************
sort frame_id_numeric year
tempvar t_year
gen `t_year' = year if foreign==1 & foreign[_n-1]==0 
bys frame_id_numeric: egen first_year_foreign=max(`t_year')
gen time_foreign = year-first_year_foreign
replace time_foreign=. if foreign==0 & time_foreign>0

forval i=0/5 {
	
	gen foreign_e`i'=(time_foreign==-`i')
	gen foreigne`i'=(time_foreign==`i')

	}

replace foreigne5=1 if time_foreign>5 & time_foreign<.
drop foreign_e0

order foreign_e5 foreign_e4 foreign_e3 foreign_e2 foreign_e1 foreigne0 foreigne1 foreigne2 foreigne3 foreigne4 foreigne5, a(time_foreign) 

**Recompute spell using only hires
bys frame_id_numeric: egen first_year_firm = min(year)
tempvar t_hire
gen `t_hire'=hire_ceo
replace `t_hire' = 1 if first_year_firm==year 
bys frame_id_numeric: gen ceo_spell_hire=sum(`t_hire')


******Foreign-hired ceo***********
tempvar t_ceo
bys frame_id_numeric: egen `t_ceo'= max(ceo_spell_hire) if !foreign
bys frame_id_numeric: egen last_ceo_spell_do = max(`t_ceo')
gen foreign_hire = (ceo_spell_hire > last_ceo_spell_do)
replace foreign_hire = . if last_ceo_spell_do == .

bys frame_id_numeric: egen ever_foreign_hire = max(foreign_hire)


**********Insider vs. outsider local CEO***************
tempvar fh_ins
gen `fh_ins'=(foreign_hire==1 & has_insider==1 & hire_ceo==1)
bysort frame_id_numeric ceo_spell_hire: egen foreign_hire_insider=max(`fh_ins') 


*****expat alone
gen expat_alone = (has_expat & !has_local)

*******First, second etc ceos************

gen ceo_spell_foreign = ceo_spell_hire - last_ceo_spell_do
replace ceo_spell_foreign = 0 if ceo_spell_foreign<0

tempvar t_expat
bys frame_id_numeric ceo_spell_foreign: egen `t_expat' = max(hire_expat)

forval i=1/11 {
	gen foreign_hire_local_`i' = (ceo_spell_foreign == `i' & `t_expat'==0)
	gen foreign_hire_expat_`i' = (ceo_spell_foreign == `i' & `t_expat'==1)	
	}

gen foreign_hire_local_3plus = (ceo_spell_foreign > 2 & `t_expat'==0)
gen foreign_hire_expat_3plus = (ceo_spell_foreign > 2 & `t_expat'==1)


**********Sequence of hires*********
tempvar t_LL 
tempvar t_LE
tempvar t_EL
tempvar t_EE

tsset frame_id_numeric year
gen `t_LL' = (foreign_hire_local_2==1 & l.foreign_hire_local_1==1)
bys frame_id_numeric foreign_hire_local_2: egen foreign_hire_LL_2 = max(`t_LL') 
tsset frame_id_numeric year
gen `t_LE' = (foreign_hire_expat_2==1 & l.foreign_hire_local_1==1)
bys frame_id_numeric foreign_hire_expat_2: egen foreign_hire_LE_2 = max(`t_LE') 
tsset frame_id_numeric year
gen `t_EL' = (foreign_hire_local_2==1 & l.foreign_hire_expat_1==1)
bys frame_id_numeric foreign_hire_local_2: egen foreign_hire_EL_2 = max(`t_EL')
tsset frame_id_numeric year
gen `t_EE' = (foreign_hire_expat_2==1 & l.foreign_hire_expat_1==1)
bys frame_id_numeric foreign_hire_expat_2: egen foreign_hire_EE_2 = max(`t_EE')


***********Event time dummies for foreign_hire, expat************
sort frame_id_numeric year
foreach mantype in hire_local hire_expat `X' {
	
	tempvar t_year
	tempvar t_year_max
	gen `t_year' = year if foreign_`mantype'_1==1 & foreign_`mantype'_1[_n-1]==0 
	bys frame_id_numeric: egen `t_year_max'=max(`t_year')
	gen time_foreign_`mantype' = year-`t_year_max'
	*Make the variable 0 when the manager leaves
	replace time_foreign_`mantype'=. if foreign_`mantype'_1==0 & time_foreign_`mantype'>0


forval i=0/5 {
	
	gen foreign_`mantype'_1_e`i'=(time_foreign_`mantype'==-`i')
	gen foreign_`mantype'_1e`i'=(time_foreign_`mantype'==`i')

	}

replace foreign_`mantype'_1e5=1 if time_foreign_`mantype'>5 & time_foreign_`mantype'<.
drop foreign_`mantype'_1_e0
}

order foreign_hire_local_1_e5 foreign_hire_local_1_e4 foreign_hire_local_1_e3 foreign_hire_local_1_e2 foreign_hire_local_1_e1 foreign_hire_local_1e0 foreign_hire_local_1e1 foreign_hire_local_1e2 foreign_hire_local_1e3 foreign_hire_local_1e4 foreign_hire_local_1e5 foreign_hire_expat_1_e5 foreign_hire_expat_1_e4 foreign_hire_expat_1_e3 foreign_hire_expat_1_e2 foreign_hire_expat_1_e1 foreign_hire_expat_1e0 foreign_hire_expat_1e1 foreign_hire_expat_1e2 foreign_hire_expat_1e3 foreign_hire_expat_1e4 foreign_hire_expat_1e5, a(time_foreign_hire_expat)

*save, replace
