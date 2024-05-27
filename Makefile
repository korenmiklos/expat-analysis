STATA = stata -b do
ESTIMATOR = temp/analysis_sample.dta estimate.do regram.do
.PHONY: all copy

# Define the source directories and the target directory
FIGURES_DIR = output/figure
TABLES_DIR = output/table
TARGET_DIR = text/overleaf/tab_fig


all: regression.log figures.log
%.log: code/estimate/%.do temp/analysis_sample.dta 
	$(STATA) $<
copy:
	@mkdir -p $(TARGET_DIR)
	@cp -r $(FIGURES_DIR)/* $(TARGET_DIR)/
	@cp -r $(TABLES_DIR)/* $(TARGET_DIR)/
	@echo "All files from $(FIGURES_DIR) and $(TABLES_DIR) have been copied to $(TARGET_DIR)."
temp/analysis_sample.dta: temp/balance-small-clean.dta temp/firm_events.dta code/create/analysis_sample.do
	$(STATA) code/create/analysis_sample.do
temp/firm_events.dta: temp/ceo-panel.dta temp/balance-small-clean.dta code/create/firm_panel.do
	$(STATA) code/create/firm_panel.do
temp/balance-small-clean.dta: input/merleg-LTS-MVP/balance.dta code/create/balance.do
	$(STATA) code/create/balance.do
temp/ceo-panel.dta: input/ceo-panel/ceo-panel.dta code/create/ceo_panel.do
	$(STATA) code/create/ceo_panel.do
install:
	$(STATA) code/util/install.do

