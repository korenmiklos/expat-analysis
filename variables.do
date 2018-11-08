clear all
capture log close
log using output/variables, text replace

*Balance sheet-tel kapcsolás
use input/balance-small/balance-sheet-1992-2016-small, clear
drop if frame_id==""

merge 1:1 frame_id year using temp/firm_ceo_panel, keep(master match)
drop _merge


egen id=group(frame_id)
xtset id year
BRK	

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


