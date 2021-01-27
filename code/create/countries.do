local countries DE AT CH NL FR GB IT US BE CZ DK ES FI IL PL RO RU SE SK UA BG GR HR SI 
char _dta[countries] `countries'

foreach country in `countries' `offshore' {
	generate byte owner`country' = (strpos(country_all_owner, "`country'") > 0) & !missing(country_all_owner)
	generate byte manager`country' = (strpos(country_all_manager, "`country'") > 0) & !missing(country_all_manager)
}
tempvar knownowner knownmanager
egen `knownowner' = rowmax(owner??)
egen `knownmanager' = rowmax(manager??)

generate byte ownerXX = foreign & !`knownowner'
generate byte managerXX = has_expat & !`knownmanager'

drop `knownowner' `knownmanager'
