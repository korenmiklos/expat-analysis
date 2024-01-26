*Betöltés
set more off
clear all
capture log close

* find root folder
here
local here = r(here)

log using "`here'/output/investigate", text replace

* keep only sample from balance-small - NOTE: had to restructure as we have to keep foreign which is different in years - so no collapse this time
use "`here'/temp/balance-small-clean.dta"
by frame_id_numeric: egen firm_birth = min(year)
by frame_id_numeric: egen firm_death = max(year)
keep frame_id year firm_birth firm_death foreign
tempfile sample
save `sample', replace

* count expats in do - asterisk used
use "`here'/input/ceo-panel/ceo-panel.dta", clear // QUESTION: what is owner
rename person_id manager_id
merge m:1 frame_id_numeric year using `sample', keep(match) nogen
bys frame_id_numeric: egen ever_expat = max(expat == 1)
bys frame_id_numeri: egen ever_foreign = max(foreign == 1)
egen firm_tag = tag(frame_id_numeric)
count if ever_expat == 1 & ever_foreign == 0 & firm_tag == 1

keep if ever_expat == 1 & ever_foreign == 0

bys frame_id_numeric year: egen expat_firm = max(expat)

duplicates drop frame_id_numeric year, force

tab year expat 

 
