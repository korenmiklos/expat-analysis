local fname = e(depvar)
local title : variable label `fname'

preserve
clear
set obs 5
local DD 2
local DE 3
local ED 4
local EE 5

local DD_label "domestic--domestic"
local DE_label "domestic--expat"
local ED_label "expat--domestic"
local EE_label "expat--expat"

local style1 p1
local style2 p2
local style3 p1
local style4 p2

gen x = _n
recode x 3=2 4/5=3

gen y = 0
gen str label = ""
gen diff0 = 0
gen diffD = 0

local i = 1
foreach b1 in D E {
foreach b2 in D E {
	local b `b1'`b2'

	test during_`b'
	if r(p)<0.05 {
		local width`i' thick
	}
	else {
		local width`i' medium
	}
	local i = `i'+1

	test during_`b'==during_`b1'D
	replace diffD = r(p)<0.05 if _n==``b''

	if "`b1'"=="E" {
		replace y = _b[during_DE]+_b[during_`b'] if _n==``b''
	}
	else {
		replace y = _b[during_`b'] if _n==``b''
	}
	replace label = "``b'_label'" if _n==``b''
}
}

replace label = label+" *" if diffD

gen byte line1 = inlist(_n,1,2)
gen byte line2 = inlist(_n,1,3)
gen byte line3 = inlist(_n,3,4)
gen byte line4 = inlist(_n,3,5)
local L = 4
local command ""

forval l=1/`L' {
	local style "mstyle(`style`l'') lstyle(`style`l'') mlabstyle(`style`l'') lwidth(`width`l'')"
	local command "scatter y x if line`l', connect(direct) `style' mlabposition(9) mlabgap(2) mlabel(label)  || `command'"
}

`command', scheme(538w) xlabel(none) xtitle("") ytitle(`title') legend(off) aspect(0.67)
graph export output/figure/`fname'_tree.png, width(800) replace

restore
