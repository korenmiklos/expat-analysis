clear all
use "temp/firm_year_panel.dta"

* managers in first year not classified as new hires
bysort frame_id (year): generate new_hire = (new_local | new_expat) & !(_n==1)
bysort frame_id (year): generate owner_spell = sum(foreign != foreign[_n-1])
bysort frame_id (year): generate manager_spell = sum(new_hire)
bysort frame_id owner_spell (year): generate within_owner_manager_spell = sum(new_hire)

tempvar min max
egen `min' = min(year), by(frame_id owner_spell)
egen `max' = max(year), by(frame_id owner_spell)

generate num_years = `max' - `min' + 1
egen num_managers_hired = sum(new_hire), by(frame_id owner_spell)
egen otag = tag(frame_id owner_spell)
egen start_as_domestic = max((owner_spell==1) & !foreign), by(frame_id)
generate managers_per_year = num_managers_hired / num_years

bysort foreign: summarize num_managers_hired if otag, detail

table owner_spell foreign if otag, c(mean num_managers_hired )
table owner_spell foreign if otag & start_as_domestic , c(mean num_managers_hired )
table owner_spell foreign if otag & start_as_domestic , c(mean num_years )
table owner_spell foreign if otag & start_as_domestic , c(mean managers_per_year )

tabulate within_owner_manager_spell  foreign if start_as_domestic & owner_spell <= 2, column
