STATA = stata -b do
ESTIMATOR = temp/analysis_sample.dta estimate.do regram.do
.PHONY: all
SPECS = descriptive manager_level heterogeneity event_study switch selection

all: output/table/selection.tex output/table/diffindiff.tex output/table/cross_section.tex output/table/exporter.tex output/table/dummies.tex

output/table/%.tex: code/estimate/%.do temp/analysis_sample.dta
	$(STATA) $<
output/estimate_%.log: est_%.do $(ESTIMATOR)
	$(STATA) estimate $(subst est_,,$(basename $<))
output/descriptives.log: temp/analysis_sample.dta descriptives.do
	$(STATA) descriptives 
temp/analysis_sample.dta: input/fo3-owner-names/country_codes.dta temp/balance-small-clean.dta temp/firm_events.dta code/create/analysis_sample.do code/create/event_dummies_firmlevel.do code/create/survival.do
	$(STATA) code/create/analysis_sample.do
temp/firm_events.dta: input/ceo-panel/ceo-panel.dta input/nceo-panel/nceo-panel.dta temp/balance-small-clean.dta temp/manager_country.dta code/create/firm_panel.do
	$(STATA) code/create/firm_panel.do
temp/manager_country.dta: input/ceo-panel/ceo-panel.dta
	$(STATA) code/create/manager_country.do
temp/balance-small-clean.dta: input/merleg-expat/balance-small.dta input/ceo-panel/ceo-panel.dta code/create/balance.do code/create/emp_clean.do
	$(STATA) code/create/balance.do
install:
	$(STATA) code/util/install.do
tables: 
	python3 ~/Dropbox/projects/py/oak/oak.py -p id -c output -o output .
	rm -rf output/regression/_*

