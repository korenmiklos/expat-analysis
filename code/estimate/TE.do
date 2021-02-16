clear all
here
local here = r(here)

do "`here'/code/estimate/header.do"
drop if country == "XX"

generate byte Dtrade = Dexport | Dimport
generate byte Ltrade = Lexport | Limport

generate str oc = ""
local countries : char _dta[countries]
foreach cnt in `countries' {
	egen cnt = max(owner & (country=="`cnt'")), by(frame_id_numeric)
	replace oc = "`cnt'" if cnt == 1
	drop cnt
}

drop if missing(oc)

generate TE_owner = .
generate TE_manager = .
foreach cnt in `countries' {
	reghdfe Dtrade Lowner Lmanager if Ltrade==0 & oc=="`cnt'", a(frame_id_numeric##year cc#frame_id_numeric)
	replace TE_owner = _b[Lowner] if oc=="`cnt'"
	replace TE_manager = _b[Lmanager] if oc=="`cnt'"
}
label variable TE_owner "Owner effect"
label variable TE_manager "Manager effect"

foreach X in owner manager {
	histogram TE_`X', graphregion(color(white)) color(red%30)
	graph export "`here'/output/figure/TE_`X'.png", replace
}
