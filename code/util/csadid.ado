program csadid, eclass
	syntax varlist [if] [in], treatment(varname) [absorb(varlist)]
	marksample touse
	** First determine outcome and xvars
	gettoken y xvar:varlist	
	* read panel structure
	xtset
	local i = r(panelvar)
	local time = r(timevar)
	markout `touse' `i' `time' `treatment'

	tempvar group post tr
	tempname b v
	quietly egen `group' = min(cond(`treatment', `time'-1, .)), by(`i')
	
	* build fixed effects to include
	* user fixed effects have to be interacted with `post'
	local a i
	if ("`absorb'"!="") {
		foreach word in `absorb' {
			local a "`a' `post'##`word'"
		}
	}
	else {
		local a `i' `post'
	}

	* estimate ATT(g,t) as eq 2.6 in https://pedrohcgs.github.io/files/Callaway_SantAnna_2020.pdf
	quietly levelsof `group' if `touse', local(gs)
	quietly levelsof `time' if `touse', local(ts)

	quietly generate byte `post' = .
	quietly generate byte `tr' = .

	foreach g in `gs' {
		foreach t in `ts' {
			quietly replace `post' = (`time' == `t')
			quietly replace `tr' = (`group'==`g') & `post'
			if (`g'!=`t') {
				*display "Group: `g', time: `t'"
				capture reghdfe `y' `tr' `xvar' ///
					if `touse' & ((`group'==`g') ///
						| missing(`group')) ///
						& inlist(`time', `g', `t') ///
						, absorb(`a')
				if (_rc==0) {
					matrix `b' = nullmat(`b'), e(b)[1,1]
					matrix `v' = nullmat(`v'), e(V)[1,1]
					mata: st_local("leadlag", lead_lag(`g', `t'))
					local eqname `eqname' g`g'
					local colname `colname'  `leadlag'.`treatment'
				}
			}
		}
	}
	matrix `v' = diag(`v')
	matrix colname `b' = `colname'
	matrix coleq   `b' = `eqname'
	matrix colname `v' = `colname'
	matrix coleq   `v' = `eqname'
	matrix rowname `v' = `colname'
	matrix roweq   `v' = `eqname'

	ereturn post `b' `v'
	ereturn local cmd csadid
	ereturn local cmdline csadid `0'
	display "Callaway Sant'Anna (2021)"
	ereturn display

end

mata:
string scalar lead_lag(real scalar g, real scalar t)
{
	if (t > g) {
		return("F" + strofreal(t - g))
	}
	else {
		return("L" + strofreal(g - t))
	}
}
end