clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
egen cc = group(country)

generate Ltrade = Lexport | Limport
generate Dtrade = Dexport | Dimport

local dummies originalid##year cc##year originalid##cc
local outcomes owner manager export import

local owner Lmanager Lexport Limport
local manager Lowner Lexport Limport
local export Lowner Lmanager Limport
local import Lowner Lmanager Lexport

local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Y in `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' ``Y'' if L`Y'==0, a(`dummies') cluster(originalid)
	outreg2 using "`here'/output/table/granger.tex", `fmode' `options' ctitle(`title`sample'')
	local fmode append
}

