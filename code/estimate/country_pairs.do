* owner-manager related countries based on frequency
local AT DE
local CH AT DE
local DE AT CH 
local NL AT DE GB
local US AT DE GB

local owner_countries AT CH DE NL US

generate byte related_country = 0
foreach oc in `owner_countries' {
	egen rc = max(Lowner & (country=="`oc'")), by(frame_id_numeric year)
	foreach country in ``oc'' {
		replace related_country = 1 if (rc == 1) & (country=="`country'")
	}
	drop rc
}
