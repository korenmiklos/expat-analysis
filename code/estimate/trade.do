clear all
here
local here = r(here)

do "`here'/code/estimate/header.do"
drop if country == "XX"

local Y1 export
local Y2 import
local Y3 `Y1'
local Y4 `Y2'
local X1 Lowner Lmanager
local X2 `X1'
local X3 Lonly_owner Lonly_manager Lboth
local X4 `X3'

local fmode replace
forvalues i = 1/4 {
	* hazard of entering this market
	reghdfe `Y`i'' `X`i'', a($dummies) cluster(frame_id_numeric)
	summarize `Y`i'' if e(sample), meanonly
	outreg2 using "`here'/output/table/trade.tex", `fmode' $options ctitle(`Y`i'')
	local fmode append
}

