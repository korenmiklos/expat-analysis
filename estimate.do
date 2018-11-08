*Alapstatisztikák
count if fo3_ever&!greenfield&firm_tag
count if fo3_ever&!greenfield&firm_tag&expat_ceo_ever


*Alapmodellek lefuttatása (greenfield, illetve a ceo szempontjából missing sorok kivéve)
foreach X of var lnL lnQ lnK lnQL lnKL exporter inv{
	eststo: qui areg `X' fo3 switch_ceo_exist fo3_switch_after expat_switch expat_after i.ind_year i.age_cat if expat_ceo!=.&greenfield!=1, a(frame_id ) cluster(frame_id )
}
esttab using ${data}/results_base.rtf, b(3) se(3) r2 keep (fo3 switch_ceo_exist fo3_switch_after expat_switch expat_after _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear


*Alapmodellek lefuttatása - nem manufacturing
foreach X of var lnL lnQ lnK lnQL lnKL exporter inv{
	eststo: qui areg `X' fo3 switch_ceo_exist fo3_switch_after expat_switch expat_after i.ind_year i.age_cat if expat_ceo!=.&greenfield!=1&manufacturing!=1, a(frame_id ) cluster(frame_id )
}
esttab using ${data}/results_nonmanu.rtf, b(3) se(3) r2 keep (fo3 switch_ceo_exist fo3_switch_after expat_switch expat_after _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear


*Alapmodellek lefuttatása - manufacturing
foreach X of var lnL lnQ lnK lnQL lnKL exporter inv{
	eststo: qui areg `X' fo3 switch_ceo_exist fo3_switch_after expat_switch expat_after i.ind_year i.age_cat if expat_ceo!=.&greenfield!=1&manufacturing==1, a(frame_id ) cluster(frame_id )
}
esttab using ${data}/results_manu.rtf, b(3) se(3) r2 keep (fo3 switch_ceo_exist fo3_switch_after expat_switch expat_after _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear


*TFP
g byte lnK_ind=lnK*ind


eststo: qui areg lnQ lnL lnK lnK_ind lnM fo3 switch_ceo_exist expat_ceo_exist i.ind_year i.age_cat if !greenfield&expat_ceo!=., a(frame_id ) cluster(frame_id )
esttab using ${data}/results_tfp.rtf, b(3) se(3) r2 keep (fo3 switch_ceo_exist expat_ceo_exist _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
*esttab using ${data}/first_leed_ceo5.rtf, b(3) se(3) r2 keep (fo3 change fo3_change expat _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear


*Szelekció az akvicíziós mintában
xtset id year
eststo: qui areg f1.expat_ceo_exist lnL lnQ lnK exporter if fo3_ever==1&greenfield!=1, a(industry_year) cluster(frame_id)
esttab using ${data}/results_selection.rtf, b(3) se(3) r2 compress replace modelwidth(5) nogap
eststo clear


*Akvizíciós minta (greenfield nélkül)
keep if fo3_ever==1&greenfield!=1


*Switch_ceo dinamika (csak az fo3 utáni switch-ek bevonva)
gen switch_ceo0=0
gen switch_ceo1=0
gen switch_ceo2=0
gen switch_ceo3=0
gen switch_ceo4=0


xtset id year
replace switch_ceo0=1 if switch_ceo_number>0&switch_ceo_exist==1&fo3_switch_after==1
replace switch_ceo1=1 if l1.switch_ceo_number>0&switch_ceo_number==0&switch_ceo_exist==1&l1.fo3_switch_after==1&fo3_switch_after==1
replace switch_ceo2=1 if l2.switch_ceo_number>0&l1.switch_ceo_number==0&switch_ceo_number==0&switch_ceo_exist==1& ///
l2.fo3_switch_after==1&l1.fo3_switch_after==1&fo3_switch_after==1
replace switch_ceo3=1 if l3.switch_ceo_number>0&l2.switch_ceo_number==0&l1.switch_ceo_number==0&switch_ceo_number==0&switch_ceo_exist==1& ///
l3.fo3_switch_after==1&l2.fo3_switch_after==1&l1.fo3_switch_after==1&fo3_switch_after==1
replace switch_ceo4=1 if l4.switch_ceo_number>0&l3.switch_ceo_number==0&l2.switch_ceo_number==0&l1.switch_ceo_number==0&switch_ceo_number==0& ///
switch_ceo_exist==1&l4.fo3_switch_after==1&l3.fo3_switch_after==1&l2.fo3_switch_after==1&l1.fo3_switch_after==1&fo3_switch_after==1


*Fo3_switch dinamika (jelen helyzetben ez megegyezik a switch_ceo_exist-tel)
*például - tab fo3_switch_exist0 switch_ceo_exist0
gen fo3_switch_exist0=fo3*switch_ceo0
gen fo3_switch_exist1=fo3*switch_ceo1
gen fo3_switch_exist2=fo3*switch_ceo2
gen fo3_switch_exist3=fo3*switch_ceo3
gen fo3_switch_exist4=fo3*switch_ceo4


*Expat dinamika
gen expat_switch0=expat_ceo_exist*switch_ceo0
gen expat_switch1=expat_ceo_exist*switch_ceo1
gen expat_switch2=expat_ceo_exist*switch_ceo2
gen expat_switch3=expat_ceo_exist*switch_ceo3
gen expat_switch4=expat_ceo_exist*switch_ceo4


*Akvizíciós minta mentése
save ${data}/sample_fo, replace


*Alapmodell lefuttatása az akvizíciós mintán
foreach X of var lnL lnQ lnK lnQL lnKL exporter inv{
	eststo: qui areg `X' fo3 fo3_switch_exist expat_switch expat_after i.ind_year i.age_cat if expat_ceo!=., a(frame_id ) cluster(frame_id )
}
esttab using ${data}/results_fo.rtf, b(3) se(3) r2 keep (fo3 fo3_switch_exist expat_switch expat_after _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear


*Alapmodell lefuttatása az akvizíciós mintán dinamikával
foreach X of var lnL lnQ lnK lnQL lnKL exporter inv{
	eststo: qui areg `X' fo3 fo3_switch_exist0 fo3_switch_exist1 fo3_switch_exist2 fo3_switch_exist3 fo3_switch_exist4 expat_switch0 expat_switch1 expat_switch2 expat_switch3 expat_switch4 expat_after i.ind_year i.age_cat if expat_ceo!=., a(frame_id ) cluster(frame_id )
}
esttab using ${data}/results_dynamics.rtf, b(3) se(3) r2 keep (fo3 fo3_switch_exist0 fo3_switch_exist1 fo3_switch_exist2 fo3_switch_exist3 fo3_switch_exist4 expat_switch0 expat_switch1 expat_switch2 expat_switch3 expat_switch4 expat_after _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear
