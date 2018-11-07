*Betöltés
set more off


import delimited input/motherlode/manage.csv, varnames(1) clear


*Külföldi-magyar dummy
gen person_type=substr(manager_id,1,2)
keep if person_type=="FP"|person_type=="PH"|person_type=="PP"|person_type=="PR"|person_type=="NH"|person_type=="NO"
gen person_foreign=0
replace person_foreign=1 if person_type=="FP"


*Source darabolása
gen rovat_id=substr(source,1,2)
gen ceg_id=substr(source,4,10)
gen alrovat_id=substr(source,15,4)


destring rovat_id, replace
destring alrovat_id, replace
destring ceg_id, replace


*Pos5 kapcsolása
preserve
import delimited input/manager_position/pos5.csv, varnames(1) clear
drop if pos5==9
gen rovat_id=13
tempfile positions
save `positions'
restore


*duplicates report ceg_id rovat_id alrovat_id
*van eg cég, ahol a ceg_id rovat_id alrovat_id nem határozza meg egyértelműen a személyt - a ceg_id:110041043, ezért kell merge m:1
merge m:1 ceg_id rovat_id alrovat_id using `positions', keepusing(pos5)
drop if _merge==2
drop _merge


*Panelify
gen year_from=substr(valid_from,1,4)
destring year_from, replace
gen month_from=substr(valid_from,6,2)
destring month_from, replace
gen day_from=substr(valid_from,9,2)
destring day_from, replace
gen year_till=substr(valid_till,1,4)
destring year_till, replace
gen month_till=substr(valid_till,6,2)
destring month_till, replace
gen day_till=substr(valid_till,9,2)
destring day_till, replace
replace year_till=2018 if valid_till==""
replace month_till=12 if valid_till==""
replace day_till=31 if valid_till==""


replace year_from=year_from+1 if month_from>6|(month_from==6&day_from>20)
replace year_till=year_till-1 if month_till<6|(month_till==6&day_till<21)


gen diff=year_till-year_from+1
drop if diff<=0
expand diff


bys ceg_id rovat_id alrovat_id: gen year_relative=_n
gen year=year_from+year_relative-1


*Duplikációk összeejtése
*duplicates report frame_id manager_id year
*duplicates report frame_id manager_id year pos5
collapse (mean)	person_foreign, by(frame_id manager_id year pos5)
tab person_foreign


*Pos5 dummy-vá alakítása (ceo-nem ceo)
recode pos5(.=2) (0=2) (3=2)


*Amennyiben egy személy egy cégnél egy évben többször szerepelt, és ceo is volt, esetében a ceo pos5 megtartása
duplicates tag frame_id manager_id year, gen(manager_duplicate)


bys frame_id manager_id year: egen manager_ceo=min(pos5)
drop if manager_duplicate>0&pos5==2&manager_ceo==1
drop manager_duplicate


*Duplikációk összeejtése - innentől egy személy egyszer szerepel egy vállalati évben
*duplicates report frame_id manager_id year
*duplicates report frame_id manager_id year pos5
collapse (mean)	person_foreign pos5, by(frame_id manager_id year)


*Pos5 húzások előkészítése
bys frame_id year: gen man_number=_N
*bys frame_id year: egen ceo_number=total(cond(pos5==1,pos5,.))
bys frame_id year: egen ceo_exist=min(pos5)
recode ceo_exist (2=0)


*Egy menedzseres cégeknél, ha nincs ceo, a menedzser ceo-vá kinevezése
replace pos5=1 if man_number==1&ceo_exist==0


*Ceo_exist újraszámolása, mert változott a pos5-ok száma
drop ceo_exist
bys frame_id year: egen ceo_exist=min(pos5)
recode ceo_exist (2=0)


egen company_manager=group(frame_id manager_id)
xtset company_manager year
clonevar pos5_reference=pos5


