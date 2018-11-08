args tablefile specname speclabel

* create directory if needed
* FIXME: this only works with relative paths
local list_of_dirs = subinstr("`tablefile'/columns","/"," ",.)
local sofar "."
foreach word in `list_of_dirs' {
	local sofar "`sofar'/`word'"
	capture mkdir "`sofar'"
}

macro shift
macro shift
macro shift

local _others ""
local _state "key"
while "`1'"!="" {
	if ("`_state'"=="key") {
		di "key: `1'"
		local _key `1'
		local _state "value"
		local _others "`_others' `1'"
	}
	else {
		di "value: `1'"
		local `_key' "`1'"
		local _state "key"
	}
	macro shift
}

estimates
tempname output coefs stats variables b se
matrix `coefs' = r(table)
local observations `e(N)'
local R2 `e(r2)'

local `stats' : rownames(`coefs')
local `variables' : colnames(`coefs')


file open `output' using "`tablefile'/columns/`specname'.yaml", write text replace

file write `output' "id: " "`specname'" _newline
file write `output' "label: " "`speclabel'" _newline

file write `output' "coefficients:" _newline
foreach X in ``variables'' {
	scalar `b' = `coefs'[rownumb(`coefs',"b"),colnumb(`coefs',"`X'")]
	scalar `se' = `coefs'[rownumb(`coefs',"se"),colnumb(`coefs',"`X'")]
	file write `output' (" - id: `X'") _newline
	file write `output' ("   estimate: " + string(`b')) _newline
	file write `output' ("   standard_error: " + string(`se')) _newline
	file write `output' ("   t_statistic: " + string(`b'/`se')) _newline
	file write `output' ("   p_value: " + string(`coefs'[rownumb(`coefs',"pvalue"),colnumb(`coefs',"`X'")])) _newline
}
file write `output' "extra_rows:" _newline
foreach X in R2 observations `_others'{
	if ("``X''"!="") {
		file write `output' (" - id: `X'") _newline
		file write `output' ("   value: ``X''") _newline
	}
}

file close `output'
