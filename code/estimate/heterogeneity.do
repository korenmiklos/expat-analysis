clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear

generate byte Ltrade = Lexport | Limport
generate byte Dtrade = Dexport | Dimport

egen ever_sc_hire = max(both), by(frame_id_numeric)
egen ever_owner_org = max(owner_org), by(frame_id_numeric)

* five types of firms
generate byte link = 0
replace link = 1 if ever_foreign
replace link = 2 if ever_foreign_hire
replace link = 3 if ever_expat
replace link = 4 if ever_sc_hire

tabulate link ever_foreign_hire

* estimate separate same country and same language effects for each type
forvalues i = 1/4 {
	generate byte owner_country_`i' = (Lowner==1) & (link==`i')
}
generate byte manager_country_3 = (Lmanager==1) & (link==3) & !owner_country_3

local dummies frame_id_numeric##year cc##year frame_id_numeric##cc
local outcomes export import
local treatments *er_country_? 
local options tex(frag) dec(3) nocons nonotes addstat(Mean, r(mean)) addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(frame_id_numeric)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/heterogeneity.tex", `fmode' `options'
	local fmode append
}
* rerun for private firms only
keep if ever_owner_org == 0 | missing(ever_owner_org)
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(frame_id_numeric)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/heterogeneity.tex", `fmode' `options'
	local fmode append
}