*Pos5 kihúzása, ha egy, kettő, három, négy vagy öt évnyi lyuk van, ugyanazon személy ugyanazon cégnél történő ceo tevékenysége között
*Úgy, hogy több menedzser is van a cégnél, és nincs másik ceo közben
replace pos5=1 if l1.pos5_reference==1&pos5_reference==2&f1.pos5_reference==1&ceo_exist==0&man_number>1


*replace pos5=1 if l1.pos5_reference==1&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==1&ceo_exist==0&f1.ceo_exist==0&man_number>1 //&f1.man_number>1
*A ceo_exist időben eltolt verzióit most nem kötöm ki, hogy 0-k legyenek - nincs nagy különbség, így most több a változás - a négy lyukas megoldásnál
*meghagyom az eredetit erre példaként
replace pos5=1 if l1.pos5_reference==1&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==1&ceo_exist==0&man_number>1
replace pos5=1 if l2.pos5_reference==1&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==1&ceo_exist==0&man_number>1


replace pos5=1 if l1.pos5_reference==1&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==2&f3.pos5_reference==1&ceo_exist==0&man_number>1
replace pos5=1 if l2.pos5_reference==1&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==1&ceo_exist==0&man_number>1
replace pos5=1 if l3.pos5_reference==1&l2.pos5_reference==2&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==1&ceo_exist==0&man_number>1



*replace pos5=1 if l1.pos5_reference==1&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==2&f3.pos5_reference==2&f4.pos5_reference==1& ///
*ceo_exist==0&f1.ceo_exist==0&f2.ceo_exist==0&f3.ceo_exist==0&man_number>1
*replace pos5=1 if l2.pos5_reference==1&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==2&f3.pos5_reference==1& ///
*l1.ceo_exist==0&ceo_exist==0&f1.ceo_exist==0&f2.ceo_exist==0&man_number>1
*replace pos5=1 if l3.pos5_reference==1&l2.pos5_reference==2&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==1& ///
*l2.ceo_exist==0&l1.ceo_exist==0&ceo_exist==0&f1.ceo_exist==0&man_number>1
*replace pos5=1 if l4.pos5_reference==1&l3.pos5_reference==2&l2.pos5_reference==2&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==1& ///
*l3.ceo_exist==0&l2.ceo_exist==0&l1.ceo_exist==0&ceo_exist==0&man_number>1


replace pos5=1 if l1.pos5_reference==1&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==2&f3.pos5_reference==2&f4.pos5_reference==1& ///
ceo_exist==0&man_number>1
replace pos5=1 if l2.pos5_reference==1&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==2&f3.pos5_reference==1& ///
ceo_exist==0&man_number>1
replace pos5=1 if l3.pos5_reference==1&l2.pos5_reference==2&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==1& ///
ceo_exist==0&man_number>1
replace pos5=1 if l4.pos5_reference==1&l3.pos5_reference==2&l2.pos5_reference==2&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==1& ///
ceo_exist==0&man_number>1


replace pos5=1 if l1.pos5_reference==1&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==2&f3.pos5_reference==2&f4.pos5_reference==2&f5.pos5_reference==1& ///
ceo_exist==0&man_number>1
replace pos5=1 if l2.pos5_reference==1&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==2&f3.pos5_reference==2&f4.pos5_reference==1& ///
ceo_exist==0&man_number>1
replace pos5=1 if l3.pos5_reference==1&l2.pos5_reference==2&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==2&f3.pos5_reference==1& ///
ceo_exist==0&man_number>1
replace pos5=1 if l4.pos5_reference==1&l3.pos5_reference==2&l2.pos5_reference==2&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==1& ///
ceo_exist==0&man_number>1
replace pos5=1 if l5.pos5_reference==1&l4.pos5_reference==2&l3.pos5_reference==2&l2.pos5_reference==2&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==1& ///
ceo_exist==0&man_number>1


