clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear

local dummies originalid##year current_market##year originalid##current_market
local treatments Leither
local countries : char _dta[countries]
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach country in `countries' {
	preserve
	* merge all other countries
	generate byte current_market = (country=="`country'")
	keep if country == "XX" | country == "`country'"
	collapse (max) `treatments' Dexport Lexport, by(originalid current_market year) 
	* hazard of entering this market
	reghdfe Dexport `treatments' if Lexport==0, a(`dummies') cluster(originalid)
	outreg2 using "`here'/output/table/pairwise.tex", `fmode' `options' ctitle(`country')
	local fmode append
	restore
}

