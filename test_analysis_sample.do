*testing the number of domestic companies with expats as managers
count if has_expat & !foreign
scalar expat_domestic_number = r(N)
assert expat_domestic_number < 100

*setting the panel
xtset frame_id_numeric year

*testing the number of expat changes when manager spell has not changed simultaneously
count if has_expat == 0 & f1.has_expat  == 1 & manager_spell == f1.manager_spell
scalar no_spell_change = r(N)
assert no_spell_change < 100

*testing the latter without scalars and using a more strict threshold
assert !(has_expat == 0 & f1.has_expat  == 1 & manager_spell == f1.manager_spell)
