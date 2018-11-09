
gsort frame_id -year
foreach X of var tenure_* {
	clonevar `X'_recoded = `X'
	replace `X'_recoded = . if `X'<-Tbefore | `X'>Tafter
	* create "before" event windows only if there is no overlap with a prior "after" event window
	by frame_id: replace `X'_recoded = `X'_recoded[_n-1]+year-year[_n-1] if missing(`X'_recoded) & (`X'_recoded[_n-1]+year-year[_n-1]>=-Tbefore)
	* winsorize all tenure "after"
	replace `X'_recoded = Tafter if `X'>Tafter & missing(`X'_recoded) & !missing(`X')
}
local T1 = Tbefore 
local T2 = Tafter

foreach X in foreign expat domestic {
	gen byte `X'_p_0 = tenure_`X'_recoded==0
	forval t=1/`T1' {
		gen byte `X'_m_`t' = tenure_`X'_recoded==-`t'
	}
	forval t=1/`T2' {
		gen byte `X'_p_`t' = tenure_`X'_recoded==`t'
	}
}
sort frame_id year

* illustrate window overlap and recoding
foreach X in domestic expat foreign {
	l year tenure_`X' tenure_`X'_recoded if frame_id=="ft10072219"
}
