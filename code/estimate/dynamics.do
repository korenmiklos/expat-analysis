clear all
here
local here = r(here)

do "`here'/code/estimate/header.do"
drop if country == "XX"

egen first_foreign_ceo = min(cond(foreign,ceo_spell,.)), by(frame_id_numeric)
generate byte owner_exit = Lowner & !owner
generate byte manager_exit = Lmanager & !manager
label variable owner_exit "Owner left"
label variable manager_exit "Manager left"

local Y1 export
local Y2 import
local Y3 `Y1'
local Y4 `Y2'

local X1 Lowner Lmanager
local X2 `X1'
local X3 Lowner owner_exit Lmanager manager_exit
local X4 `X3'

local sample1 (ceo_spell <= first_foreign_ceo)
local sample2 `sample1'
local sample3 1
local sample4 1

local label1 "First CEO"
local label2 `label1'
local label3 "Exit"
local label4 `label3'

local fmode replace
forvalues i = 1/4 {
	* hazard of entering this market
	reghdfe D`Y`i'' `X`i'' if L`Y`i''==0 & `sample`i'', a($dummies) cluster(frame_id_numeric)
	summarize D`Y`i'' if e(sample), meanonly
	outreg2 using "`here'/output/table/dynamics.tex", `fmode' $options ctitle(`label`i'')
	local fmode append
}

