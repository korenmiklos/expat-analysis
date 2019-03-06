use temp/analysis_sample, clear

preserve
use input/balance-small/leed86108_30May2011, clear
recode year (86=1986) (89=1989) (92=1992) (93=1993) (94=1994) (95=1995) (96=1996) (97=1997) (98=1998) (99=1999) ///
(0100=2000) (0101=2001) (0102=2002) (0103=2003) (0104=2004) (0105=2005) (0106=2006) (0107=2007) (0108=2008)
tempfile leed
save `leed'
restore

gen id8=substr(frame_id,3,8)
destring id8, replace

scalar Tbefore = 4
scalar Tduring = 6
scalar Tafter = 4
gen byte analysis_window = (tenure>=-Tbefore-1)&(year-first_exit_year<=Tafter)
keep if analysis_window==1

merge m:m id8 year using `leed', nogen keep(master match)

save temp/analysis_sample_bertarifa, replace
