here
local here = r(here)

use "`here'/temp/analysis_sample_dyadic.dta", clear
do "`here'/code/util/label.do"

global dummies frame_id_numeric##year cc##year frame_id_numeric##cc
global options label tex(frag) dec(3) nocons nonotes addstat(Mean outcome, r(mean)) nor2
