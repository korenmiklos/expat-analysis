cap drop hole* x
sort frame_id_numeric year
gen x = year - year[_n-1] if frame_id_numeric == frame_id_numeric[_n-1]
forval i = 1(1)10 {
	gen hole`i' = (x > `i' & x != .)
}
