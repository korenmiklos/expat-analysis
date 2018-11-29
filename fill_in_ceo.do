tab pos5
gen ceo = (pos5==1) if !missing(pos5)

*Amennyiben egy személy egy cégnél egy évben többször szerepelt, és ceo is volt, esetében a ceo pos5 megtartása
duplicates tag frame_id manager_id year, gen(manager_duplicate)

bys frame_id manager_id year: egen manager_ceo = max(ceo)
drop if manager_duplicate>0 & (manager_ceo==1) & !(ceo==1)
drop manager_duplicate

* before all the cleaning
tab ceo, miss
count if missing(ceo)
scalar missing_ceo_before = r(N)

*Duplikációk összeejtése - innentől egy személy egyszer szerepel egy vállalati évben
collapse (firstnm) person_foreign (max) ceo, by(frame_id manager_id year)


*Pos5 húzások előkészítése
bys frame_id year: gen man_number=_N
*bys frame_id year: egen ceo_number=total(cond(pos5==1,pos5,.))
bys frame_id year: egen ceo_exist=max(ceo)

*Egy menedzseres cégeknél, ha nincs ceo, a menedzser ceo-vá kinevezése
count if ceo==1
scalar temp=r(N)
	replace ceo=1 if man_number==1&ceo_exist!=1
count if ceo==1
scalar no_other_manager = r(N)-temp

*Ceo_exist újraszámolása, mert változott a pos5-ok száma
drop ceo_exist
bys frame_id year: egen ceo_exist=max(ceo)

egen company_manager=group(frame_id manager_id)
xtset company_manager year

* this is on purpose, so that any chang is captured
gen change = ceo!=ceo[_n-1] 
/* index spells within a relationship so that

ceo 		= 1 1 1 . . 0 0
spell 		= 1 1 1 2 2 3 3
spell_year	= 1 2 3 1 2 1 2

*/
bys company_manager: gen spell = sum(change)
sort company_manager spell year
by company_manager spell: gen spell_year = _n
by company_manager spell: gen spell_length = _N


xtset company_manager year
tempvar ceo_prev ceo_next
gen `ceo_prev' = cond(spell_year==1, L.ceo, .)
gen `ceo_next' = cond(spell_year==spell_length, F.ceo, .)
egen ceo_prev = mean(`ceo_prev'), by(company_manager spell)
egen ceo_next = mean(`ceo_next'), by(company_manager spell)
drop `ceo_prev' `ceo_next'


* type of changes
tab ceo_prev ceo if spell_year==1, miss
tab ceo ceo_next if spell_year==spell_length, miss
assert ceo!=ceo_next if !missing(ceo)
assert ceo!=ceo_prev if !missing(ceo)

* descriptives
tab spell_length if missing(ceo) & ceo_prev==0 & ceo_next==0
tab spell_length if missing(ceo) & ceo_prev==0 & ceo_next==1
tab spell_length if missing(ceo) & ceo_prev==1 & ceo_next==0
tab spell_length if missing(ceo) & ceo_prev==1 & ceo_next==1


*Pos5 kihúzása, ha egy, kettő, három, négy vagy öt évnyi lyuk van, ugyanazon személy ugyanazon cégnél történő ceo tevékenysége között
tab ceo_prev ceo_next if missing(ceo)

count if ceo==1
scalar temp=r(N)
	replace ceo = ceo_prev if ceo_prev==ceo_next & !missing(ceo_prev) & missing(ceo) & spell_length<=5
count if ceo==1
scalar fill_gap_5 = r(N)-temp
drop ceo_exist
bys frame_id year: egen ceo_exist=max(ceo)

*Pos5 kihúzása három, kettő vagy egy évig, ha nincs más ceo és több menedzser van a cégnél - itt marad az eltolt ceo_exist, mert kicsit más a logika
count if ceo==1
scalar temp=r(N)
	replace ceo = 1 if (ceo_prev==1) & missing(ceo) & (ceo_exist==0) & spell_year<=3
count if ceo==1
scalar fill_forward_3 = r(N)-temp
drop ceo_exist
bys frame_id year: egen ceo_exist=max(ceo)

* one year back
count if ceo==1
scalar temp=r(N)
	replace ceo = 1 if (ceo_next==1) & missing(ceo) & (ceo_exist==0) & spell_year==spell_length
count if ceo==1
scalar fill_backward_1 = r(N)-temp

* after all the cleaning
tab ceo, miss
count if missing(ceo)
scalar missing_ceo_after = r(N)
