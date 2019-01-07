STATA = stata -b do
ESTIMATOR = temp/analysis_sample.dta estimate.do regram.do
.PHONY: all
SPECS = descriptive manager_level heterogeneity event_study switch selection

all: $(foreach spec,$(SPECS),output/estimate_$(spec).log) output/descriptives.log

output/estimate_%.log: est_%.do $(ESTIMATOR)
	$(STATA) estimate $(subst est_,,$(basename $<))
output/descriptives.log: temp/analysis_sample.dta descriptives.do
	$(STATA) descriptives 
temp/analysis_sample.dta: temp/balance-small.dta temp/firm_ceo_panel.dta variables.do
	$(STATA) variables
temp/firm_ceo_panel.dta: temp/manager_panel.dta firm_panel.do fill_in_ceo.do
	$(STATA) firm_panel
temp/balance-small.dta: input/balance-small/balance-sheet-1992-2016-small.dta select_sample.do
	$(STATA) select_sample
temp/manager_panel.dta: temp/managers.dta temp/positions.dta manager_panel.do 
	$(STATA) manager_panel
temp/managers.dta temp/positions.dta: input/manager_position/pos5.csv input/motherlode/manage.csv read_data.do
	$(STATA) read_data
install:
	stata -b ssc install g538schemes, replace all
tables: 
	python3 ~/Dropbox/projects/py/oak/oak.py -p id -c output -o output .
	rm -rf output/regression/_*

