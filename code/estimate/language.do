clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
generate byte Lmanager_HUN = ((has_expat==0) | (strpos(lang_all_manager, "hu")>0)) & (Lmanager==1)
* everyone assumed to speak the language of their own country, even if ethnic minority
replace Llanguage = 1 if Lmanager
drop if country == "XX"

local dummies frame_id_numeric##year cc##year frame_id_numeric##cc
local treatments Lowner Lmanager Lowner_comlang Lmanager_comlang Llanguage
local outcomes export import import_capital import_material
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addstat(Mean, r(mean)) addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(frame_id_numeric)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/language.tex", `fmode' `options' 
	local fmode append
}

