clear all
here
local here = r(here)

do "`here'/code/estimate/header.do"
drop if country == "XX"

label variable Lowner "Owner (same country)"
label variable Lowner_contig  "  neighbor country"
label variable Lowner_comlang "  common languange"
label variable Lmanager "Manager (same country)"
label variable Lmanager_contig  "  neighbor country"
label variable Lmanager_comlang "  common languange"

local outcomes export import 
local treatments Lowner Lowner_contig Lowner_comlang Lmanager Lmanager_contig Lmanager_comlang

keep `treatments' ?export ?import frame_id_numeric cc year 

local fmode replace
foreach Y in `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a($dummies) cluster(frame_id_numeric)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/gravity.tex", `fmode' $options ctitle(`Y')
	local fmode append
}

