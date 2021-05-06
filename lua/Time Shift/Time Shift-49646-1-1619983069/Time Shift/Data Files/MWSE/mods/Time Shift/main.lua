local cf = mwse.loadConfig("Time Shift", {KEY = {keyCode = 56}, mb = 3, fat = 30, mag = 50, mc = 5, sc = 20, sou = true})
local p, mp, wc, MMana		local TS = false

local function SIMTS() local dt = wc.deltaTime		if mp.fatigue.current > dt * cf.sc and mp.magicka.current > dt * cf.mc then
	mp.fatigue.current = mp.fatigue.current - dt * cf.sc
	if cf.mc > 0 then mp.magicka.current = mp.magicka.current - dt * cf.mc		MMana.current = mp.magicka.current end
	wc.deltaTime = wc.deltaTime * cf.mag/100
else event.unregister("simulate", SIMTS)	if cf.sou then tes3.playSound{sound = "illusion cast"} end		TS = false end end

local function KEYDOWN(e) if not tes3ui.menuMode() then		if TS then event.unregister("simulate", SIMTS)	if cf.sou then tes3.playSound{sound = "illusion cast"} end	TS = false
else event.register("simulate", SIMTS)	if cf.sou then tes3.playSound{sound = "illusion hit"} end	TS = true end end end		event.register("keyDown", KEYDOWN, {filter = cf.KEY.keyCode})

local function MOUSEBUTTONDOWN(e) if not tes3ui.menuMode() and e.button == cf.mb then	if TS then event.unregister("simulate", SIMTS)	if cf.sou then tes3.playSound{sound = "illusion cast"} end	TS = false
else event.register("simulate", SIMTS)	if cf.sou then tes3.playSound{sound = "illusion hit"} end	TS = true end end end		event.register("mouseButtonDown", MOUSEBUTTONDOWN)

local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		wc = tes3.worldController		MMana = tes3ui.findMenu(-526):findChild(-865).widget	
	event.unregister("simulate", SIMTS)		TS = false
end		event.register("loaded", loaded)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Time Shift")	tpl:saveOnClose("Time Shift", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createKeyBinder{variable = var{id = "KEY", table = cf}, label = "Time shift key (requires restarting the game)"}
p0:createSlider{label = "Time shift mouse button: 1 - right, 2 - middle", min = 1, max = 6, step = 1, jump = 1, variable = var{id = "mb", table = cf}}
p0:createSlider{label = "The speed of time (the lower the slower)", min = 5, max = 90, step = 1, jump = 5, variable = var{id = "mag", table = cf}}
p0:createSlider{label = "Mana cost per second", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "mc", table = cf}}
p0:createSlider{label = "Stamina cost per second", min = 10, max = 100, step = 1, jump = 5, variable = var{id = "sc", table = cf}}
p0:createYesNoButton{label = "Enable time shift sound", variable = var{id = "sou", table = cf}}
end		event.register("modConfigReady", registerModConfig)