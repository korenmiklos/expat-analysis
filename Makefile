STATA = stata -b do
ESTIMATOR = temp/analysis_sample.dta estimate.do regram.do
.PHONY: all
SPECS = descriptive manager_level heterogeneity event_study switch selection

all: output/table/language.tex output/table/granger.tex output/table/trade.tex output/table/event_study.tex output/table/products.tex
extra:  output/table/pairwise.tex output/table/gravity.tex output/table/placebo.tex output/figure/TE_owner.png
output/table/%.tex: code/estimate/%.do temp/analysis_sample_dyadic.dta
	$(STATA) $<
output/figure/TE_owner.png: code/estimate/TE.do temp/analysis_sample_dyadic.dta
	$(STATA) $<
output/descriptives.log: temp/analysis_sample.dta descriptives.do
	$(STATA) descriptives 
temp/analysis_sample_dyadic.dta: input/owner-country/owner-country-panel.dta temp/balance-small-clean.dta temp/trade.dta temp/firm_events.dta code/create/analysis_sample.do code/create/event_dummies_firmlevel.do code/create/countries.do code/create/lags.do temp/gravity.dta
	$(STATA) code/create/analysis_sample.do
temp/firm_events.dta: input/ceo-panel/ceo-panel.dta temp/balance-small-clean.dta code/create/firm_panel.do temp/manager_country.dta
	$(STATA) code/create/firm_panel.do
temp/balance-small-clean.dta: input/merleg-expat/balance-small.dta code/create/balance.do
	$(STATA) code/create/balance.do
temp/trade.dta: input/trade-firm-panel/trade-country-firm.dta temp/balance-small-clean.dta code/create/trade.do
	$(STATA) code/create/trade.do
temp/gravity.dta: code/create/gravity.do input/cepii-geodist/geodist.dta
	$(STATA) $<
temp/manager_country.dta: code/create/manager_country.do input/ceo-panel/ceo-panel.dta
	$(STATA) $<
install:
	$(STATA) code/util/install.do
tables: 
	python3 ~/Dropbox/projects/py/oak/oak.py -p id -c output -o output .
	rm -rf output/regression/_*

