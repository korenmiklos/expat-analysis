xtset firm_person year

gen byte Fexpat = F.expat==1 if !missing(F.expat)

keep if $sample_baseline & tenure == -1 & !missing(lag_expat)

reg Fexpat $outcomes foreign i.ind_year i.age_cat , vce(cluster frame_id)
do regram output/regression/selection 1 Selection

reg Fexpat $outcomes foreign lag_expat i.ind_year i.age_cat, vce(cluster frame_id)
do regram output/regression/selection 2 Persistence

reg Fexpat $outcomes foreign i.ind_year i.age_cat if lag_expat==0, vce(cluster frame_id)
do regram output/regression/selection 3 Local

reg Fexpat $outcomes foreign i.ind_year i.age_cat if lag_expat==1, vce(cluster frame_id)
do regram output/regression/selection 4 Expat
