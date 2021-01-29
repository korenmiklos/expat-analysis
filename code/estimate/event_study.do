clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
keep if ever_foreign == 1

local T1 95
local T2 105

foreach X of var only_owner only_manager both {
	egen int ft_`X' = min(cond(`X', year, .)), by(originalid cc)
	generate et_`X' = 100 + year - ft_`X'
	forvalues t = `T1'/`T2' {
		generate byte `X'_`t' = (et_`X'==`t')
	}
	* drop t-1 as reference period
	drop `X'_99
	* winsorize
	replace `X'_`T1' = 1 if (et_`X' < `T1')
	replace `X'_`T2' = 1 if (et_`X' > `T2') & !missing(et_`X')
	drop ft_* et_*
}

local dummies originalid##year cc##year originalid##cc
local treatments only_owner_* only_manager_* both_*
local outcomes export import_capital import_material
local options keep(`treatments') tex(frag) dec(3)  nocons nonotes addtext(Firm-year FE, YES, Country-year FE, YES, Firm-country FE, YES)

local fmode replace
foreach Y of var `outcomes' {
	* hazard of entering this market
	reghdfe D`Y' `treatments' if L`Y'==0, a(`dummies') cluster(originalid)
	outreg2 using "`here'/output/table/event_study.tex", `fmode' `options' ctitle(`title`sample'')
	local fmode append
}

