clear all
here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
keep if Lowner | Lmanager

keep frame_id_numeric country year Lowner Lmanager
reshape wide Lowner Lmanager, i(frame_id_numeric year) j(country) string
reshape long Lowner, i(frame_id_numeric year) j(country) string

keep if Lowner == 1
collapse (sum) Lmanager??, by(country)
rename country owner
reshape long Lmanager, i(owner) j(manager) string
* common pairings of owners and managers
keep if (Lmanager >= 50) & (manager != "XX") & (owner != "XX") & (owner != manager)

/*
o	AT	CH	DE	FR	GB	IT
AT			274			
CH	122		234			
DE	428	105		55	54	
FR	72					
NL	136		102	53	103	50
US	127		216		96	
*/
