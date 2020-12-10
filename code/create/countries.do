local countries DE AT CH NL FR GB IT US
local offshore LU MT CY SC

foreach country in `countries' `offshore'{
	generate byte `country' = (strpos(country_all_owner, "`country'") > 0) & !missing(country_all_owner)
}
generate offshore = 0
foreach country in `offshore' {
	replace offshore = offshore | `country'
}
drop `offshore'
