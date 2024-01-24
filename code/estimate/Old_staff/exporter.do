clear all
here
local here = r(here)

use "`here'/temp/analysis_sample.dta", clear

local dummies originalid teaor08_2d##year
local treatments foreign foreign_hire has_expat
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addtext(Ind-year FE, YES, Firm FE, YES)

local sample1 L.exporter == 0 
local sample2 L.exporter == 1
local title1 "Start"
local title2 "Continue"

xtset originalid year

local fmode replace
forvalues sample = 1/2 {
	reghdfe exporter `treatments' if `sample`sample'', a(`dummies') cluster(originalid)
	outreg2 using "`here'/output/table/exporter.tex", `fmode' `options' ctitle(`title`sample'')
	local fmode append
}

