clear all

foreach file in balance analysis {
	clear all
	mata: mata matuse "temp/matrix-`file'", replace
	mata: st_matrix("total_`file'", mat_total_`file')

	matrix colnames total_`file' = "foreign" "foreign_0" "foreign_1" "count" "hole1" "hole2"
	*No option to save row names as variables as svmat - https://www.stata.com/statalist/archive/2007-07/msg00477.html

	matrix list total_`file'

	svmat total_`file', names(col)
	
	tempfile `file'
	save ``file''
}

use `balance', clear
append using `analysis'

gen when = _n
forval i = 2(2)20 {
	replace when = when - 1 if when == `i'
}

label define when_label 1 "beginning" 3 "sampling" 5 "fo3 holes" 7 "missing lnK" 9 "missing lnQ" 11 "missing lnL" 13 "missing lnM" 15 "manager merge" 17 "many foreign changes" 19 "D, D-F kept"
label values when when_label

gen type = _n
forval i = 1(2)20 {
	replace type = 1 if type == `i'
}

forval i = 2(2)20 {
	replace type = 2 if type == `i'
}

label define type_label 1 "all" 2 "analysis sample ever foreign"
label values type type_label

export delimited using "temp/foreign_drop", replace

*rename foreign data1
*rename foreign_0 data2
*rename foreign_1 data3
*rename count data4
*reshape long data, i(when) j(what)
*label define what_label 1 "foreign" 2 "foreign_0" 3 "foreign_1" 4 "count"
*label values what what_label
