global here "/srv/sandbox/expat/almos"

use "$here/temp/analysis_sample.dta", clear

drop if time_foreign<-4
drop if time_foreign>5 & time_foreign!=.

use "$here/temp/analysis_sample_match.dta", clear


gen y_t=year if time_foreign==0
egen y=max(y_t), by(frame_id_numeric)
drop if y<1998
drop if year<1994

gen trend_plus=time_foreign+100
gen foreign_hire_local=(foreign_hire==1 & has_expat_ceo==0)
egen ever_foreign_hire_local=max(foreign_hire_local), by(frame_id_numeric)

eststo clear
foreach X of varlist $outcome  {
	eststo: quietly reghdfe `X' foreign foreign_hire has_expat_ceo, a(frame_id_numeric teaor08_2d##year) cluster(frame_id_numeric)
}

esttab using "$here/fe.xlsx", star(* .1 ** .05 *** .01)  b(3) se keep(foreign foreign_hire has_expat_ceo) noconstant label replace  nonote  r2

gen foreign_plus=time_foreign+100

xthdidregress ra (TFP_cd) (has_expat_ceo) [aw==weight] if ever_expat==1 | ever_foreign==0, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
estat aggregation
estat aggregation, dynamic graph



xthdidregress ra (lnQ) (has_expat_ceo), group(frame_id_numeric) vce(cluster frame_id_numeric) 
estat aggregation
estat aggregation, dynamic graph


xthdidregress ra (TFP_cd i.trend_plus ) (has_expat_ceo) if ever_foreign_hire_local==0, group(frame_id_numeric) vce(cluster frame_id_numeric) controlgroup(notyet)
estat aggregation
estat aggregation, dynamic graph

xthdidregress ra (TFP_cd) (has_expat_ceo) [aw=weight], group(frame_id_numeric) vce(cluster frame_id_numeric)
estat aggregation
estat aggregation, dynamic graph



gr export "$here/output/twfe/tfp_match_trend.pdf", replace


*Pre-treatment variable averages

foreach x in lnQL lnL {
	
	egen `x'_c=mean(`x'), by(frame_id_numeric)
	
	gen `x'_temp=`x' if time_foreign<0
	egen `x'_t=mean(`x'_temp), by(frame_id_numeric)
	
	gen `x'_pre=`x'_t if ever_foreign==1
	replace `x'_pre=`x'_c if ever_foreign==0
	
	xtile `x'_d=`x'_pre, nq(3)

}

gen QL=sales_18/emp_cl
foreach x in emp_cl QL {
	
	egen `x'_avg=mean(`x'), by(frame_id_numeric)
	xtile `x'_cat=`x'_avg, nq(3)

}



xthdidregress aipw (TFP_cd) (has_expat_ceo industrial i.emp_cl_cat i.QL_cat), group(frame_id_numeric) vce(cluster frame_id_numeric)
estat aggregation
estat aggregation, dynamic graph
