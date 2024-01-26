


*Check ATTGT

forval i=1990/2017 {

	display "g="`i' 	
	
	forval j=0/5 {
		
		display "t="`j'
		
		*Construct variables

		gen x_0=(has_expat_ceo==1 & year==`i'-1)
		egen expat_0=max(x_0), by(frame_id_numeric)
		
		gen x_1=(has_expat_ceo==1 & year==`i')
		egen expat_1=max(x_1), by(frame_id_numeric)
		
		gen x_2=(has_expat_ceo==1 & year==`i'+5)
		egen expat_2=max(x_2), by(frame_id_numeric)
		
		gen treated_firm=(expat_0==0 & expat_1==1)
		gen control_firm=(expat_0==0 & expat_2==0)

		*Diff-in-diff
		tempvar out0 out1
		gen `out0'=TFP_cd if year==`i'-1
		gen `out1'=TFP_cd if year==`i'+`j'
		egen outcome_pre=mean(`out0'), by(frame_id_numeric)
		egen outcome_post=mean(`out1'), by(frame_id_numeric)
		
		gen d_outcome=outcome_post-outcome_pre 
		
		egen diff_control=mean(d_outcome) if control_firm==1
		egen d0=mean(diff_control)
		egen diff_treated=mean(d_outcome) if treated_firm==1
		egen d1=mean(diff_treated)
		
		gen did_`i'_`j'=d1-d0
		
		*Nobs
		sum frame_id_numeric if outcome_pre!=. & year==`i'+`j' & (control_firm==1 | treated_firm==1) 
		scalar N_`i'_`j'=r(N)

		sum frame_id_numeric if outcome_pre!=. & year==`i'+`j' & treated_firm==1 
		scalar Nt_`i'_`j'=r(N)
		
		drop x* expat_0 expat_1 expat_2 treated_firm control_firm outcome_pre outcome_post d_outcome diff_control diff_treated d1 d0
	}

}

*Compute ATT for year i

forval i=1990/2017 {
		
	scalar denom_`i'=N_`i'_0+N_`i'_1+N_`i'_2+N_`i'_3+N_`i'_4+N_`i'_5
	
	scalar ATT_`i'=(did_`i'_0*N_`i'_0+did_`i'_1*N_`i'_1+did_`i'_2*N_`i'_2+did_`i'_3*N_`i'_3+did_`i'_4*N_`i'_4+did_`i'_5*N_`i'_5)/denom_`i'

	display "ATT"`i'
	display ATT_`i'
	
	}

*Compute LATE for year i
forval i=1990/2017 {
		
	scalar denom_`i'=Nt_`i'_0+Nt_`i'_1+Nt_`i'_2+Nt_`i'_3+Nt_`i'_4+Nt_`i'_5
	
	scalar ATT_`i'=(beta_`i'_0*Nt_`i'_0+beta_`i'_1*Nt_`i'_1+beta_`i'_2*Nt_`i'_2+beta_`i'_3*Nt_`i'_3+beta_`i'_4*Nt_`i'_4+beta_`i'_5*Nt_`i'_5)/denom_`i'

	display "ATT"`i'
	display ATT_`i'
	
	}
	
	
	
*Compute grand ATT
scalar ATT=0
scalar denom=0
forval i=1990/2013 {

	scalar nom=ATT+ATT_`i'*denom_`i'
	scalar denom=denom+denom_`i'
}

disp nom/denom	



*junk
		*Regression, nobs
		quietly regress TFP_cd treated_firm treatyear treat if regsample==1, cluster(frame_id_numeric)
		scalar beta_`i'_`j'=_b[treat]
		scalar N_`i'_`j'=e(N_clust)

		quietly sum has_expat_ceo if treated_firm==1 & treatyear==1 
		scalar Nt_`i'_`j'=r(N)
