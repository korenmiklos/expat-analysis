
tsset frame_id_numeric year

*******Check number of ceos******************
bys frame_id_numeric: egen max_n_ceo = max(n_ceo)
bys frame_id_numeric: egen min_n_ceo = min(n_ceo)
gen diff = max_n_ceo-min_n_ceo

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
* allow for greenfield firms for whom last_ceo_spell_do == .
generate byte foreign_hire = (ceo_spell_hire > last_ceo_spell_do) | missing(last_ceo_spell_do)
drop x*

bys frame_id_numeric: egen ever_foreign_hire = max(foreign_hire)



*****expat alone
gen expat_alone = (has_expat & !has_local)

