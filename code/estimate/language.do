clear all
here
local here = r(here)

do "`here'/code/estimate/header.do"

egen other_language = max(Llanguage), by(frame_id_numeric year)
egen ever_language = max(Llanguage), by(frame_id_numeric)
* immigrants might have different effect
generate byte immigrant = Lmanager & !Llanguage & other_language
* everyone assumed to speak the language of their own country, even if ethnic minority
replace Llanguage = 1 if Lmanager
replace Lmanager_comlang = 1 if Lmanager
replace Lowner_comlang = 1 if Lowner
drop if country == "XX"
keep if ever_language | !ever_foreign_hire

do "`here'/code/create/lags.do" import_consumer export_rauch export_nonrauch import_rauch import_nonrauch

local outcomes export import_consumer import_capital import_material
local X Lowner Lowner_comlang Lmanager Lmanager_comlang Llanguage immigrant

label variable Lowner "Owner (country)"
label variable Lmanager "Manager (country)"
label variable Lowner_comlang "(language)"
label variable Lmanager_comlang "(language)"
label variable Llanguage "(ethnicity)"

local fmode replace
foreach Y in `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `X' if L`Y'==0, a($dummies) cluster(frame_id_numeric)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/language.tex", `fmode' $options ctitle(`Y')
	local fmode append
}