*Pos5 kihúzása három, kettő vagy egy évig, ha nincs más ceo és több menedzser van a cégnél - itt marad az eltolt ceo_exist, mert kicsit más a logika
replace pos5=1 if l1.pos5_reference==1&pos5_reference==2&f1.pos5_reference==2&f2.pos5_reference==2&ceo_exist==0&f1.ceo_exist==0&f2.ceo_exist==0&man_number>1
replace pos5=1 if l2.pos5_reference==1&l1.pos5_reference==2&pos5_reference==2&f1.pos5_reference==2&l1.ceo_exist==0&ceo_exist==0&f1.ceo_exist==0&man_number>1
replace pos5=1 if l3.pos5_reference==1&l2.pos5_reference==2&l1.pos5_reference==2&pos5_reference==2&l2.ceo_exist==0&l1.ceo_exist==0&ceo_exist==0&man_number>1


replace pos5=1 if l1.pos5_reference==1&pos5_reference==2&f1.pos5_reference==2&ceo_exist==0&f1.ceo_exist==0&man_number>1
replace pos5=1 if l2.pos5_reference==1&l1.pos5_reference==2&pos5_reference==2&l1.ceo_exist==0&ceo_exist==0&man_number>1


replace pos5=1 if l1.pos5_reference==1&pos5_reference==2&ceo_exist==0&man_number>1


*Cégalapítás éve
bys frame_id: egen firstyear=min(year)


*Drop helyett conditional használata, de az eredmény ugyanaz
*keep if pos5==1
*bys frame_id manager_id: egen enter_year=min(year)
*bys frame_id manager_id: egen exit_year=max(year)


*Adott ceo első megjelenése és utolsó kilépése
bys frame_id manager_id: egen enter_year=min(cond(pos5==1,year,.))
bys frame_id manager_id: egen exit_year=max(cond(pos5==1,year,.))


gen enter=0
replace enter=1 if year==enter_year&year!=firstyear
gen exit=0
replace exit=1 if year==exit_year&year!=firstyear
drop enter_year exit_year


gen domestic_ceo_entry_exit=1 if enter&exit&!person_foreign&pos5==1
gen expat_ceo_entry_exit=1 if enter&exit&person_foreign&pos5==1
gen domestic_ceo_entry=1 if enter&!exit&!person_foreign&pos5==1
gen expat_ceo_entry=1 if enter&!exit&person_foreign&pos5==1
gen domestic_ceo_exit=1 if !enter&exit&!person_foreign&pos5==1
gen expat_ceo_exit=1 if !enter&exit&person_foreign&pos5==1
gen domestic_ceo=1 if !enter&!exit&!person_foreign&pos5==1
gen expat_ceo=1 if !enter&!exit&person_foreign&pos5==1


*Kezelni kell azokat az eseteket, amikor a ceo elmegy, majd visszajön ugyanahhoz a céghez (mert az entry az első entry, az exit az utolsó exit)
*Ilyenkor hirtelen el kellene tűnnie a következő évre az ott lévő, vagy éppen belépett menedzsernek kilépés nélkül
*Vagy meg kellene jelennie hirtelen a menedzsernek
xtset company_manager year
count if (domestic_ceo==1|domestic_ceo_entry==1)&f1.domestic_ceo==.&f1.domestic_ceo_entry_exit==.&f1.domestic_ceo_entry==.&f1.domestic_ceo_exit==.&f1.year!=.&year!=firstyear
count if (expat_ceo==1|expat_ceo_entry==1)&f1.expat_ceo==.&f1.expat_ceo_entry_exit==.&f1.expat_ceo_entry==.&f1.expat_ceo_exit==.&f1.year!=.&year!=firstyear
count if (domestic_ceo==1|domestic_ceo_exit==1)&l1.domestic_ceo==.&l1.domestic_ceo_entry_exit==.&l1.domestic_ceo_entry==.&l1.domestic_ceo_exit==.&l1.year!=. //&l1.year!=firstyear - ez a kitétel nem számít
count if (expat_ceo==1|expat_ceo_exit==1)&l1.expat_ceo==.&l1.expat_ceo_entry_exit==.&l1.expat_ceo_entry==.&l1.expat_ceo_exit==.&l1.year!=. //&l1.year!=firstyear - ez a kitétel nem számít


