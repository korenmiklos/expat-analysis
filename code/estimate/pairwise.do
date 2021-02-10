clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear

local dummies frame_id_numeric##year current_market##year frame_id_numeric##current_market
local treatments Leither
local countries : char _dta[countries]
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addstat(Mean, r(mean)) addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach country in `countries' {
	preserve
	* merge all other countries
	generate byte current_market = (country=="`country'")
	keep if country == "XX" | country == "`country'"
	collapse (max) `treatments' Dexport Lexport, by(frame_id_numeric current_market year) 
	* hazard of entering this market
	reghdfe Dexport `treatments' if Lexport==0, a(`dummies') cluster(frame_id_numeric)
	summarize Dexport if e(sample), meanonly
	outreg2 using "`here'/output/table/pairwise.tex", `fmode' `options' ctitle(`country')
	local fmode append
	restore
}

