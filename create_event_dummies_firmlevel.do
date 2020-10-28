*cd C:\Users\Almos\Documents\Research\Expat\Expat_git\expat-analysis

use "temp\analysis_sample.dta", clear
tsset frame_id_numeric year

*******Check number of ceos******************
bys frame_id_numeric: egen max_n_ceo = max(n_ceo)
bys frame_id_numeric: egen min_n_ceo = min(n_ceo)
gen diff = max_n_ceo-min_n_ceo

reghdfe n_ceo foreign has_expat lnL, a(teaor08_2d##year) cluster(frame_id_numeric)


******Event-time variable for foreign**************
sort frame_id_numeric year
gen x = year if foreign==1 & foreign[_n-1]==0 
bys frame_id_numeric: egen first_year_foreign=max(x)
drop x
gen time_foreign = year-first_year_foreign


**Recompute spell using only hires
bys frame_id_numeric: egen first_year_firm = min(year)
gen x=hire_ceo
replace x = 1 if first_year_firm==year 
bys frame_id_numeric: gen ceo_spell_hire=sum(x)
drop x

******Foreign-hired ceo***********
bys frame_id_numeric: egen x = max(ceo_spell_hire) if !foreign
bys frame_id_numeric: egen last_ceo_spell_do = max(x)
gen foreign_hire = (ceo_spell_hire > last_ceo_spell_do)
replace foreign_hire = . if last_ceo_spell_do == .
drop x*

bys frame_id_numeric: egen ever_foreign_hire = max(foreign_hire)



*****expat alone
gen expat_alone = (has_expat & !has_local)

*******First, second etc ceos************

gen ceo_spell_foreign = ceo_spell_hire - last_ceo_spell_do
replace ceo_spell_foreign = 0 if ceo_spell_foreign<0


bys frame_id_numeric ceo_spell_foreign: egen x_expat = max(hire_expat)

forval i=1/11 {
	gen foreign_hire_local_`i' = (ceo_spell_foreign == `i' & x_expat==0)
	gen foreign_hire_expat_`i' = (ceo_spell_foreign == `i' & x_expat==1)	
	}

gen foreign_hire_local_3plus = (ceo_spell_foreign > 2 & x_expat==0)
gen foreign_hire_expat_3plus = (ceo_spell_foreign > 2 & x_expat==1)

drop x

*Check the dummies

*gen x = foreign - foreign_hire_local_1 - foreign_hire_local_2 - foreign_hire_local_3 - foreign_hire_local_4plus - foreign_hire_expat_1 - foreign_hire_expat_2 - foreign_hire_expat_3 - foreign_hire_expat_4plus

*sum x if foreign_hire
*drop x*

**********Sequence of hires*********
tsset frame_id_numeric year
gen x_LL = (foreign_hire_local_2==1 & l.foreign_hire_local_1==1)
bys frame_id_numeric foreign_hire_local_2: egen foreign_hire_LL_2 = max(x_LL) 
tsset frame_id_numeric year
gen x_LE = (foreign_hire_expat_2==1 & l.foreign_hire_local_1==1)
bys frame_id_numeric foreign_hire_expat_2: egen foreign_hire_LE_2 = max(x_LE) 
tsset frame_id_numeric year
gen x_EL = (foreign_hire_local_2==1 & l.foreign_hire_expat_1==1)
bys frame_id_numeric foreign_hire_local_2: egen foreign_hire_EL_2 = max(x_EL)
tsset frame_id_numeric year
gen x_EE = (foreign_hire_expat_2==1 & l.foreign_hire_expat_1==1)
bys frame_id_numeric foreign_hire_expat_2: egen foreign_hire_EE_2 = max(x_EE)

drop x* 
 


****Expat CEO alone************
gen expat_alone = (has_expat == 1 & has_local == 0)




*Regressions to try out the dummies (can be deleted later)

reghdfe lnQL foreign foreign_hire has_expat, a(frame_id_numeric year##teaor08_2d) cluster(frame_id_numeric)

reghdfe lnQL foreign foreign_hire_local_* foreign_hire_expat_*, a(frame_id_numeric year##teaor08_2d) cluster(frame_id_numeric)

reghdfe lnQL foreign foreign_hire_local_1 foreign_hire_expat_1 foreign_hire_local_2 foreign_hire_expat_2 foreign_hire_local_3 foreign_hire_expat_3 foreign_hire_local_4plus foreign_hire_expat_4plus, a(frame_id_numeric year##teaor08_2d) cluster(frame_id_numeric)

reghdfe lnQL foreign foreign_hire_local_1 foreign_hire_expat_1 foreign_hire_local_2 foreign_hire_expat_2 foreign_hire_local_3plus foreign_hire_expat_3plus, a(frame_id_numeric year##teaor08_2d) cluster(frame_id_numeric)

reghdfe lnQL foreign foreign_hire_local_1 foreign_hire_expat_1 foreign_hire_LL_2 foreign_hire_EL_2 foreign_hire_LE_2 foreign_hire_EE_2 foreign_hire_local_3plus foreign_hire_expat_3plus, a(frame_id_numeric year##teaor08_2d) cluster(frame_id_numeric)