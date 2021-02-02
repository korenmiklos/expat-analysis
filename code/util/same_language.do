* does firm have owner/manager from German/English speaking country?
local languages English German French Spanish Italian Russian
foreach role in owner manager {
	generate byte same_language_`role' = 0
	foreach language in `languages' {
		egen byte `language'_`role' = max(L`role' * `language'), by(originalid year)
		* German knowledge should only matter in German-speaking markets
		replace same_language_`role' = 1 if `language' & `language'_`role'
		drop `language'_`role'
	}
}
