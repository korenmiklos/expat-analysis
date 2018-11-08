clear all
capture log close
log using output/estimate, text replace

use temp/analysis_sample

local sample_baseline expat!=.&greenfield!=1
local sample_manufacturing `sample_baseline' & manufacturing==1
local sample_acquisitions `sample_baseline' & ever_foreign==1

local samples baseline manufacturing acquisitions

local scale lnL lnK lnQ
local intensity lnKL lnQL exporter inv

xtset id year
foreach sample in `samples' {
	foreach group in scale intensity {
		foreach X of var ``group'' {
			xtreg `X' foreign new fnew fnew_expat fold_expat i.ind_year i.age_cat if `sample_`sample'', i(id ) fe vce(cluster id)
			local r2_w = `e(r2_w)'
			do regram output/regression/`sample'_`group' `X' `X' R2_within "`r2_w'"
		}
	}
}

*Szelekció az akvicíziós mintában
xtset id year
areg f1.expat lnL lnQ lnK exporter if ever_foreign==1&greenfield!=1, a(industry_year) cluster(frame_id)
do regram output/regression/selection 1 1

*Akvizíciós minta (greenfield nélkül)
keep if ever_foreign==1&greenfield!=1
clonevar tenure_foreign = age_since_foreign

BRK


*Alapmodell lefuttatása az akvizíciós mintán dinamikával
foreach X of var lnL lnQ lnK lnQL lnKL exporter inv{
	eststo: qui areg `X' forein forein_switch_exist0 forein_switch_exist1 forein_switch_exist2 forein_switch_exist3 forein_switch_exist4 expat_switch0 expat_switch1 expat_switch2 expat_switch3 expat_switch4 expat_after i.ind_year i.age_cat if expat_ceo!=., a(frame_id ) cluster(frame_id )
}
esttab using ${data}/results_dynamics.rtf, b(3) se(3) r2 keep (forein forein_switch_exist0 forein_switch_exist1 forein_switch_exist2 forein_switch_exist3 forein_switch_exist4 expat_switch0 expat_switch1 expat_switch2 expat_switch3 expat_switch4 expat_after _cons) star(* 0.1 ** 0.05 *** 0.01) compress onecell replace modelwidth(5)
eststo clear
