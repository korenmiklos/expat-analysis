STATA = stata -b do
ESTIMATOR = temp/analysis_sample.dta estimate.do regram.do
.PHONY: all
SPECS = descriptive manager_level heterogeneity event_study switch selection

all: $(foreach spec,$(SPECS),output/estimate_$(spec).log) output/descriptives.log

output/estimate_%.log: est_%.do $(ESTIMATOR)
	$(STATA) estimate $(subst est_,,$(basename $<))
output/descriptives.log: temp/analysis_sample.dta descriptives.do
	$(STATA) descriptives 
temp/analysis_sample.dta: temp/balance-small-clean.dta temp/firm_events.dta code/create/analysis_sample.do code/create/event_dummies_firmlevel.do
	$(STATA) code/create/analysis_sample.do
temp/firm_events.dta: input/ceo-panel/ceo-panel.dta temp/balance-small-clean.dta code/create/firm_panel.do
	$(STATA) code/create/firm_panel.do
temp/balance-small-clean.dta: input/merleg-expat/balance-small.dta code/create/balance.do
	$(STATA) code/create/balance.do
install:
	$(STATA) install.do
tables: 
	python3 ~/Dropbox/projects/py/oak/oak.py -p id -c output -o output .
	rm -rf output/regression/_*

