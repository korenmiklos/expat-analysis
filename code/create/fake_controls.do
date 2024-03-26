tempfile fake
* generate fake controls with 0 effect, to estimate the average effect in the treatment group
levelsof year, local(years)
local N_years : word count `years'
local K 231

preserve
    clear
    set obs `=`K'*`N_years''
    generate long frame_id_numeric = .
    forvalues k = 1/`K' {
        quietly replace frame_id_numeric = `k' if inrange(_n, (`k'-1)*`N_years'+1, `k'*`N_years')
    }
    generate year = .
    forvalues i = 1/`N_years' {
        local year : word `i' of `years'
        quietly replace year = `year' if _n == (frame_id_numeric - 1)*`N_years' + `i'
    }
    foreach Y in $varlist_rhs local_ceo has_expat_ceo ever_expat ever_local foreign {
        generate `Y' = 0
    }
    compress
    save `fake', replace
restore
append using `fake', generate(fake)

generate byte control = !fake & !foreign
egen N_control = total(control), by(year)
tabulate year control

* the time pattern of the fake control group should be the same as the real control group
drop if (frame_id_numeric > N_control) & fake
tabulate year if fake
drop N_control

xtset frame_id_numeric year
