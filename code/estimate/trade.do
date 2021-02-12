clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
drop if country == "XX"

local dummies frame_id_numeric##year cc##year frame_id_numeric##cc
local outcomes export import 
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addstat(Mean, r(mean)) addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' Lowner Lmanager if L`Y'==0, a(`dummies') cluster(frame_id_numeric)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/trade.tex", `fmode' `options' ctitle(`title`sample'')
	local fmode append

	reghdfe D`Y' Lowner owner Lmanager manager `treatments' if L`Y'==0, a(`dummies') cluster(frame_id_numeric)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/trade.tex", `fmode' `options' ctitle(`title`sample'')
}

