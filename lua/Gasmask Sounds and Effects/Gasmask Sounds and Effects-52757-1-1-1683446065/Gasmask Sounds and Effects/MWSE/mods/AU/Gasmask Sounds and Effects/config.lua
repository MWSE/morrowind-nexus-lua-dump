return mwse.loadConfig("Gasmask Sounds and Effects", {
	onOff = true,
	
	-- volume slider
	volume = 90,
	
	-- watch out! when mod first loads it needs to add at least one resistance!
	-- blight resistance
	enableBlight = true,
	blightMag = 10,
	-- common disease resistance
	enableDisease = true,
	diseaseMag = 10,
	-- poison resistance
	enablePoison = false,
	poisonMag = 0,
	
	key = { keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false },

	dropDown = 0,
	gasmasks = {},
})