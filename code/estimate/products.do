clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear

local dummies frame_id_numeric##year cc##year frame_id_numeric##cc
local treatments Lonly_owner Lonly_manager Lboth
local outcomes export import
local products rauch nonrauch consumer
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addstat(Mean, r(mean)) addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

keep originalid year country cc teaor08_2d `treatments' *export* *import*
do "`here'/code/create/lags.do" export_rauch export_nonrauch export_consumer import_rauch import_nonrauch import_consumer

local fmode replace
foreach Y in `outcomes' {
	foreach p in `products' {
		* hazard of entering this market
		reghdfe D`Y'_`p' `treatments' if L`Y'_`p'==0, a(`dummies') cluster(frame_id_numeric)
		summarize D`Y'_`p' if e(sample), meanonly
		outreg2 using "`here'/output/table/products.tex", `fmode' `options' ctitle(`title`sample'')
		local fmode append
	}
}

