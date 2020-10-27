use "temp\analysis_sample.dta", clear

******Event-time variable for foreign**************
sort frame_id_numeric year
gen x = year if foreign==1 & foreign[_n-1]==0 
bys frame_id_numeric: egen first_year_foreign=max(x)
drop x
gen time_foreign = year-first_year_foreign


**Recompute spell using only hires
rename ceo_spell ceo_spell_old
bys frame_id_numeric: egen first_year_firm = min(year)
gen x=hire_ceo
replace x = 1 if first_year_firm==year 
bys frame_id_numeric: gen ceo_spell=sum(x)
drop x

******Foreign-hired ceo***********
bys frame_id_numeric: egen x = max(ceo_spell) if !foreign
bys frame_id_numeric: egen last_ceo_spell_do = max(x)
gen foreign_hire = (ceo_spell > last_ceo_spell_do)
replace foreign_hire = . if last_ceo_spell_do == .
drop x*

bys frame_id_numeric: egen ever_foreign_hire = max(foreign_hire)


*******First, second etc ceos************

gen ceo_spell_foreign = ceo_spell - last_ceo_spell_do
replace ceo_spell_foreign = 0 if ceo_spell_foreign<0
sum ceo_spell_foreign

forval i=1/11 {
	gen foreign_hire_`i' = (ceo_spell_foreign == `i')
	gen has_expat_`i' = foreign_hire_`i'*has_expat
}

******Sequence of CEOs************

	


*Expat CEO alone
gen expat_alone = (has_expat == 1 & has_local == 0)


*Keep firms with 2 manager_spells during foreign
bysort frame_id_numeric: egen x = max(manager_spell) if foreign & start_as_domestic & owner_spell <4 
bysort frame_id_numeric: egen last_manager_spell_fo = max(x)
drop x

gen manager_spell_n_fo = last_manager_spell_fo - last_manager_spell_do
replace manager_spell_n_fo = 0 if !foreign


*Sequence of hires
gen x = manager_spell*foreign_hire
tab x if x>0, gen(foreign_hire_spell_)

gen xx = manager_spell*has_expat
tab xx if xx>0, gen(has_expat_spell_)

recode foreign_hire_spell* has_expat_spell* (. = 0)	
drop x*

gen foreign_hire_spell_5plus = foreign_hire_spell_5+foreign_hire_spell_6+foreign_hire_spell_7+foreign_hire_spell_8+foreign_hire_spell_9+foreign_hire_spell_10+foreign_hire_spell_11+foreign_hire_spell_12+foreign_hire_spell_13+foreign_hire_spell_14

gen has_expat_spell_5plus = has_expat_spell_5+has_expat_spell_6+has_expat_spell_7+has_expat_spell_8+foreign_hire_spell_9+has_expat_spell_10+has_expat_spell_11+has_expat_spell_12+has_expat_spell_13

global manager_spell foreign_hire_spell_1 foreign_hire_spell_2 foreign_hire_spell_3 foreign_hire_spell_4 foreign_hire_spell_5plus has_expat_spell_1 has_expat_spell_2 has_expat_spell_3 has_expat_spell_4 has_expat_spell_5plus
