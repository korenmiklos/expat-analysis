program define slopegraph
syntax, from(string) to(string) [style(string) width_test(string) star_test(string) label(string) format(string asis)]

local N2 : word count `from'
local N = `N2'/2

preserve
clear
set obs `N2'

gen x = .
gen y = .
gen str label = ""
local lines ""
forval n=1/`N' {
	local n2 = 2*(`n'-1)+1
	local n21 = 2*`n'
	local X1 : word `n2' of `from'
	local Y1 : word `n21' of `from'
	local X2 : word `n2' of `to'
	local Y2 : word `n21' of `to'

	replace x = `X1' if _n==`n2'
	replace y = `Y1' if _n==`n2'
	replace x = `X2' if _n==`n21'
	replace y = `Y2' if _n==`n21'

	local sty : word `n' of `style'
	local lbl : word `n' of `label'

	replace label = "`lbl'" if _n==`n21'

	if "`width_test'"!="" {
		local test : word `n' of `width_test'
		test `test'
		if r(p)<0.05 {
			local width thick
		}
		else {
			local width medium
		}
	}
	if "`star_test'"!="" {
		local test : word `n' of `star_test'
		test `test'
		if r(p)<0.05 {
			replace label = label + " *" if _n==`n21'
		}
	}

	local lines "scatter y x if (_n==`n2')|(_n==`n21'), connect(direct) mstyle(`sty') lstyle(`sty') lwidth(`width') mlabstyle(`sty') mlabposition(10) mlabgap(2) mlabel(label) || `lines'"
}
local fmt = `" `format' "'
`lines', `fmt'

restore

end
