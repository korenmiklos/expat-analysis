# Analysis for Koren, Miklós and Álmos Telegdy, "Expatriate Managers and Firm Performance."

Requires confidential micro data to be placed in the `input` folder, like so:
```
input/balance-small/balance-sheet-1992-2016-small.dta
input/manager_position/pos5.csv
input/motherlode/branch.csv
input/motherlode/hq.csv
input/motherlode/manage.csv
input/motherlode/own.csv
input/motherlode/site.csv
```

Then run `make install` to install the [beautiful 538 graph schemes](https://danbischof.com/2017/09/05/a-final-stata-gift-538-schemes/). After that, `make` does all the data cleaning and runs all the analysis, like so:
```Makefile
STATA = stata -b do
output/estimate.log: temp/analysis_sample.dta estimate.do event_study.do regram.do
	$(STATA) estimate
temp/analysis_sample.dta: input/balance-small/balance-sheet-1992-2016-small.dta temp/firm_ceo_panel.dta variables.do
	$(STATA) variables
temp/firm_ceo_panel.dta: temp/manager_panel.dta firm_panel.do fill_in_ceo.do
	$(STATA) firm_panel
temp/manager_panel.dta: temp/managers.dta temp/positions.dta manager_panel.do 
	$(STATA) manager_panel
temp/managers.dta temp/positions.dta: input/manager_position/pos5.csv input/motherlode/manage.csv read_data.do
	$(STATA) read_data
install:
	stata -b ssc install g538schemes, replace all
```
Intermediate files after data cleaning, sample and variable definition etc are stored in the `temp` folder.

Regression output is save as "regression grammar," see `regram.do` (at some point I will document this as a package). Regressions are saved into tables, columns and rows within columns. Each cell has a point estimate, standard deviation, t-stat and p-value saved in [YAML](https://en.wikipedia.org/wiki/YAML) format. Just see `output/regression/baseline_intensity/columns/exporter.yaml`, for example. Having these numbers, you can create the table you want in the format you want.