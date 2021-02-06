clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
do "`here'/code/util/same_language.do"

local dummies originalid##year cc##teaor08_2d##year originalid##cc
local treatments Lowner Lmanager same_language_owner same_language_manager
local outcomes export import import_capital import_material
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addstat(Mean, r(mean)) addtext(Firm-year FE, YES, Country-sector-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(originalid)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/language.tex", `fmode' `options' 
	local fmode append
}

