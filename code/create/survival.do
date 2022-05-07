fillin frame_id_numeric year
rename _fillin dead_firm
xtset frame_id_numeric year
generate byte survival = 1 - dead_firm

tempvar begin end
egen `begin' = min(cond(survival, year, .)), by(frame_id_numeric)
egen `end' = max(cond(survival, year+1, .)), by(frame_id_numeric)
keep if `begin' <= year
drop `begin' `end'