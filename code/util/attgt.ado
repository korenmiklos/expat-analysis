program attgt, eclass
	syntax varlist [if] [in], treatment(varname) [aggregate(string)] [absorb(varlist)] [pre(integer 999)] [post(integer 999)] [reps(int 199)] [notyet] [debug] [cluster(varname)] [limitcontrol(string)] [weightprefix(string)] [treatment2(varname)]
	marksample touse

	* boostrap
	local B `reps'

	* read method of aggregation
	if ("`aggregate'"=="") {
		local aggregate gt
	}
	assert inlist("`aggregate'", "gt", "e", "att")
	if ("`aggregate'"=="att") {
		* if we only compute ATT, no need to check pre-trends
		local pre 0
	}

	* read panel structure
	xtset
	local i = r(panelvar)
	local time = r(timevar)
	markout `touse' `i' `time' `treatment' `varlist'

	if ("`treatment2'" != "") {
		capture assert "`limitcontrol'`tyet'" == ""
		if _rc {
			display in red "limitcontrol and notyet incompatible with treatment2"
			error 9
		}
		tempvar group2
		quietly egen `group2' = min(cond(`treatment2', `time'-1, .)) if `touse', by(`i')
		* FIXME: range of group2 may not be the same as group. what to do with these treatment times?
	}

	* limitcontrol option limits control observations to satisfy "if `limitcontrol'" both in g and in t
	if ("`limitcontrol'"=="") {
		local limitcontrol 1
	}
	tempvar lc_var
	quietly generate byte `lc_var' = (`limitcontrol')

	* test that cluster embeds ivar
	if ("`cluster'"!="") {
		tempvar g1 g2
		tempname max1 max2
		quietly egen `g1' = group(`i')
		quietly summarize `g1'
		scalar `max1' = r(max)
		quietly egen `g2' = group(`i' `cluster')
		quietly summarize `g2'
		scalar `max2' = r(max)
		assert `max2'==`max1'
		drop `g1' `g2'
	}
	else {
		local cluster `i'
	}

	tempvar group _alty_ _y_ flip
	tempname b V v att co tr _tr_
	quietly egen `group' = min(cond(`treatment', `time'-1, .)) if `touse', by(`i')
	quietly summarize `time' if `touse'
	local min_time = r(min)
	local max_time = r(max)
	quietly summarize `group' if `touse'
	local min_g = r(min)
	local max_g = r(max)
	* feasible event windows
	local max_pre = min(`max_g' - `min_time', `pre')
	local max_post = min(`max_time' - `min_g', `post')
	
	* estimate ATT(g,t) as eq 2.6 in https://pedrohcgs.github.io/files/Callaway_SantAnna_2020.pdf
	quietly levelsof `group' if `touse' & `group' > `min_time', local(gs)
	quietly levelsof `time' if `touse', local(ts)

	* check that valid weights exist for each treatment group
	if ("`weightprefix'" != "") {
		foreach g in `gs' {
			confirm numeric variable `weightprefix'`g'
			capture assert `weightprefix'`g' >= 0 if `touse', fast
			if _rc {
				display in red "Weights must be non-negative. Offending weight:  `weightprefix'`g'"
				error 9
			}
			tempvar i1 i2
			* check that weight does not vary within ivar
			quietly egen `i1' = group(`i') if `touse'
			quietly egen `i2' = group(`i' `weightprefix'`g') if `touse'
			quietly summarize `i1'
			local m1 = r(max)
			quietly summarize `i2'
			local m2 = r(max)
			capture assert `m1' == `m2'
			if _rc {
				display in red "Weights cannot vary within `i'. Offending weight:  `weightprefix'`g'"
				error 9
			}
			drop `i1' `i2'
		}
	}
	else {
		tempvar one
		quietly generate byte `one' = 1
	}

	* FIXME: check that g = min_time is not used as control
	* create design matrix
	display "Generating weights..."
	foreach g in `gs' {
		if ("`weightprefix'" != "") {
			local cweight `weightprefix'`g'
		}
		else {
			local cweight `one'
		}
		foreach t in `ts' {
		if (`g'!=`t') & (`g'>`min_time') & (`t' - `g' <= `post') & (`g' - `t' <= `pre') {
			* within (g,t), panel has to be balanced
			mata: st_local("leadlag1", lead_lag(`g', `t'))
			mata: st_local("leadlag2", lead_lag(`t', `g'))
			local timing (`time'==`g' & `leadlag1'.`time'==`t') | (`time'==`t' & `leadlag2'.`time'==`g')
			if ("`limitcontrol'" != "") {
				local lc (`lc_var' & `leadlag1'.`lc_var' ///
					& !missing(`lc_var', `leadlag1'.`lc_var') & `time'==`g') ///
					| (`lc_var' & `leadlag2'.`lc_var' ///
					& !missing(`lc_var', `leadlag2'.`lc_var') & `time'==`t')
			}
			else {
				local lc 1
			}

			local treated (`group'==`g') & (`timing')
			if ("`tyet'"=="") {
				if "`treatment2'" != "" {
					local control (`group2'==`g') & (`timing')
				}
				else {
					* never treated
					local control missing(`group') & (`timing') & (`lc')
				}
			}
			else {
					* not yet treated
					* QUESTION: > or >=
					local control (missing(`group') | (`group' > max(`g', `t'))) & (`timing') & (`lc')
			}
			quietly count if `treated' & `touse'
			local n_treated = r(N)/2
			quietly summarize `cweight' if `control' & `touse'
			local sumw_control = r(sum)/2
			local n_control = r(N)/2
			local n_`g'_`t' = `n_treated' * `n_control' / (`n_treated' + `n_control')

			tempvar treated_`g'_`t' control_`g'_`t'
			quietly generate `treated_`g'_`t'' = cond(`time'==`t', +1/`n_treated', -1/`n_treated') if `treated' & `touse'
			quietly generate `control_`g'_`t'' = cond(`time'==`t', `cweight'/`sumw_control', -`cweight'/`sumw_control') if `control' & `touse'
		}
		}
	}

	if ("`aggregate'"=="e") {
		tempname n_e
		forvalues e = `max_pre'(-1)1 {
			scalar `n_e' = 0
			tempvar event_m`e' wce_m`e'
			quietly generate `event_m`e'' = 0
			quietly generate `wce_m`e'' = 0
			foreach g in `gs' {
				local t = `g' - `e'
				if (`t' >= `min_time') & ("`n_`g'_`t''" != "") {
					quietly replace `event_m`e'' = `event_m`e'' + `n_`g'_`t''*`treated_`g'_`t'' if !missing(`treated_`g'_`t'') & `touse'
					quietly replace `wce_m`e'' = `wce_m`e'' + `n_`g'_`t''*`control_`g'_`t'' if !missing(`control_`g'_`t'') & `touse'
					scalar `n_e' = `n_e' + `n_`g'_`t''
				}
			}
			quietly replace `event_m`e'' = `event_m`e'' / `n_e' 
			quietly replace `wce_m`e'' = `wce_m`e'' / `n_e' 
			local tweights `tweights' event_m`e'
			local cweights `cweights' wce_m`e'
		}
		forvalues e = 1/`max_post' {
			scalar `n_e' = 0
			tempvar event_`e' wce_`e'
			quietly generate `event_`e'' = 0
			quietly generate `wce_`e'' = 0
			foreach g in `gs' {
				local t = `g' + `e'
				if (`t' <= `max_time') & ("`n_`g'_`t''" != "") {
					quietly replace `event_`e'' = `event_`e'' + `n_`g'_`t''*`treated_`g'_`t'' if !missing(`treated_`g'_`t'') & `touse'
					quietly replace `wce_`e'' = `wce_`e'' + `n_`g'_`t''*`control_`g'_`t'' if !missing(`control_`g'_`t'') & `touse'
					scalar `n_e' = `n_e' + `n_`g'_`t''
				}
			}
			quietly replace `event_`e'' = `event_`e'' / `n_e' 
			quietly replace `wce_`e'' = `wce_`e'' / `n_e' 
			local tweights `tweights' event_`e'
			local cweights `cweights' wce_`e'
		}
	}
	if ("`aggregate'"=="gt") {
			foreach g in `gs' {
				foreach t in `ts' {
				if (`g'!=`t') & (`g'>`min_time') & ("`n_`g'_`t''" != "") {
					local tweights `tweights' treated_`g'_`t'
					local cweights `cweights' control_`g'_`t'
				}
				}
			}
	}
	if ("`aggregate'"=="att") {
			tempname n
			tempvar att control
			quietly generate `att' = 0
			quietly generate `control' = 0
			scalar `n' = 0
			foreach g in `gs' {
				foreach t in `ts' {
				if (`g' < `t') & (`g'>`min_time') & (`t' - `g' <= `post') & ("`n_`g'_`t''" != "") {
					quietly replace `att' = `att' + `n_`g'_`t''*`treated_`g'_`t'' if !missing(`treated_`g'_`t'') & `touse'
					quietly replace `control' = `control' + `n_`g'_`t''*`control_`g'_`t'' if !missing(`control_`g'_`t'') & `touse'
					scalar `n' = `n' + `n_`g'_`t''
				}
				}
			}
			quietly replace `att' = `att' / `n' 
			quietly replace `control' = `control' / `n' 
			local tweights att
			local cweights control
	}

	tempvar esample
	quietly generate byte `esample' = 0

	* aggregate across known weights
	quietly generate `_alty_' = .
	quietly generate `_y_' = .
	quietly generate byte `flip' = 0
	local nw : word count `tweights'
	foreach y of var `varlist' {
		forvalues n = 1/`nw' {
			quietly replace `_alty_' = .
			quietly replace `_y_' = .

			local tw : word `n' of `tweights'
			local cw : word `n' of `cweights'

			* set estimation sample
			quietly replace `esample' = 1 if ((``tw'' != 0 & !missing(``tw'')) | (``cw'' != 0 & !missing(``cw''))) & `touse'

			display "Estimating `y': `tw'"

			mata: st_numscalar("`co'", sum_product("`y' ``cw''"))
			mata: st_numscalar("`tr'", sum_product("`y' ``tw''"))
			matrix `att' = `tr' - `co'

			* wild bootstrap with Rademacher weights requires flipping the error term
			quietly replace `_y_' = cond(``tw''>0, `y' - `tr', `y') if ``tw'' !=0 & !missing(``tw'') & `touse'
			quietly replace `_alty_' = cond(``tw''>0, `tr' - `y', -`y') if ``tw'' !=0 & !missing(``tw'') & `touse'
			quietly replace `_y_' = cond(``cw''>0, `y' - `co', `y') if ``cw'' !=0 & !missing(``cw'') & `touse'
			quietly replace `_alty_' = cond(``cw''>0, `co' - `y', -`y') if ``cw'' !=0 & !missing(``cw'') & `touse'

			set seed 4399
			mata: st_numscalar("`v'", bs_variance("`_y_' `_alty_' ``tw'' ``cw'' `cluster'", "`touse'", `B', 1))
			matrix `b' = nullmat(`b'), `att'
			matrix `V' = nullmat(`V'), `v'
			local eqname `eqname' `y'
			local colname `colname' `tw'
		}
	}
	matrix `V' = diag(`V')
	matrix colname `b' = `colname'
	matrix coleq   `b' = `eqname'
	matrix colname `V' = `colname'
	matrix coleq   `V' = `eqname'
	matrix rowname `V' = `colname'
	matrix roweq   `V' = `eqname'

	quietly count if `esample' == 1
	local Nobs = r(N)

	ereturn post `b' `V', obs(`Nobs') esample(`esample')
	ereturn local cmd attgt
	ereturn local cmdline attgt `0'
	display "Callaway Sant'Anna (2021)"
	* Use Stata's built-in but undocumented estimation display
	_prefix_display

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

string scalar minus(real scalar t)
{
	if (t >= 0) {
		return(strofreal(t))
	}
	else {
		return("m" + strofreal(-t))
	} 
}

real scalar sum_product(string matrix vars)
{
	X = 0
	st_view(X, ., vars, 0)
	return(colsum(X[1...,1] :* X[1...,2]))
}

real scalar bs_variance(string matrix vars, string scalar selectvar, real scalar B, real scalar cluster)
{
	X = 0
	st_view(X, ., vars, selectvar)
	N = rows(X)
	Y = J(N, 1, 0)
	theta = J(B, 1, .)

	if (cluster==1) {
		group = recode(X[1..., 5])
		K = max(group)
	}
	else {
		group = 1::N
		K = N
	}

	for (i=1; i<=B; i++) {
		flip = rdiscrete(K, 1, (0.5, 0.5))

		for (n=1; n<=N; n++) {
			Y[n,1] = X[n, 1..2][flip[group[n]]]
		}

		theta[i, 1] = colsum(Y :* X[1..., 3]) - colsum(Y :* X[1..., 4])
	}
	return((variance(theta))[1,1])
}

real vector recode(real vector x)
{
	N = rows(x)
	levelsof = uniqrows(x)
	G = rows(levelsof)
	output = J(N, 1, 0)
	for (n=1; n<=N; n++) {
		output[n] = min(selectindex(levelsof :== x[n]))
	}
	return(output)
}

real matrix build_index(real vector ivar, real vector tvar)
{
	N = colmax(ivar)
	T = colmax(tvar)

	index = J(N, T, 0)
	for (i=1; i<=N; i++) {
		for (t=1; t<=T; t++) {
			loc = selectindex((ivar :== i) :& (tvar :== t))
			if (rows(loc) & cols(loc)) {
				index[i, t] = loc[1]
			}
		}
	}
	return(index)
}

void difference_baseline(string scalar vars)
{
	real matrix YX
	st_view(YX, ., vars)

	ivar = YX[., 3]
	tvar = YX[., 4]
	gvar = YX[., 5]

	T = colmax(tvar)
	N = colmax(ivar)

	index = build_index(ivar, tvar)
	printf("503,7 = %f", index[503,7])

	for (i=1; i<=N; i++) {
		for (g=1; g<=T; g++) {
			if (index[i, g] > 0) {
				baseline = YX[index[i, g], 2]
			}
			else {
				baseline = .
			}
			for (t=1; t<=T; t++) {
				if (index[i, t] > 0) {
					gg = gvar[index[i, t]]
					if (gg > 0) {
						if (index[i, gg] > 0) {
							YX[index[i, t], 1] = YX[index[i, t], 2] - YX[index[i, gg], 2]
						}
					}
				}
			}
		}
	}
}

end