clonevar domestic_ceo_entry_exitreference=domestic_ceo_entry_exit
clonevar expat_ceo_entry_exitreference=expat_ceo_entry_exit
clonevar domestic_ceo_entry_reference=domestic_ceo_entry
clonevar expat_ceo_entry_reference=expat_ceo_entry
clonevar domestic_ceo_exit_reference=domestic_ceo_exit
clonevar expat_ceo_exit_reference=expat_ceo_exit
clonevar domestic_ceo_reference=domestic_ceo
clonevar expat_ceo_reference=expat_ceo



replace domestic_ceo_entry_exit=1 if domestic_ceo_entry_reference==1&f1.domestic_ceo_reference==.&f1.domestic_ceo_entry_exitreference==.& ///
f1.domestic_ceo_entry_reference==.&f1.domestic_ceo_exit_reference==.&f1.year!=.&year!=firstyear
replace domestic_ceo_entry=0 if domestic_ceo_entry_reference==1&f1.domestic_ceo_reference==.&f1.domestic_ceo_entry_exitreference==.& ///
f1.domestic_ceo_entry_reference==.&f1.domestic_ceo_exit_reference==.&f1.year!=.&year!=firstyear


replace domestic_ceo_exit=1 if domestic_ceo_reference==1&f1.domestic_ceo_reference==.&f1.domestic_ceo_entry_exitreference==.& ///
f1.domestic_ceo_entry_reference==.&f1.domestic_ceo_exit_reference==.&f1.year!=.&year!=firstyear
replace domestic_ceo=0 if domestic_ceo_reference==1&f1.domestic_ceo_reference==.&f1.domestic_ceo_entry_exitreference==.& ///
f1.domestic_ceo_entry_reference==.&f1.domestic_ceo_exit_reference==.&f1.year!=.&year!=firstyear


replace expat_ceo_entry_exit=1 if expat_ceo_entry_reference==1&f1.expat_ceo_reference==.&f1.expat_ceo_entry_exitreference==.& ///
f1.expat_ceo_entry_reference==.&f1.expat_ceo_exit_reference==.&f1.year!=.&year!=firstyear
replace expat_ceo_entry=0 if expat_ceo_entry_reference==1&f1.expat_ceo_reference==.&f1.expat_ceo_entry_exitreference==.& ///
f1.expat_ceo_entry_reference==.&f1.expat_ceo_exit_reference==.&f1.year!=.&year!=firstyear


replace expat_ceo_exit=1 if expat_ceo_reference==1&f1.expat_ceo_reference==.&f1.expat_ceo_entry_exitreference==.& ///
f1.expat_ceo_entry_reference==.&f1.expat_ceo_exit_reference==.&f1.year!=.&year!=firstyear
replace expat_ceo=0 if expat_ceo_reference==1&f1.expat_ceo_reference==.&f1.expat_ceo_entry_exitreference==.& ///
f1.expat_ceo_entry_reference==.&f1.expat_ceo_exit_reference==.&f1.year!=.&year!=firstyear


replace domestic_ceo_entry_exit=1 if domestic_ceo_exit_reference==1&l1.domestic_ceo_reference==.&l1.domestic_ceo_entry_exitreference==.& ///
l1.domestic_ceo_entry_reference==.&l1.domestic_ceo_exit_reference==.&l1.year!=.
replace domestic_ceo_exit=0 if domestic_ceo_exit_reference==1&l1.domestic_ceo_reference==.&l1.domestic_ceo_entry_exitreference==.& ///
l1.domestic_ceo_entry_reference==.&l1.domestic_ceo_exit_reference==.&l1.year!=.


