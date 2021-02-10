clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
drop if country == "XX"

local dummies frame_id_numeric##year cc##year frame_id_numeric##cc
local treatments Lowner* Lmanager* 
local outcomes export import 
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

keep `treatments' ?export ?import frame_id_numeric cc year 

local fmode replace
foreach Y in `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(frame_id_numeric)
	outreg2 using "`here'/output/table/gravity.tex", `fmode' `options' ctitle(`title`sample'')
	local fmode append
}

