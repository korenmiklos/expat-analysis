clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear

* does firm have owner/manager from German/English speaking country?
local languages English German French Spanish Italian Russian
foreach role in owner manager {
	generate byte same_language_`role' = 0
	foreach language in `languages' {
		egen byte `language'_`role' = max(L`role' * `language'), by(originalid year)
		* German knowledge should only matter in German-speaking markets
		replace same_language_`role' = 1 if `language' & `language'_`role'
		drop `language'_`role'
	}
}

local dummies originalid##year cc##teaor08_2d##year originalid##cc
local treatments Lowner Lmanager same_language_owner same_language_manager
local outcomes export import import_capital import_material
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addtext(Firm-year FE, YES, Country-sector-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(originalid)
	outreg2 using "`here'/output/table/language.tex", `fmode' `options' 
	local fmode append
}

