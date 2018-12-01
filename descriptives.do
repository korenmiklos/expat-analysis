clear all
capture log close
log using output/descriptives, text replace

use temp/firm_ceo_panel

gen spell_length = first_exit_year-enter_year+1
label var spell_length "Length of CEO spell"
label var expat "manager nationality"
label def xp 0 "Local" 1 "Expat"
label val expat xp

hist spell_length if spell_length <=30 & founder==0, by(expat ) disc scheme(538w)
graph export output/figure/CEO_tenure_histogram.png, width(800) replace

use temp/analysis_sample, clear

gen byte entrant = year==enter_year
collapse (count) N=entrant (sum) entrant, by(frame_id year expat)
reshape wide N entrant, i(frame_id year) j(expat)
reshape long

mvencode N entrant, mv(0) override

egen total_N = sum(N), by(frame_id year)

label var N "Number of CEOs"
label var total_N "Number of CEOs"
label var expat "manager nationality"
label def xp 0 "Local" 1 "Expat"
label val expat xp

hist total_N, disc scheme(538w)
graph export output/figure/CEO_N_histogram.png, width(800) replace

hist N if N <=5, by(expat ) disc scheme(538w)
graph export output/figure/CEO_N_histogram_by.png, width(800) replace

reshape wide
collapse (sum) N0 N1 entrant0 entrant1 total_N, by(year)

foreach X of var N1 entrant0 entrant1 {
	gen `X'_share = `X'/total_N*100
}

line N1_share entrant0_share entrant1_share year, sort scheme(538w) ytitle("Share of CEOs (%)") legend(order(1 "Expat" 2 "New local" 3 "New expat"))
graph export output/figure/shares_over_time.png, width(800) replace

log close
