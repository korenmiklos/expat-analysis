clear all
*here
local here = r(here)

use "`here'/temp/analysis_sample.dta", clear

local LHS lnQ lnQL TFP_cd lnK lnL lnKL exporter 
local dummies frame_id_numeric teaor08_2d##year
local treatments foreign foreign_hire has_expat_ceo

foreach X in `LHS' `treatments' {
	reghdfe `X', a(`dummies') resid
	predict M_`X', resid
}


collapse (mean) M_*, by(time_foreign)
label variable time_foreign "Time since foreign"
label variable M_foreign "Foreign owner"
label variable M_foreign_hire "New hire"
label variable M_has_expat "Expat manager"

line M_foreign M_lnK time_foreign, sort

graph export "`here'/output/figure/design-matrix.pdf", replace
