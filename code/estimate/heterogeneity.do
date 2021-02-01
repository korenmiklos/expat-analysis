clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
generate byte Ltrade = Lexport | Limport
generate byte Dtrade = Dexport | Dimport

local dummies originalid##year cc##year originalid##cc
local interactions ever_foreign_hire ever_expat
local treatments Lowner Lboth
local options tex(frag) dec(3) nocons nonotes addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Z of var `interactions' {
	generate byte `Z'_owner = `Z' * Lowner
}
foreach Z of var `interactions' {
	* hazard of entering this market
	reghdfe Dtrade `treatments' `Z'_* if Ltrade==0, a(`dummies') cluster(originalid)
	outreg2 using "`here'/output/table/heterogeneity.tex", `fmode' `options' ctitle(`title`sample'')
	local fmode append
}

