return mwse.loadConfig("Infectious Sixth House", {
	onOff = true,
	key = { keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false },
	dropDown = 0,
	slider = 30,
	sliderpercent = 30,
	cells = {},
	blocked = { 
		["ash woe blight"] = true, 
		["ash-chancre"] = true,
		["black-heart blight"] = true,
		["chanthrax blight"] = true
	},
})
