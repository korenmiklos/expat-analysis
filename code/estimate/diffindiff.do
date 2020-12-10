clear all
here
local here = r(here)

use "`here'/temp/analysis_sample.dta", clear

local LHS lnL lnQL lnKL TFP_cd exporter RperK
local dummies originalid teaor08_2d##year

local fmode replace
foreach Y of var `LHS' {
	reghdfe `Y' foreign foreign_hire has_expat country_same, a(`dummies') cluster(originalid)
	outreg2 using "`here'/output/table/diffindiff.tex", `fmode' `options'
	local fmode append
}

