clear all
here
local here = r(here)

do "`here'/code/estimate/header.do"
* everyone assumed to speak the language of their own country, even if ethnic minority
replace Llanguage = 1 if Lmanager
drop if country == "XX"

do "`here'/code/create/lags.do" import_consumer

local Y1 export
local Y2 import_consumer
local Y3 import_capital
local Y4 import_material
local X Lowner Lowner_comlang Lmanager Lmanager_comlang Llanguage

label variable Lowner "Owner from same country"
label variable Lmanager "Manager from same country"

local fmode replace
forvalues i = 1/4 {
	* hazard of entering this market
	reghdfe D`Y`i'' `X' if L`Y`i''==0, a($dummies) cluster(frame_id_numeric)
	summarize D`Y`i'' if e(sample), meanonly
	outreg2 using "`here'/output/table/language.tex", `fmode' $options ctitle(`Y`i'')
	local fmode append
}


