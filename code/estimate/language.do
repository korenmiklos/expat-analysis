clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
generate byte Lmanager_HUN = (has_expat==0) & (Lmanager==1)
drop if country == "XX"

local dummies frame_id_numeric##year cc##year frame_id_numeric##cc
local treatments Lowner Lmanager Lowner_comlang Lmanager_comlang Lmanager_HUN
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

