clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
keep if ever_foreign == 1

local T1 95
local T2 105

foreach X of var only_owner only_manager both {
	egen byte ever_`X' = max(`X'), by(originalid cc)
	forvalues t = `T1'/`T2' {
		generate byte `X'_`t' = (time_foreign+100==`t')*ever_`X'
	}
	* drop t as reference period
	drop `X'_100
	* winsorize
	replace `X'_`T1' = 1 if (time_foreign+100 < `T1') & ever_`X'
	replace `X'_`T2' = 1 if (time_foreign+100 > `T2') & !missing(time_foreign+100) & ever_`X'
}

local dummies originalid##year cc##year originalid##cc
local treatments only_owner_* only_manager_* both_*
local outcomes export import_capital import_material
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addstat(Mean, r(mean)) addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(originalid)
	summarize D`Y' if e(sample), meanonly
	outreg2 using "`here'/output/table/event_study.tex", `fmode' `options' ctitle(`title`sample'')
	local fmode append
}

