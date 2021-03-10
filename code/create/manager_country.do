clear all
here
local here = r(here)
use "`here'/input/ceo-panel/ceo-panel.dta", clear

rename person_id manager_id

* same manager with multiple countries changed to mode country
tab country_code expat, missing
bys frame_id_numeric manager_id: egen country_code_fill = mode(country_code), minmode
tab country_code_fill expat, missing

* same manager with multiple countries changed to mode country
bys manager_id: egen country_code_fill_manager = mode(country_code), minmode
tab country_code_fill_manager expat, missing

* propagate country code for known names
replace country_code = country_code_fill if missing(country_code) & !missing(country_code_fill)
replace country_code = country_code_fill_manager if missing(country_code) & !missing(country_code_fill_manager)

drop if missing(country_code)
* merge some easy-to-mix languages
replace iso639 = "sk" if iso639 == "cs"
replace iso639 = "ru" if inlist(iso639, "bg", "uk", "sq")
replace iso639 = "sr" if inlist(iso639, "hr")
replace iso639 = "sv" if inlist(iso639, "no")
replace iso639 = "vi" if inlist(iso639, "th")
* flag non-expats as hungarian
replace iso639 = "hu" if expat == 0
* NB: remove country-related languages
levelsof iso639
local languages = r(levels)
foreach lang in `languages' {
	* add language inferred from name
	generate byte cnt_`lang' = (iso639 == "`lang'")
}

collapse (max) expat cnt_??, by(frame_id_numeric year country_code)
drop expat

* convert YU country codes
do "`here'/code/util/yugoslavia.do"

* adding all language codes for one firm-year into one variable
generate str language_list = ""
foreach language of var cnt_?? {
	local lng = substr("`language'", 5, 2)
	display "`lng'"
	tempvar cnt
	egen `cnt' = max(`language'), by(frame_id_numeric year)
	replace language_list = language_list + "`lng'," if `cnt' == 1
	drop `cnt'
}

* adding all country codes for one firm-year into one variable
generate str country_list = ""
levelsof country_code
local countries = r(levels)
foreach country in `countries' {
	display "`country'"
	tempvar cnt
	egen `cnt' = max(country_code == "`country'"), by(frame_id_numeric year)
	replace country_list = country_list + "`country'," if `cnt' == 1
	drop `cnt'
}
bysort frame_id_numeric year: generate keep = (_n==1)
keep if keep
keep frame_id_numeric year country_list language_list

compress
save "`here'/temp/manager_country.dta", replace
