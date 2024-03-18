args y treatment1 treatment2 group time
local pre 4
local post 4

tempvar yg eventtime ever1 ever2 treatment first_treatment dy

egen `ever1' = max(`treatment1'), by(`group')
egen `ever2' = max(`treatment2'), by(`group')

* no two treatment can happen to the same group
assert !( (`ever1'==1) & (`ever2'==1) )
generate `treatment' = `treatment1' | `treatment2'
egen `first_treatment' = min(cond(`treatment', `time', .)), by(`group')
* everyone receives treatment
assert !missing(`first_treatment')

generate `eventtime' = `time' - `first_treatment'

egen `yg' = mean(cond(`eventtime' == -1, `y', .)), by(`group')
generate `dy' = `y' - `yg'

generate ATET = inrange(`eventtime', 0, `post') & (`ever2' == 1)
reghdfe `dy' ATET `ever1' `ever2' if inrange(`eventtime', -`pre', `post'), a(`eventtime') cluster(`group')
drop ATET

forvalues t = `pre'(-1)2 {
    generate byte event_m`t' = (`eventtime' == -`t') & (`ever2' == 1)
}
forvalues t = 0/`post' {
    generate byte event_`t' = (`eventtime' == `t') & (`ever2' == 1)
}
reghdfe `dy' event_*  if inrange(`eventtime', -`pre', `post'), a(`eventtime') cluster(`group')
drop event_*