replace domestic_ceo_entry=1 if domestic_ceo_reference==1&l1.domestic_ceo_reference==.&l1.domestic_ceo_entry_exitreference==.& ///
l1.domestic_ceo_entry_reference==.&l1.domestic_ceo_exit_reference==.&l1.year!=.
replace domestic_ceo=0 if domestic_ceo_reference==1&l1.domestic_ceo_reference==.&l1.domestic_ceo_entry_exitreference==.& ///
l1.domestic_ceo_entry_reference==.&l1.domestic_ceo_exit_reference==.&l1.year!=.


replace expat_ceo_entry_exit=1 if expat_ceo_exit_reference==1&l1.expat_ceo_reference==.&l1.expat_ceo_entry_exitreference==.& ///
l1.expat_ceo_entry_reference==.&l1.expat_ceo_exit_reference==.&l1.year!=.
replace expat_ceo_exit=0 if expat_ceo_exit_reference==1&l1.expat_ceo_reference==.&l1.expat_ceo_entry_exitreference==.& ///
l1.expat_ceo_entry_reference==.&l1.expat_ceo_exit_reference==.&l1.year!=.


replace expat_ceo_entry=1 if expat_ceo_reference==1&l1.expat_ceo_reference==.&l1.expat_ceo_entry_exitreference==.& ///
l1.expat_ceo_entry_reference==.&l1.expat_ceo_exit_reference==.&l1.year!=.
replace expat_ceo=0 if expat_ceo_reference==1&l1.expat_ceo_reference==.&l1.expat_ceo_entry_exitreference==.& ///
l1.expat_ceo_entry_reference==.&l1.expat_ceo_exit_reference==.&l1.year!=.


*Cégév szintre ejtés
collapse (sum) domestic_ceo_entry_exit expat_ceo_entry_exit domestic_ceo_entry expat_ceo_entry domestic_ceo_exit expat_ceo_exit domestic_ceo expat_ceo, by(frame_id year)


*Elkészült cégszintű menedzser adat
save ${data}/ceo, replace







*Balance sheet-tel kapcsolás
use ${data}/balance_sheet80_14, clear
drop if frame_id==""
merge 1:1 frame_id year using ${data}/ceo


drop if _merge==2
drop _merge


egen id=group(frame_id)
xtset id year
sort id year


*Expat CEO létezik változó készítése
gen expat_ceo_exist=0
egen expat_ceo_number=rowtotal(expat_ceo_entry_exit expat_ceo_entry expat_ceo_exit expat_ceo)
replace expat_ceo_exist=1 if expat_ceo_number>0&expat_ceo_number!=.


*Első expat CEO változó készítése
gen expat_ceo_year=expat_ceo_exist*year
bys frame_id: egen expat_ceo_first=min(cond(expat_ceo_year!=0,expat_ceo_year,.))
drop expat_ceo_year


*Több CEO
gen ceo_more=0
egen ceo_number=rowtotal(domestic_ceo_entry_exit domestic_ceo_entry domestic_ceo_exit domestic_ceo expat_ceo_entry_exit expat_ceo_entry expat_ceo_exit expat_ceo)
replace ceo_more=1 if ceo_number>1&ceo_number!=.


*Switch változó létrehozása
gen switch_ceo_exist=0
egen switch_ceo_number=rowtotal(expat_ceo_entry_exit expat_ceo_entry domestic_ceo_entry_exit domestic_ceo_entry)
replace switch_ceo_exist=1 if switch_ceo_number>0&switch_ceo_number!=.


bys frame_id: egen switch_ceo_total=total(switch_ceo_exist)
xtset id year
replace switch_ceo_exist=1 if ((l1.switch_ceo_number>0&l1.switch_ceo_number!=.)|(l2.switch_ceo_number>0&l2.switch_ceo_number!=.)|(l3.switch_ceo_number>0&l3.switch_ceo_number!=.)|(l4.switch_ceo_number>0&l4.switch_ceo_number!=.))&switch_ceo_number==0


