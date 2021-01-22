clear all
here
local here = r(here)

use "`here'/temp/analysis_sample.dta", clear

local main lnL lnQL TFP_cd RperK
local trade export_same_country import_capital_same_country import_material_same_country export_other_country import_capital_other_country import_material_other_country

local dummies originalid teaor08_2d##year
local treatments foreign foreign_hire has_expat country_same
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addtext(Ind-year FE, YES, Firm FE, YES)

foreach table in main trade {
	local fmode replace
	foreach Y of var ``table'' {
		reghdfe `Y' `treatments', a(`dummies') cluster(originalid)
		outreg2 using "`here'/output/table/diffindiff_`table'.tex", `fmode' `options'
		local fmode append
	}
}

