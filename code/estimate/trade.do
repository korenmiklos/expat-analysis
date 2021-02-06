clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
* only keep [-3,3] window around acquisition
keep if (time_foreign >= -3 & time_foreign <=3) | missing(time_foreign)

local dummies originalid##year cc##teaor08_2d##year originalid##cc
local treatments Lonly_owner Lonly_manager Lboth
local outcomes export import import_capital import_material
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addstat(Mean, r(mean)) addtext(Firm-year FE, YES, Country-sector-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(originalid)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/trade.tex", `fmode' `options' ctitle(`title`sample'')
	local fmode append
}