*Expat_switch és expat_after interakciók létrehozása
gen expat_after=0
gen expat_switch=expat_ceo_exist*switch_ceo_exist
replace expat_after=1 if expat_ceo_exist==1&expat_switch==0


*Final netgép (K érdekében) hozzátétele
preserve
use ${data}/balance_sheet92_14_address_machines, clear
duplicates drop frame_id year, force
tempfile machines
save `machines'
restore


merge 1:1 frame_id year using `machines', keepusing(final_netgep)
drop if _merge==2
drop _merge


*Fo3 átalakítása 
recode fo3 (.=0)


*Fo3-at többször váltók kidobása
xtset id year
gen fo3_change=1 if l1.fo3==0&fo3==1
gen fo3_change_rev=1 if l1.fo3==1&fo3==0
bys frame_id: egen fo3_change_total=total(fo3_change)
bys frame_id: egen fo3_change_rev_total=total(fo3_change_rev)
drop if fo3_change_total>1|fo3_change_rev_total>1
drop fo3_change fo3_change_rev fo3_change_total fo3_change_rev_total


*Fo3 visszahúzása expatba, valaha expat-tal, de soha fo3-mal bíró cégek teljes kidobása
bys frame_id: egen fo3_ever=max(fo3) 
bys frame_id: egen expat_ceo_ever=max(expat_ceo_exist) 
replace fo3=1 if expat_ceo_first<=year&fo3==0&fo3_ever!=0
drop if expat_ceo_ever==1&fo3_ever==0


*Fo3_switch interakció létrehozása
gen fo3_switch_exist=fo3*switch_ceo_exist


*Fo3_switch szétbontása az fo3 váltás megtörténte előtt és után megjelenő új ceo szerint (lehet időben némi átfedés közöttük)
gen fo3_switch_before=0
xtset id year
replace fo3_switch_before=1 if (fo3_switch_exist==0&switch_ceo_exist==1&fo3_ever==1)|(fo3_switch_exist==1&l1.switch_ceo_number>0&l1.fo3==0)| ///
(fo3_switch_exist==1&l2.switch_ceo_number>0&l2.fo3==0)|(fo3_switch_exist==1&l3.switch_ceo_number>0&l3.fo3==0)|(fo3_switch_exist==1&l4.switch_ceo_number>0&l4.fo3==0)


gen fo3_switch_after=0
replace fo3_switch_after=1 if fo3_switch_exist==1&fo3_switch_before!=1
replace fo3_switch_after=1 if fo3_switch_exist==1&fo3_switch_before==1&(switch_ceo_number>0|(l1.fo3==1&l1.switch_ceo_number>0)|(l2.fo3==1&l2.switch_ceo_number>0)|(l3.fo3==1&l3.switch_ceo_number>0))


count if fo3_switch_exist==1
count if fo3_switch_before==1
count if fo3_switch_after==1


*Greenfield - fo3 húzás után, de a sampling előtt
bys frame_id (year): gen relative_year=_n
gen fo3_infirst=1 if relative_year==1&fo3==1
bys frame_id: egen greenfield=max(fo3_infirst)


recode greenfield (.=0)


*Függő változók készítése
gen lnL=ln(emp)
gen lnK=ln(final_netgep)
gen lnM=ln(ranyag)
gen lnQ=ln(sales)
gen lnQL=lnQ-lnL
gen lnKL=lnK-lnL
gen byte exporter = export>0&export!=.
replace exporter=0 if export==.


*Industry_year dummy
egen industry_year = group(teaor08_2d year)


*Industry dummy
gen ind=0
replace ind=1 if teaor08_1d=="B"|teaor08_1d=="C"|teaor08_1d=="D"|teaor08_1d=="E"
egen ind_year=group(ind year)


*Manufacaturing dummy
gen manufacturing=0
replace manufacturing=1 if teaor08_1d=="C"


*Átlagos létszám változó
bys frame_id: egen avg_emp = mean(emp)


