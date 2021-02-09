clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear

generate byte Ltrade = Lexport | Limport
generate byte Dtrade = Dexport | Dimport

egen ever_sl_hire = max(owner_comlang & manager_comlang), by(originalid)
egen ever_sc_hire = max(both), by(originalid)

* five types of firms
generate byte link = 0
replace link = 1 if ever_foreign
replace link = 2 if ever_foreign_hire
replace link = 3 if ever_expat
replace link = 4 if ever_sl_hire
replace link = 5 if ever_sc_hire

tabulate link ever_foreign_hire

* estimate separate same country and same language effects for each type
forvalues i = 1/5 {
	generate byte owner_country_`i' = (Lowner==1) & (link==`i')
	generate byte owner_language_`i' = (Lowner_comlang==1) & (link==`i') & !owner_country_`i'
}
generate byte manager_country_3 = (Lmanager==1) & (link==3) & !owner_country_3
generate byte manager_language_3 = (Lmanager_comlang==1) & (link==3) & !manager_country_3 & !owner_language_3
generate byte manager_country_4 = (Lmanager==1) & (link==4) & !owner_country_4

local dummies originalid##year cc##teaor08_2d##year originalid##cc
local outcomes export import
local treatments *er_country_? *er_language_? 
local options tex(frag) dec(3) nocons nonotes addstat(Mean, r(mean)) addtext(Firm-year FE, YES, Country-sector-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(originalid)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/heterogeneity.tex", `fmode' `options'
	local fmode append
}
* rerun for private firms only
keep if owner_org == 0
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(originalid)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/heterogeneity.tex", `fmode' `options'
	local fmode append
}
