clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
drop if country == "XX"

local dummies frame_id_numeric##year cc##year frame_id_numeric##cc
local treatments Lonly_owner Lonly_manager Lboth
local outcomes export import
local products rauch nonrauch consumer
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addstat(Mean, r(mean)) addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

keep frame_id_numeric year country cc teaor08_2d `treatments' *export* *import*
do "`here'/code/create/lags.do" export_rauch export_nonrauch export_consumer import_rauch import_nonrauch import_consumer

local fmode replace
foreach Y in `outcomes' {
	foreach p in `products' {
		* hazard of entering this market
		reghdfe D`Y'_`p' `treatments' if L`Y'_`p'==0, a(`dummies') cluster(frame_id_numeric)
		estimates store `Y'_`p'
		summarize D`Y'_`p' if e(sample), meanonly
		outreg2 using "`here'/output/table/products.tex", `fmode' `options' ctitle(`title`sample'')
		local fmode append
	}
}

coefplot export_rauch, bylabel("Export - rauch") || export_nonrauch, bylabel("Export - nonrauch") || export_consumer, bylabel("Export - consumer") || import_rauch, bylabel("Import - rauch") || import_nonrauch, bylabel("Import - nonrauch") || import_consumer, bylabel("Import - consumer") ||,  drop(_cons) coeflabel(Lonly_owner = "Only owner" Lonly_manager = "Only manager" Lboth = "Both") xline(0, lcolor(black) lpattern(dash)) subtitle(, lcolor(white) fcolor(white)) levels(95) xlabel(0(0.05)0.25) byopts(graphregion(col(white)) bgcol(white) title("Products", color(black)))

graph export "`here'/output/figure/coefplot_products.png", replace
