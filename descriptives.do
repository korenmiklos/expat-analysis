clear all
capture log close
log using output/descriptives, text replace

use temp/firm_ceo_panel

* sample for faster graphs
set seed 7805
sample 25

ren N_total N
reshape long N_ tenure_, i(frame_id year ) j(category) string

label var N_ "Number of CEOs"
label var N "Total number of managers"
label var tenure_ "Lowest tenure"
label var category "Manager"

hist N if N <=20, disc scheme(538w)
graph export output/figure/manager_N_histogram.png, width(800) replace

hist N_ if N_ <=5, by(category ) disc scheme(538w)
graph export output/figure/CEO_N_histogram.png, width(800) replace

hist tenure_ if tenure_ <=30, by(category ) disc scheme(538w)
graph export output/figure/CEO_tenure_histogram.png, width(800) replace

log close
