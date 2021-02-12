clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear

generate byte Ltrade = Lexport | Limport
generate byte Dtrade = Dexport | Dimport

egen ever_foreign_owned = max(foreign | ever_foreign | Lowner), by(frame_id_numeric)
egen ever_sc_hire = max(both), by(frame_id_numeric)
egen ever_owner_org = max(owner_org), by(frame_id_numeric)
do "`here'/code/estimate/country_pairs.do"

* five types of firms
generate byte link = 0
replace link = 1 if ever_foreign_owned
replace link = 2 if ever_foreign_hire
replace link = 3 if ever_expat
replace link = 4 if ever_sc_hire

tabulate link ever_foreign_hire

* estimate separate same country and related effects for each type
forvalues i = 1/4 {
	generate byte owner_country_`i' = (Lowner==1) & (link==`i')
	generate byte owner_related_`i' = (Lowner!=1) & (link==`i') & (related_country==1)
}
generate byte manager_unrelated_3 = (Lmanager==1) & (link==3) & !owner_related_3
generate byte manager_related_3 = (Lmanager==1) & (link==3) & !owner_country_3 & owner_related_3

local dummies frame_id_numeric##year cc##year frame_id_numeric##cc
local outcomes export import
local treatments owner_country_? owner_related_? manager_related_3 manager_unrelated_3
local options tex(frag) dec(3) nocons nonotes addstat(Mean, r(mean)) addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

* only drop ROW here after variables have been defined
drop if country == "XX"
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