*Életkor változó
gen age=year-foundyear
gen age_cat=.
replace age_cat=1 if age==0
replace age_cat=2 if age==1
replace age_cat=3 if age==2
replace age_cat=4 if age>=3&age<=5
replace age_cat=5 if age>=6&age<=8
replace age_cat=6 if age>8


*Mintavétel létszám és a K-n kvül a többi függő változó nem missing alapján
local sample (avg_emp>=20)&!missing(lnL,lnQ,exporter)
keep if `sample'


*Pénzügyi szektorban működő vállalatok kiszűrése
bys frame_id: egen industry_mode=mode(teaor08_2d)
drop if industry_mode==64|industry_mode==65|industry_mode==66


*Firm_tag
egen firm_tag=tag(frame_id)



*Investment változó készítése
reg lnK industry_year
predict res, res
sum res, d


xtset id year
g d_res=res-l1.res
g inv=0


replace inv=1 if d_res>=0.1&d_res!=.
replace inv=-1 if d_res<=-0.1&d_res!=.
replace inv=. if d_res==.


*Teljes minta elmentése a kontrollokkal
save ${data}/sample_full, replace


*Alapstatisztikák
count if fo3_ever&!greenfield&firm_tag
count if fo3_ever&!greenfield&firm_tag&expat_ceo_ever


*Alapmodellek lefuttatása (greenfield, illetve a ceo szempontjából missing sorok kivéve)
foreach X of var lnL lnQ lnK lnQL lnKL exporter inv{
	eststo: qui areg `X' fo3 switch_ceo_exist fo3_switch_after expat_switch expat_after i.ind_year i.age_cat if expat_ceo!=.&greenfield!=1, a(frame_id ) cluster(frame_id )
}
esttab using ${data}/results_base.rtf, b(3) se(3) r2 keep (fo3 switch_ceo_exist fo3_switch_after expat_switch expat_after _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear


*Alapmodellek lefuttatása - nem manufacturing
foreach X of var lnL lnQ lnK lnQL lnKL exporter inv{
	eststo: qui areg `X' fo3 switch_ceo_exist fo3_switch_after expat_switch expat_after i.ind_year i.age_cat if expat_ceo!=.&greenfield!=1&manufacturing!=1, a(frame_id ) cluster(frame_id )
}
esttab using ${data}/results_nonmanu.rtf, b(3) se(3) r2 keep (fo3 switch_ceo_exist fo3_switch_after expat_switch expat_after _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear


*Alapmodellek lefuttatása - manufacturing
foreach X of var lnL lnQ lnK lnQL lnKL exporter inv{
	eststo: qui areg `X' fo3 switch_ceo_exist fo3_switch_after expat_switch expat_after i.ind_year i.age_cat if expat_ceo!=.&greenfield!=1&manufacturing==1, a(frame_id ) cluster(frame_id )
}
esttab using ${data}/results_manu.rtf, b(3) se(3) r2 keep (fo3 switch_ceo_exist fo3_switch_after expat_switch expat_after _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear


*TFP
g byte lnK_ind=lnK*ind


eststo: qui areg lnQ lnL lnK lnK_ind lnM fo3 switch_ceo_exist expat_ceo_exist i.ind_year i.age_cat if !greenfield&expat_ceo!=., a(frame_id ) cluster(frame_id )
esttab using ${data}/results_tfp.rtf, b(3) se(3) r2 keep (fo3 switch_ceo_exist expat_ceo_exist _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
*esttab using ${data}/first_leed_ceo5.rtf, b(3) se(3) r2 keep (fo3 change fo3_change expat _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear


*Szelekció az akvicíziós mintában
xtset id year
eststo: qui areg f1.expat_ceo_exist lnL lnQ lnK exporter if fo3_ever==1&greenfield!=1, a(industry_year) cluster(frame_id)
esttab using ${data}/results_selection.rtf, b(3) se(3) r2 compress replace modelwidth(5) nogap
eststo clear


*Akvizíciós minta (greenfield nélkül)
keep if fo3_ever==1&greenfield!=1


*Switch_ceo dinamika (csak az fo3 utáni switch-ek bevonva)
gen switch_ceo0=0
gen switch_ceo1=0
gen switch_ceo2=0
gen switch_ceo3=0
gen switch_ceo4=0


xtset id year
replace switch_ceo0=1 if switch_ceo_number>0&switch_ceo_exist==1&fo3_switch_after==1
replace switch_ceo1=1 if l1.switch_ceo_number>0&switch_ceo_number==0&switch_ceo_exist==1&l1.fo3_switch_after==1&fo3_switch_after==1
replace switch_ceo2=1 if l2.switch_ceo_number>0&l1.switch_ceo_number==0&switch_ceo_number==0&switch_ceo_exist==1& ///
l2.fo3_switch_after==1&l1.fo3_switch_after==1&fo3_switch_after==1
replace switch_ceo3=1 if l3.switch_ceo_number>0&l2.switch_ceo_number==0&l1.switch_ceo_number==0&switch_ceo_number==0&switch_ceo_exist==1& ///
l3.fo3_switch_after==1&l2.fo3_switch_after==1&l1.fo3_switch_after==1&fo3_switch_after==1
replace switch_ceo4=1 if l4.switch_ceo_number>0&l3.switch_ceo_number==0&l2.switch_ceo_number==0&l1.switch_ceo_number==0&switch_ceo_number==0& ///
switch_ceo_exist==1&l4.fo3_switch_after==1&l3.fo3_switch_after==1&l2.fo3_switch_after==1&l1.fo3_switch_after==1&fo3_switch_after==1


*Fo3_switch dinamika (jelen helyzetben ez megegyezik a switch_ceo_exist-tel)
*például - tab fo3_switch_exist0 switch_ceo_exist0
gen fo3_switch_exist0=fo3*switch_ceo0
gen fo3_switch_exist1=fo3*switch_ceo1
gen fo3_switch_exist2=fo3*switch_ceo2
gen fo3_switch_exist3=fo3*switch_ceo3
gen fo3_switch_exist4=fo3*switch_ceo4


*Expat dinamika
gen expat_switch0=expat_ceo_exist*switch_ceo0
gen expat_switch1=expat_ceo_exist*switch_ceo1
gen expat_switch2=expat_ceo_exist*switch_ceo2
gen expat_switch3=expat_ceo_exist*switch_ceo3
gen expat_switch4=expat_ceo_exist*switch_ceo4


*Akvizíciós minta mentése
save ${data}/sample_fo, replace


*Alapmodell lefuttatása az akvizíciós mintán
foreach X of var lnL lnQ lnK lnQL lnKL exporter inv{
	eststo: qui areg `X' fo3 fo3_switch_exist expat_switch expat_after i.ind_year i.age_cat if expat_ceo!=., a(frame_id ) cluster(frame_id )
}
esttab using ${data}/results_fo.rtf, b(3) se(3) r2 keep (fo3 fo3_switch_exist expat_switch expat_after _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear


*Alapmodell lefuttatása az akvizíciós mintán dinamikával
foreach X of var lnL lnQ lnK lnQL lnKL exporter inv{
	eststo: qui areg `X' fo3 fo3_switch_exist0 fo3_switch_exist1 fo3_switch_exist2 fo3_switch_exist3 fo3_switch_exist4 expat_switch0 expat_switch1 expat_switch2 expat_switch3 expat_switch4 expat_after i.ind_year i.age_cat if expat_ceo!=., a(frame_id ) cluster(frame_id )
}
esttab using ${data}/results_dynamics.rtf, b(3) se(3) r2 keep (fo3 fo3_switch_exist0 fo3_switch_exist1 fo3_switch_exist2 fo3_switch_exist3 fo3_switch_exist4 expat_switch0 expat_switch1 expat_switch2 expat_switch3 expat_switch4 expat_after _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear
