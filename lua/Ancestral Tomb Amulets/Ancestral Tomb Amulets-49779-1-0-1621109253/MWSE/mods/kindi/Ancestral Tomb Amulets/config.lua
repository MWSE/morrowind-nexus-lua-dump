    local defaultconfig = {
	modActive = true,
	chance = 7.5,
	maxCycle = 75,
	showSpawn = false,
	showReset = false,
	affectScripted = false,
	dangerFactor = true,
	removeRecycle = false,
	hotkey = true,
	hotkeyOpenTable = {
    keyCode = tes3.scanCode.k
},
	hotkeyOpenModifier = {
    keyCode = tes3.scanCode.lShift
},
    }
local mwseConfig = mwse.loadConfig("ancestral_tomb_amulets", defaultconfig)



return mwseConfig;
