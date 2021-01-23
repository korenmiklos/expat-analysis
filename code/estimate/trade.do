clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
egen cc = group(country)
generate byte both = owner & manager

local dummies originalid##year cc##year originalid##cc
local treatments owner manager both
local outcomes export import import_capital import_material
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addtext(Firm-year FE, YES, Country-year FE, YES)

local fmode replace
foreach Y of var `outcomes' {
	reghdfe `Y' `treatments', a(`dummies') cluster(originalid)
	outreg2 using "`here'/output/table/trade.tex", `fmode' `options' ctitle(`title`sample'')
	local fmode append
}

