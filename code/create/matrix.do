clear all

foreach file in balance analysis {
	clear all
	mata: mata matuse "temp/matrix-`file'", replace
	mata: st_matrix("total_`file'", mat_total_`file')

	matrix colnames total_`file' = "foreign" "foreign_0" "foreign_1" "count" "holes"
	*No option to save row names as variables as svmat - https://www.stata.com/statalist/archive/2007-07/msg00477.html

	matrix list total_`file'

	svmat total_`file', names(col)
	
	tempfile `file'
	save ``file''
}

use `balance', clear
append using `analysis'

gen when = _n
label define when_label 1 "beginning" 2 "sampling" 3 "fo3 holes" 4 "missing lnK" 5 "missing lnQ" 6 "missing lnL" 7 "missing lnM" 8 "manager merge" 9 "many foreign changes" 10 "D, D-F kept"
label values when when_label

export delimited using "temp/foreign_drop", replace

*rename foreign data1
*rename foreign_0 data2
*rename foreign_1 data3
*rename count data4
*reshape long data, i(when) j(what)
*label define what_label 1 "foreign" 2 "foreign_0" 3 "foreign_1" 4 "count"
*label values what what_label
