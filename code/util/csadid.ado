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

	tempvar group post
	egen `group' = min(cond(`treatment', `time', .)), by(`i')
	
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
	levelsof `group' if `touse', local(gs)
	levelsof `time' if `touse', local(ts)

	generate `post' = .
	capture drop ATT_gt
	generate ATT_gt = .

	foreach t in `ts' {
		replace `post' = (`time' == `t') & `touse'
		foreach g in `gs' {
			if (`g'!=`t') {
				capture reghdfe `y' `treatment' `xvar' ///
					if `touse' & ((`group'==`g') ///
						| missing(`group')) ///
						& inlist(`time', `g'-1, `t') ///
						, absorb(`a')
				if (_rc==0) {
					replace ATT_gt = _b[`treatment'] if (`group'==`g')&(`time'==`t')&`touse'
				}
			}
		}
	}

end
