*testing the number of domestic companies with expats as managers
count if has_expat & !foreign
scalar expat_domestic_number = r(N)
assert expat_domestic_number < 100

*setting the panel
xtset frame_id_numeric year

*testing the number of expat changes (from 0 to 1) when manager spell has not changed simultaneously
count if has_expat == 0 & f1.has_expat  == 1 & manager_spell == f1.manager_spell
scalar no_manager_spell_change = r(N)
assert no_manager_spell_change < 100

*testing the latter without scalars and using a more strict threshold
assert !(has_expat == 0 & f1.has_expat  == 1 & manager_spell == f1.manager_spell)

*testing the number of expat changes (from 1 to 0) when manager spell has not changed simultaneously
count if has_expat == 1 & f1.has_expat == 0 & (manager_spell + 1) != f1.manager_spell
*alternatively (yields the same results):
*count if has_expat == 1 & f1.has_expat == 0 & manager_spell == f1.manager_spell
scalar no_manager_spell_change_reversed = r(N)
assert no_manager_spell_change_reversed < 100 /// setting the threshold below 80 would crash the test currently  

*testing the number of foreign changes when owner spell has not changed simultaneously
count if foreign != f1.foreign & owner_spell == f1.owner_spell
scalar no_owner_spell_change = r(N)
assert no_owner_spell_change < 100
