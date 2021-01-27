clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
* exclude control firms
keep if ever_foreign

local dummies originalid##year cc##year originalid##cc
local treatments Lowner Lmanager
local outcomes export import import_capital import_material
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(originalid)
	outreg2 using "`here'/output/table/trade.tex", `fmode' `options' ctitle(`title`sample'')
	local fmode append
}

