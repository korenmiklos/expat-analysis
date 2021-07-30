clear all
here
local here = r(here)

cap log close
log using "`here'/output/est_csdid_att_ipw_idepvar", text replace

use "`here'/temp/analysis_sample.dta"

rename ever_foreign ef
rename ever_foreign_hire efh
rename has_expat_ceo has_expat

gen lnIK = ln(immat_18)
gen lnIK_0 = lnIK
replace lnIK_0 = 0 if immat_18 == 0

replace export_18 = 0 if export_18 == .
gen Qh = sales_18 - export_18
gen lnQh = ln(Qh)
gen lnQhr = lnQ - lnQh

bys frame_id_numeric: egen first_year_foreign_new = min(cond(foreign == 1, year,.))
bys frame_id_numeric: egen fy_foreign_o = min(cond(foreign_only == 1, year,.))
bys frame_id_numeric: egen fy_foreign_ho = min(cond(foreign_hire_only == 1, year,.))
bys frame_id_numeric: egen fy_expat = min(cond(has_expat == 1, year,.))
count if first_year_foreign_new != first_year_foreign_new

mvencode fy_*, mv(0)

gen x = exporter if time_foreign > -4 & time_foreign < 0
egen exporter_before = max(x), by(frame_id_numeric)
drop x

sort frame_id_numeric year

foreach var in lnL lnQ lnK {
	gen `var'_sq = `var'^2
	gen `var'_lag=L.`var'
	gen `var'_lag_sq=`var'_lag^2
}

foreach depvar in lnQL lnK lnL exporter lnQ TFP_cd lnIK_0 lnQh lnQhr {
	foreach var in fy_foreign_o fy_foreign_ho fy_expat {
		csdid `depvar' lnL_sq lnQ_sq lnK_sq exporter_before i.year i.teaor08_2d, ivar(frame_id_numeric) time(year) gvar(`var') agg(simple) method(ipw) notyet
		eststo m`var'`depvar', title("`depvar' `var'")
	}
	
	foreach var in fy_foreign_o fy_foreign_ho fy_expat {
		csdid `depvar' lnL_sq lnQ_sq lnK_sq exporter_before i.year i.teaor08_2d, ivar(frame_id_numeric) time(year) gvar(`var') agg(simple) method(ipw) notyet
		eststo mh`var'`depvar', title("efh `depvar' `var'")
	}
}

esttab m* using "`here'/output/table_csdid_att_ipw_idepvar.tex", mtitle b(3) se(3) replace
esttab m* using "`here'/output/table_csdid_att_ipw_idepvar.txt", mtitle b(3) se(3) replace

log close
