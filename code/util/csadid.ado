capture program drop csadid
program define csadid
	args outcome treatment1 treatment2 treatment3
	local treatment `treatment1'
	local treatments `treatment1' `treatment2' `treatment3'
	
	* read panel structure
	xtset
	local i = r(panelvar)
	local t = r(timevar)
	
	tempvar first_treatment not_yet_treated
	egen `first_treatment' = min(cond(`treatment', `t', .)), by(`i')
	
	* estimate ATT(g,t) as eq 2.6 in https://pedrohcgs.github.io/files/Callaway_SantAnna_2020.pdf
	levelsof `first_treatment', local(gs)
	summarize `t'
	local Tmax = r(max)
	foreach X in `treatments' {
		generate ATT_`X' = .
	}
	foreach g in `gs' {
		forvalues time = `g'/`Tmax' {
			generate `not_yet_treated' = (`t' < `first_treatment')
			areg `outcome' `treatment1' `treatment2' `treatment3' i.`t' ///
				if ((`g'==`first_treatment') ///
					|(`not_yet_treated')) ///
					&((`time'==`t')|(`t'==`g'-1)) ///
					, a(`i')
			foreach X in `treatments' {
				replace ATT_`X' = _b[`X'] if (`g'==`first_treatment')&(`time'==`t')
			}
			drop `not_yet_treated'
		}
	}

end
