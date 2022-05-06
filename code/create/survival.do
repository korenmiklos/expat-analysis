fillin frame_id_numeric year
rename _fillin dead_firm
xtset frame_id_numeric year
generate byte survival = 1 - dead_firm