local vars `1' `2' `3' `4' `5' `6' `7' `8' `9' `10' `11' `12' `13' `14' `15' `16' `17'

tempvar first_yes
foreach X of var `vars' {
	egen `first_yes' = min(cond(`X'==1, year, .)), by(originalid country)
	* if dummy never turns on, LX is always 0
	generate byte L`X' = (year > `first_yes')
	generate byte D`X' = (year == `first_yes')
	drop `first_yes'
}
