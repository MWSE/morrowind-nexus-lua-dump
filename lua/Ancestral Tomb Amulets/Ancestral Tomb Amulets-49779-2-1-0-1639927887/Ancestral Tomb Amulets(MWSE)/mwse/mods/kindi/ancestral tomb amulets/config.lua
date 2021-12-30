    local defaultconfig = {
	undeadprotectwearer = false,
	autoequipamuletattacked = false,
	unlockdisarmtomb = false,
	familymembersfriendlyonce = false,
	modActive = true,
	chance = 7.5,
	maxCycle = 75,
	useBestCont = false,
	tombRaider = false,
	showSpawn = false,
	showReset = false,
	affectScripted = false,
	dangerFactor = true,
	removeRecycle = true,
	deepestTomb = false,
	blockedCells = {
	['Akulakhan\'s Chamber'] = true,
	['Dagoth Ur, Facility Cavern'] = true,
	['Sotha Sil, Dome of Sotha Sil'] = true
	},
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
