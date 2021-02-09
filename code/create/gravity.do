clear all
here
local here = r(here)

use "`here'/input/cepii-geodist/geodist.dta"
keep iso2_o iso2_d contig comlang_ethno dist
rename iso2_d country

generate distance = ln(dist)
rename comlang_ethno comlang
drop dist

save "`here'/temp/gravity.dta", replace
