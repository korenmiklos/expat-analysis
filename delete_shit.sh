# List of source files
source_files=(
    "code/estimate/descriptive.do"
    "code/estimate/manager_level.do"
    "code/estimate/heterogeneity.do"
    "code/estimate/event_study.do"
    "code/estimate/switch.do"
    "code/estimate/selection.do"
    "temp/analysis_sample.dta"
    "code/create/analysis_sample.do"
    "temp/balance-small-clean.dta"
    "temp/firm_events.dta"
    "code/create/firm_panel.do"
    "input/merleg-LTS-MVP/balance.dta"
    "code/create/balance.do"
    "input/ceo-panel/ceo-panel.dta"
    "code/create/ceo_panel.do"
    "code/util/install.do"
)

# Convert the source files array to a set of patterns for grep
patterns=$(printf "|%s" "${source_files[@]}")
patterns=${patterns:1}

# Find and delete files in code/ and temp/ that are not in the source files list
find code/ temp/ -type f | grep -Ev "($(echo $patterns | sed 's|/|\\/|g'))" | xargs rm -f
