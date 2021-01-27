STATA = stata -b do
ESTIMATOR = temp/analysis_sample.dta estimate.do regram.do
.PHONY: all
SPECS = descriptive manager_level heterogeneity event_study switch selection

all: output/table/granger.tex output/table/trade.tex output/table/selection.tex output/table/diffindiff_main.tex output/table/cross_section_main.tex output/table/exporter.tex

output/table/granger.tex: code/estimate/granger.do temp/analysis_sample_dyadic.dta
	$(STATA) $<
output/table/trade.tex: code/estimate/trade.do temp/analysis_sample_dyadic.dta
	$(STATA) $<
output/table/%.tex: code/estimate/%.do temp/analysis_sample.dta
	$(STATA) $<
output/table/%_main.tex: code/estimate/%.do temp/analysis_sample.dta
	$(STATA) $<
output/estimate_%.log: est_%.do $(ESTIMATOR)
	$(STATA) estimate $(subst est_,,$(basename $<))
output/descriptives.log: temp/analysis_sample.dta descriptives.do
	$(STATA) descriptives 
temp/analysis_sample_dyadic.dta: input/fo3-owner-names/country_codes.dta temp/balance-small-clean.dta temp/trade.dta temp/firm_events.dta code/create/analysis_sample.do code/create/event_dummies_firmlevel.do
	$(STATA) code/create/analysis_sample.do
temp/firm_events.dta: input/ceo-panel/ceo-panel.dta temp/balance-small-clean.dta code/create/firm_panel.do
	$(STATA) code/create/firm_panel.do
temp/balance-small-clean.dta: input/merleg-expat/balance-small.dta code/create/balance.do
	$(STATA) code/create/balance.do
temp/trade.dta: input/trade-firm-panel/trade-country-firm.dta temp/balance-small-clean.dta code/create/trade.do
	$(STATA) code/create/trade.do
install:
	$(STATA) code/util/install.do
tables: 
	python3 ~/Dropbox/projects/py/oak/oak.py -p id -c output -o output .
	rm -rf output/regression/_*

