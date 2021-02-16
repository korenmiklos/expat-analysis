clear all
here
local here = r(here)

do "`here'/code/estimate/header.do"
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

* keep only placebo cases
drop if link==4
generate Lowner_placebo = !Lowner & related_country
label variable Lowner "Owner (country)"
label variable Lmanager "Manager (country)"
label variable Lowner_comlang "(language)"
label variable Lmanager_comlang "(language)"
label variable Lowner_placebo "(placebo)"


local outcomes export import
local treatments Lowner Lowner_comlang Lowner_placebo Lmanager Lmanager_comlang

* only drop ROW here after variables have been defined
drop if country == "XX"
local fmode replace
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a($dummies) cluster(frame_id_numeric)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/placebo.tex", `fmode' $options ctitle(`Y')
	local fmode append
}
* rerun for private firms only
keep if ever_owner_org == 0 | missing(ever_owner_org)
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a($dummies) cluster(frame_id_numeric)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/placebo.tex", `fmode' $options ctitle(`Y')
	local fmode append
}
