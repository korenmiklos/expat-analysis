local T1 = Tbefore 
local T2 = Tafter

foreach X in expat domestic {
	gen byte `X'_p_0 = tenure==0 & (`X'==1)
	forval t=1/`T1' {
		gen byte `X'_m_`t' = tenure== -`t' & (`X'==1)
	}
	forval t=1/`T2' {
		gen byte `X'_p_`t' = tenure== `t' & (`X'==1)
	}
}
sort frame_id year

* illustrate window overlap and recoding
l manager_id expat year tenure if frame_id=="ft10072219"
