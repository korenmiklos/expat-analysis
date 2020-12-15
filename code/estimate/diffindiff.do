clear all
here
local here = r(here)

use "`here'/temp/analysis_sample.dta", clear

local LHS lnQ lnL lnQL lnKL TFP_cd exporter RperK
local dummies originalid teaor08_2d##year
local treatments foreign foreign_hire has_expat
local options keep(`treatments') tex(frag) dec(3)

local fmode replace
foreach Y of var `LHS' {
	reghdfe `Y' `treatments', a(`dummies') cluster(originalid)
	outreg2 using "`here'/output/table/diffindiff.tex", `fmode' `options'
	local fmode append
}

* PPML for domestic and export sales
local fmode replace
foreach Y of var sales domestic_sales export {
	ppmlhdfe `Y' `treatments', a(`dummies') cluster(originalid)
	outreg2 using "`here'/output/table/ppml.tex", `fmode' `options'
	local fmode append
}

