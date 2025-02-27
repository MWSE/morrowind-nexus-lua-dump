--[[
Passing Time While Reading
]]

-- begin configurable parameters
local defaultConfig = {
	timePassedMul = 1, -- Multiplier for in-game real time passed while Reading (default: 1)
	expDivide = 18, -- the amount of real time reading (in seconds) divided by this number will get your Speechcraft skill percent advancement (0 = disabled).
	logLevel = 0,
}
-- end configurable parameters

local author = 'abot'
local modName = 'PTWR'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local gameHourObj -- set in modConfigReady

local enterTime

local function loaded()
	enterTime = nil
end
event.register('loaded', loaded)

local tes3_skill_speechcraft = tes3.skill.speechcraft
---local speechcraftExp -- set in modConfigReady()

local function afterDestroyBook()
	if not enterTime then
		return
	end
	local ostime = os.time()
	local secondsPassed = ostime - enterTime
	--[[
	---local osclock = os.clock()
	local secondsPassed2 = osclock - enterTime2
	local delta = secondsPassed - secondsPassed2
	---if math.abs(delta) > 0.001 then
		mwse.log("os.time() = %s sec, os.clock() = %s sec", ostime, osclock)
		mwse.log("delta os.time() = %s sec, delta os.clock() = %s sec, diff = %s", secondsPassed, secondsPassed2, delta)
	---end
	]]
	if secondsPassed <= 0 then
		return
	end

	if config.timePassedMul > 0 then
		local hoursPassed = secondsPassed * config.timePassedMul / 3600
		local hour = gameHourObj.value
		hour = hour + hoursPassed
		gameHourObj.value = hour
		if config.logLevel > 0 then
			local s = string.format("%s afterDestroyBook(): secondsPassed = %s, hoursPassed = %s", modPrefix, secondsPassed, hoursPassed)
			mwse.log(s)
			if config.logLevel > 1 then
				tes3ui.showNotifyMenu(s)
			end
		end
	end
	if config.expDivide > 0 then
		local progress = math.min(secondsPassed / config.expDivide, 100)
		tes3.mobilePlayer:exerciseSkill(tes3_skill_speechcraft, progress)
		if config.logLevel > 0 then
			local s = string.format("%s afterDestroyBook(): tes3.mobilePlayer:exerciseSkill(%s = %s, %s)",
				modPrefix, tes3_skill_speechcraft, tes3.skillName[tes3_skill_speechcraft], progress)
			mwse.log(s)
			if config.logLevel > 1 then
				tes3ui.showNotifyMenu(s)
			end
		end
	end
end

---local enterTime2
local function uiMenuBookActivated(e)
	if not e.newlyCreated then
		return
	end
	e.element:registerAfter('destroy', afterDestroyBook)
	enterTime = os.time()
	---enterTime2 = os.clock()
	if config.logLevel > 0 then
		local s = string.format('%s: uiMenuBookActivated("%s") enterTime = %s',
			modPrefix, e.element.name, enterTime)
		mwse.log(s)
		if config.logLevel > 1 then
			tes3ui.showNotifyMenu(s)
		end
	end
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	gameHourObj = tes3.findGlobal('GameHour')
	assert(gameHourObj)

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		mwse.saveConfig(configName, config, {indent = false})
	end

	local preferences = template:createSideBarPage({
		label='Preferences',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.25
			self.elements.sideToSideBlock.children[2].widthProportional = 0.75
		end
	})
	preferences.sidebar:createInfo({text = mcmName})

	local controls = preferences:createCategory({})

	controls:createSlider({
		label = 'Time Passed While Reading Multiplier (Timescale)',
		description = [[Multiplier for in-game real time passed while reading.
e.g. 1 = realtime, 30 = like default in-game timescale, 0 = disabled.
After you close the book the time spent reading will be added to current in-game hour.]],
		variable = createConfigVariable('timePassedMul')
		,min = 0, max = 100, step = 1, jump = 10
	})

	controls:createSlider({
		label = 'Speechcraft experience reading divider',
		description = [[The amount of real time reading (in seconds) divided by this number
will get your Speechcraft skill percent advancement (0 = disabled).
e.g. A 9 divider will get you 100% = one full point skill advancement with 900 seconds = 15 minutes spent reading,
a 1 divider will get the same with 100 sec = 1.66 minutes spent reading,
a 18 divider will get the same with 1800 sec = 30 minutes spent reading and so on.
Max skill advancement for a book reading is capped at 100% = 1 full skill point max per book read.]],
		variable = createConfigVariable('expDivide')
		,min = 0, max = 100, step = 1, jump = 5
	})

	controls:createDropdown{
		label = "Log level:",
		description =
[[The amount/type of debug information logged to MWSE.log and/or screen.
0. Disabled
1. Log
2. Log + MessageBox
]],
		options = {
			{ label = "0. Disabled", value = 0 },
			{ label = "1. Log", value = 1 },
			{ label = "2. Log + MessageBox", value = 2 },
		},
		variable = createConfigVariable('logLevel')
	}

	mwse.mcm.register(template)
	mwse.log( json.encode(config, {indent = false}) )

	---local speechcraft = tes3.getSkill(tes3_skill_speechcraft)
	---speechcraftExp = speechcraft.actions[1]

	event.register('uiActivated', uiMenuBookActivated, {filter = 'MenuBook'})
	event.register('uiActivated', uiMenuBookActivated, {filter = 'MenuScroll'})

	mwse.log("%s: modConfigReady", modPrefix)
end
event.register('modConfigReady', modConfigReady)