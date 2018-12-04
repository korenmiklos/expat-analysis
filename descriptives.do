clear all
capture log close
log using output/descriptives, text replace

local format scheme(538w) plotregion(style(none)) xsize(16) ysize(10) aspect(.5)

use temp/firm_ceo_panel

gen spell_length = first_exit_year - enter_year + 1
label var spell_length "Length of CEO spell"
label var expat "manager nationality"
label def xp 0 "Local" 1 "Expat"
label val expat xp

egen spt = tag(frame_id manager_id)

hist spell_length if spell_length <=30 & spt, by(expat) disc `format'
graph export output/figure/CEO_tenure_histogram.png, width(1600) replace

use temp/analysis_sample, clear

label var expat "manager nationality"
label def xp 0 "Local" 1 "Expat"
label val expat xp

gen byte entrant = year==enter_year
* only count managers actually at firm
* cannot use "during" for this as that is 0 for founders
keep if year>=enter_year & year<=first_exit_year

preserve
	egen spt = tag(frame_id manager_id)
	collapse (sum) N=spt, by(DD DE ED EE)
	gen str1 from = ""
	gen str1 to = ""
	gen byte i = 1
	foreach from in D E {
	foreach to in D E {
		replace from = "`from'" if `from'`to'
		replace to = "`to'" if `from'`to'
		drop `from'`to'
	}
	}
	l
	drop if missing(from)
	drop i
	reshape wide N, i(from) j(to) string
	replace from = cond(from=="D","domestic","expat")
	ren ND to_domestic
	ren NE to_expat
	export delimited output/table/switches.csv, replace
restore

preserve
	gen byte categ = 1+expat
	replace categ = 0 if founder==1
	tab categ
	collapse (count) N=entrant, by(age categ)
	reshape wide N, i(age) j(categ)
	mvencode N*, mv(0) override
	
	egen total_N = rsum(N?)
	foreach X of var N? {
		gen `X'_share = 100*`X'/total_N
	}
	replace N1_share = N2_share+N1_share
	replace N0_share = 100
	label var age "Firm age (year)"
	tw (area N0_share N1_share N2_share age if age<=20, fintensity(inten20 inten20 inten20) ),  `format' legend(order(1 "Founder" 2 "New local" 3 "New expat")) 
	graph export output/figure/CEO_type_by_age.png, width(1600) replace
restore

collapse (count) N=entrant (sum) entrant (firstnm) age, by(frame_id year expat)
reshape wide N entrant, i(frame_id year) j(expat)
reshape long

mvencode N entrant, mv(0) override

egen total_N = sum(N), by(frame_id year)

label var N "Number of CEOs"
label var total_N "Number of CEOs"

hist total_N, disc `format'
graph export output/figure/CEO_N_histogram.png, width(1600) replace

hist N if N <=5, by(expat ) disc `format'
graph export output/figure/CEO_N_histogram_by.png, width(1600) replace

* only count one CEO per firm
replace N=1 if N>1
replace entrant=1 if entrant>1

reshape wide
collapse (sum) N0 N1 entrant0 entrant1 total_N, by(year)

foreach X of var N1 entrant1 entrant0 {
	gen `X'_share = `X'/total_N*100
}

line N1_share entrant0_share entrant1_share year, sort lwidth(thick thick thick) `format' ytitle("Share of firms (%)") legend(order(1 "Expat CEO" 2 "New local CEO" 3 "New expat CEO"))
graph export output/figure/shares_over_time.png, width(1600) replace

log close
