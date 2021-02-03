clear all
*here
local here = r(here)

use "`here'/temp/analysis_sample.dta", clear

local LHS lnQ lnQL TFP_cd lnK lnL lnKL exporter 
local dummies frame_id_numeric teaor08_2d##year

local treatments foreign foreign_hire has_expat
local treatments_extend foreign foreign_hire foreign_hire_insider has_expat expat_alone
local treatments_spell foreign foreign_hire_local_1 foreign_hire_expat_1 foreign_hire_local_2  foreign_hire_expat_2 foreign_hire_local_3plus foreign_hire_expat_3plus
local treatments_sequence foreign foreign_hire_local_1 foreign_hire_expat_1 foreign_hire_LL_2 foreign_hire_LE_2 foreign_hire_EL_2 foreign_hire_EE_2
local treatments_event foreign_e5-foreigne5 foreign_hire_local_1_e5-foreign_hire_expat_1e5 foreign_hire_local_2 foreign_hire_expat_2 foreign_hire_local_3plus foreign_hire_expat_3plus

local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addtext(Ind-year FE, YES, Firm FE, YES)

**********Baseline**********
local fmode replace
foreach Y of var `LHS' {
	qui reghdfe `Y' `treatments', a(`dummies') cluster(frame_id_numeric)
	outreg2 using "`here'/output/table/diffindiff_base.tex", `fmode' `options'
	local fmode append
}


********With control for manager-spell
local fmode replace
foreach Y of var `LHS' {
	qui reghdfe `Y' `treatments', a(`dummies' ceo_spell_hire) cluster(frame_id_numeric)
	outreg2 using "`here'/output/table/diffindiff_spell.tex", `fmode' `options'
	local fmode append
}

****Insiders and expat alone******
local fmode replace
foreach Y of var `LHS' {
	qui reghdfe `Y' `treatments_extend', a(`dummies') cluster(frame_id_numeric)
	outreg2 using "`here'/output/table/diffindiff_insider.tex", `fmode' `options'
	local fmode append
}

****Spell of managers******
local fmode replace
foreach Y of var `LHS' {
	qui reghdfe `Y' `treatments_spell', a(`dummies') cluster(frame_id_numeric)
	outreg2 using "`here'/output/table/diffindiff_seq1.tex", `fmode' `options'
	local fmode append
}

****Sequence of managers*******
local fmode replace
foreach Y of var `LHS' {
	qui reghdfe `Y' `treatments_sequence' if ceo_spell_foreign<3, a(`dummies') cluster(frame_id_numeric)
	outreg2 using "`here'/output/table/diffindiff_seq2.tex", `fmode' `options'
	local fmode append
}

***Event time estimation*****
local fmode replace
foreach Y of var `LHS' {
	qui reghdfe `Y' `treatments_event', a(`dummies') cluster(frame_id_numeric)
	outreg2 using "`here'/output/table/diffindiff_event.tex", `fmode' `options'
	local fmode append
}