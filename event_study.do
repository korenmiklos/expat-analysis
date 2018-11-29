local T1 = Tbefore 
local T2 = Tduring

foreach X in expat domestic {
	gen byte `X'_p_0 = tenure==0 & (`X'==1)
	forval t=1/`T1' {
		gen byte `X'_m_`t' = tenure== -`t' & (`X'==1)
	}
	forval t=1/`T2' {
		gen byte `X'_p_`t' = tenure== `t' & (`X'==1)
	}
	replace `X'_p_`T2' = tenure>= `T2' & (`X'==1)
}
local X foreign
gen byte `X'_p_0 = tenure_`X'==0
forval t=1/`T1' {
	gen byte `X'_m_`t' = tenure_`X'== -`t'
}
forval t=1/`T2' {
	gen byte `X'_p_`t' = tenure_`X'== `t'
}
replace `X'_p_`T2' = tenure_`X'>= `T2' 
sort frame_id year

* illustrate window overlap and recoding
l manager_id expat year tenure* if frame_id=="ft10072219"
