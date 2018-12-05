xtreg exporter during after during_expat after_expat $controls if $sample_acquisitions & H_exporter==0 [aw=inverse_weight], i(firm_person ) fe vce(cluster id)
local r2_w = `e(r2_w)'
do regram output/regression/exporter_heterogeneity 1 Start R2_within "`r2_w'" 

xtreg exporter during after during_expat after_expat $controls if $sample_acquisitions & H_exporter==1 [aw=inverse_weight], i(firm_person ) fe vce(cluster id)
local r2_w = `e(r2_w)'
do regram output/regression/exporter_heterogeneity 2 Continue R2_within "`r2_w'" 

xtreg exporter during after during_expat after_expat $controls if $sample_acquisitions & H_exporter==0 & lag_expat==0 [aw=inverse_weight], i(firm_person ) fe vce(cluster id)
local r2_w = `e(r2_w)'
do regram output/regression/exporter_heterogeneity 3 Domestic R2_within "`r2_w'" 

xtreg exporter during after during_expat after_expat $controls if $sample_acquisitions & H_exporter==1 & lag_expat==1 [aw=inverse_weight], i(firm_person ) fe vce(cluster id)
local r2_w = `e(r2_w)'
do regram output/regression/exporter_heterogeneity 4 Global R2_within "`r2_w'" 
