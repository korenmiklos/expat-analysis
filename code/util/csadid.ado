capture program drop csadid
program define csadid
	args outcome treatment
	
	* read panel structure
	xtset
	local i = r(panelvar)
	local t = r(timevar)
	
	tempvar first_treatment not_yet_treated
	egen `first_treatment' = min(cond(`treatment', `t', .)), by(`i')
	generate `not_yet_treated' = (year < `first_treatment')
	
	* estimate ATT(g,t) as eq 2.6 in https://pedrohcgs.github.io/files/Callaway_SantAnna_2020.pdf
	levelsof `first_treatment', local(gs)
	summarize `t'
	local Tmax = r(max)
	generate ATT_gt = .
	foreach g in `gs' {
		local g1 = `g'+1
		forvalues time = `g1'/`Tmax' {
			areg `outcome' `treatment' i.`t' ///
				if ((`g'==`first_treatment') ///
					|(`not_yet_treated')) ///
					&((`time'==`t')|(`t'==`g'-1)) ///
					, a(`i')
			replace ATT_gt = _b[`treatment'] if (`g'==`first_treatment')&(`time'==`t')
		}
	}

end
