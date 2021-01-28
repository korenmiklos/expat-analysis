clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear

* does firm have owner/manager from German/English speaking country?
foreach role in owner manager {
	foreach language in German English {
		egen byte `language'_`role' = max(L`role' * `language'), by(originalid year)
		* German knowledge should only matter in German-speaking markets
		replace `language'_`role' = 0 if `language' == 0
	}
}

local dummies originalid##year cc##year originalid##cc
local treatments Lowner Lmanager German_owner German_manager English_owner English_manager
local outcomes export import import_capital import_material
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(originalid)
	outreg2 using "`here'/output/table/language.tex", `fmode' `options' 
	local fmode append
}

