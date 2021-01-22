clear all

local countries DE AT CH NL FR GB IT US
local variables export import import_capital import_material

* find root folder
here
local here = r(here)

* load PPI for deflate
tempfile ppi
use "`here'/temp/balance-small-clean.dta"
keep originalid year ppi18
keep if !missing(ppi18)
save `ppi', replace

use "`here'/input/trade-firm-panel/trade-country-firm.dta", clear
merge m:1 originalid year using `ppi', keep(match) nogenerate

foreach X of var `variables' {
	* create dummy if greater than 1m Ft
	replace `X' = cond(`X' >= ppi18 * 1e+6, 1, 0)
}
compress

* keep only designated countries
tempvar keep
generate byte `keep' = 0
foreach cnt in `countries' {
	replace `keep' = 1 if country == "`cnt'"
}
replace country = "XX" if `keep' == 0
drop `keep'

collapse (max) `variables', by(originalid country year)
reshape wide `variables', i(originalid year) j(country) string
reshape long
mvencode `variables', mv(0) override
reshape wide

foreach X in `variables' {
	egen `X' = rowmax(`X'??)
}
compress

save "temp/trade.dta", replace
