* assume attgt estimate with aggregate(e) option has been recently produced
preserve
clear

local Z 1.96

local T = colsof(e(b)) 
local T1 = `T' + 1
set obs `T1'

generate b = 0
generate t = 0
generate upper = 0
generate lower = 0

local colnames : colnames e(b)
local outcome : coleq e(b)
local outcome : word 1 of `outcome'
local treatment : word 3 of `e(cmdline)'

forvalues i = 1/`T' {
    * get event time index
    local name : word `i' of `colnames'
    replace t = real(subinstr(subinstr("`name'", "event_", "", .), "m", "-", .)) in `i'
    * get estimates from regression
    replace b = e(b)[1, `i'] in `i'
    replace upper = b + `Z' * sqrt(e(V)[`i', `i']) in `i'
    replace lower = b - `Z' * sqrt(e(V)[`i', `i']) in `i'
}
sort t

twoway (rarea lower upper t, fcolor(blue%30) lwidth(none)) ///
    (line b t, lcolor(blue)), ///
    ytitle("`outcome'") xtitle("Year of `treatment'") ///
    graphregion(color(white)) legend(off)

list
restore