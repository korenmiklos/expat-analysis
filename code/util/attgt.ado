program attgt, eclass
	syntax varlist [if] [in], treatment(varname) [aggregate(string)] [absorb(varlist)] [notyet] [debug]
	marksample touse
	** First determine outcome and xvars
	gettoken y xvar:varlist	

	* read method of aggregation
	if ("`aggregate'"=="") {
		local aggregate gt
	}
	assert inlist("`aggregate'", "gt", "g", "t", "ge", "e", "att")

	* read panel structure
	xtset
	local i = r(panelvar)
	local time = r(timevar)
	markout `touse' `i' `time' `treatment'

	tempvar group u
	tempname b v att
	quietly egen `group' = min(cond(`treatment', `time'-1, .)) if `touse', by(`i')
	quietly summarize `time'
	local min_time = r(min)
	
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

	quietly generate `u' = .

	timer clear
	timer on 1
	* create design matrix
	foreach g in `gs' {
		foreach t in `ts' {
		if (`g'!=`t') & (`g'>`min_time') {
			* within (g,t), panel has to be balanced
			mata: st_local("leadlag1", lead_lag(`g', `t'))
			mata: st_local("leadlag2", lead_lag(`t', `g'))
			local timing (`time'==`g' & `leadlag1'.`time'==`t') | (`time'==`t' & `leadlag2'.`time'==`g')

			local treated (`group'==`g') & (`timing')
			if ("`tyet'"=="") {
				* never treated
				local control missing(`group') & (`timing')
			}
			else {
				* not yet treated
				local control (missing(`group') | (`group' >= max(`g', `t'))) & (`timing')
			}
			quietly count if `treated' & `touse'
			local n_treated = r(N)/2
			quietly count if `control' & `touse'
			local n_control = r(N)/2
			local n_`g'_`t' = `n_treated'

			tempvar treated_`g'_`t' control_`g'_`t'
			quietly generate `treated_`g'_`t'' = cond(`time'==`t', +1/`n_treated', -1/`n_treated') if `treated' & `touse'
			quietly generate `control_`g'_`t'' = cond(`time'==`t', +1/`n_control', -1/`n_control') if `control' & `touse'
		}
		}
	}

	foreach g in `gs' {
		foreach t in `ts' {
		if (`g'!=`t') & (`g'>`min_time') {

			timer on 2
			mata: sum_product("tr", "`y' `treated_`g'_`t''")
			mata: sum_product("co", "`y' `control_`g'_`t''")

			quietly replace `u' = `y' - `co' if `treated_`g'_`t'' & `touse'

			if ("`debug'"!="") {
				tabulate `treated_`g'_`t'', missing
				tabulate `control_`g'_`t'', missing
				display "Control growth: `co'"
				display `tr' - `co'
			}
			matrix `att' = `tr' - `co'
			timer off 2
			matrix `b' = nullmat(`b'), `att'
			matrix `v' = nullmat(`v'), 0.0
			mata: st_local("leadlag", lead_lag(`g', `t'))
			local eqname `eqname' `treatment'_`g'
			local colname `colname'  `leadlag'.`y'
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
	timer off 1
	timer list

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

void sum_product(string scalar output, string matrix vars)
{
	X = 0
	st_view(X, ., vars, 0)
	st_local(output, strofreal(colsum(X[1...,1] :* X[1...,2])))
}
end