* testing the number of domestic companies with expats as managers
count if has_expat & !foreign
scalar expat_domestic_number = r(N)
assert expat_domestic_number < 100

* setting the panel
xtset frame_id_numeric year

* testing the number of expat changes (from 0 to 1) when manager spell has not changed simultaneously
count if has_expat == 0 & f1.has_expat == 1 & ceo_spell == f1.ceo_spell
scalar no_ceo_spell_change = r(N)
assert no_ceo_spell_change < 100

* testing the latter without scalars and using a more strict threshold
assert !(has_expat == 0 & f1.has_expat  == 1 & ceo_spell == f1.ceo_spell)

* testing the number of expat changes (from 1 to 0) when manager spell has not changed simultaneously
count if has_expat == 1 & f1.has_expat == 0 & (ceo_spell + 1) != f1.ceo_spell
count if has_expat == 1 & f1.has_expat == 0 & ceo_spell == f1.ceo_spell
* alternatively (yields the same results):
*count if has_expat == 1 & f1.has_expat == 0 & ceo_spell == f1.ceo_spell
scalar no_ceo_spell_change_reversed = r(N)
assert no_ceo_spell_change_reversed < 100

* testing the number of foreign changes when owner spell has not changed simultaneously
* FIX ME: was 0 and164 with the new foreign (which changed two and years around the first expat and foreign owner)
* NOTE: Owner spell was moved to select_sample but foreign is changed in create_firm_panel. Should I just move owner_spell creation code just back to create_analysis_sample?
count if foreign != f1.foreign & owner_spell == f1.owner_spell
scalar no_owner_spell_change = r(N)
assert no_owner_spell_change < 100

