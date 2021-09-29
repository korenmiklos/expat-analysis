* assume attgt estimate with aggregate(e) option has been recently produced
preserve
clear

local Z 1.96

local T = colsof(e(b)) 
set obs `T'

generate str outcome = ""
generate b = 0
generate t = 0
generate upper = 0
generate lower = 0

local colnames : colnames e(b)
local outcomes : coleq e(b)
* FIXME: get treatment var from ereturn
local treatment : word 3 of `e(cmdline)'

forvalues i = 1/`T' {
    * get event time index
    local name : word `i' of `colnames'
    local outcome : word `i' of `outcomes'
    replace outcome = "`outcome'" in `i'
    replace t = real(subinstr(subinstr("`name'", "event_", "", .), "m", "-", .)) in `i'
    * get estimates from regression
    replace b = e(b)[1, `i'] in `i'
    replace upper = b + `Z' * sqrt(e(V)[`i', `i']) in `i'
    replace lower = b - `Z' * sqrt(e(V)[`i', `i']) in `i'
}
* create period 0 for every outcome
expand 1+(t==1), generate(expanded)
foreach X in t b upper lower {
    replace `X' = 0 if expanded
}
sort outcome t

levelsof outcome, local(outcomes)
foreach X in `outcomes' {
    twoway (rarea lower upper t if outcome=="`X'", fcolor(blue%30) lwidth(none)) ///
        (line b t if outcome=="`X'", lcolor(blue)), ///
        ytitle("`X'") xtitle("Year of `treatment'") ///
        graphregion(color(white)) legend(off)
    graph rename `X'
}
restore