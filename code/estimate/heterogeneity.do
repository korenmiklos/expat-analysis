clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
do "`here'/code/util/same_language.do"

generate byte Ltrade = Lexport | Limport
generate byte Dtrade = Dexport | Dimport
generate byte only_SL_manager = same_language_manager & !same_language_owner

local dummies originalid##year cc##teaor08_2d##year originalid##cc
local treatments Lowner Lboth
local options tex(frag) dec(3) nocons nonotes addtext(Firm-year FE, YES, Country-sector-year FE, YES, Firm-country FE, YES)

local fmode replace
* hazard of entering this market
reghdfe Dtrade Lonly_manager Lonly_owner Lboth if Ltrade==0, a(`dummies') cluster(originalid)
outreg2 using "`here'/output/table/heterogeneity.tex", `fmode' `options' ctitle(Baseline)
local fmode append

reghdfe Dtrade Lonly_manager Lonly_owner Lboth if Ltrade==0 & owner_org==0, a(`dummies') cluster(originalid)
outreg2 using "`here'/output/table/heterogeneity.tex", `fmode' `options' ctitle(Private owner)

reghdfe Dtrade Lonly_manager only_SL_manager same_language_owner Lonly_owner Lboth if Ltrade==0, a(`dummies') cluster(originalid)
outreg2 using "`here'/output/table/heterogeneity.tex", `fmode' `options' ctitle(Same language)

reghdfe Dtrade Lonly_manager only_SL_manager if Ltrade==0 & same_language_owner==0, a(`dummies') cluster(originalid)
outreg2 using "`here'/output/table/heterogeneity.tex", `fmode' `options' ctitle(No related owner)
