--[[
Passing Time While Reading
]]

-- begin configurable parameters
local defaultConfig = {
timePassedMul = 1, -- Multiplier for in-game real time passed while Reading (default: 1)
-- will get your Speechcraft skill percent advancement (0 = disabled).
maxSecReadingForAdvance = 1800, -- the max amount of real time reading (in seconds) to get speechcraft advancement
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

local timePassedMul, maxSecReadingForAdvance, logLevel

local logLevel1, logLevel2

local function updateFromConfig()
	timePassedMul = config.timePassedMul
	if config.expDivide then
		-- convert lecagy setting
		config.maxSecReadingForAdvance = config.expDivide * 100
		config.expDivide = nil
	end
	maxSecReadingForAdvance = config.maxSecReadingForAdvance
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
end

-- set in initialized()
local gameHour

local enterTime
local function loaded()
	enterTime = nil
end

local tes3_skill_speechcraft = tes3.skill.speechcraft

local function afterDestroyBook()
	if not enterTime then
		return
	end
	local ostime = os.time()
	local secondsPassed = ostime - enterTime
	if secondsPassed <= 0 then
		return
	end

	if timePassedMul > 0 then
		local hoursPassed = secondsPassed * timePassedMul / 3600
		local hour = gameHour.value
		hour = hour + hoursPassed
		gameHour.value = hour
		if logLevel1 then
			local s = string.format("%s afterDestroyBook(): secondsPassed = %s, hoursPassed = %s",
				modPrefix, secondsPassed, hoursPassed)
			mwse.log(s)
			if logLevel2 then
				tes3ui.showNotifyMenu(s)
			end
		end
	end

	if maxSecReadingForAdvance > 0 then
		local progress = math.min(secondsPassed / (maxSecReadingForAdvance / 100), 100)
		tes3.mobilePlayer:exerciseSkill(tes3_skill_speechcraft, progress)
		if logLevel1 then
			local s = string.format("%s afterDestroyBook(): tes3.mobilePlayer:exerciseSkill(%s = %s, %s)",
				modPrefix, tes3_skill_speechcraft, tes3.skillName[tes3_skill_speechcraft], progress)
			mwse.log(s)
			if logLevel2 then
				tes3ui.showNotifyMenu(s)
			end
		end
	end
end

local function uiMenuBookActivated(e)
	if not e.newlyCreated then
		return
	end
	local el = e.element
	el:registerAfter('destroy', afterDestroyBook)
	enterTime = os.time()
	if logLevel1 then
		local s = string.format('%s: uiMenuBookActivated("%s") enterTime = %s',
			modPrefix, el.name, enterTime)
		mwse.log(s)
		if logLevel2 then
			tes3ui.showNotifyMenu(s)
		end
	end
end

local function onClose()
	updateFromConfig()
	mwse.saveConfig(configName, config, {indent = false})
end

local function modConfigReady()

	updateFromConfig()

	local optionList = {'Disabled', 'Log', 'Log + MessageBox'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format('%s. %s',
				i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local sideBarPage = template:createSideBarPage({
		label = 'Passing Time While Reading',
		showHeader = true,
		showReset = true,
		postCreate = function(self)
			self.elements.sideToSideBlock.children[1].widthProportional = 1.25
			self.elements.sideToSideBlock.children[2].widthProportional = 0.75
		end
	})

	sideBarPage:createSlider({
		label = 'Time Passed While Reading Multiplier (Timescale)',
		description = [[Multiplier for in-game real time passed while reading.
e.g. 1 = realtime, 30 = like default in-game timescale, 0 = disabled.
After you close the book the time spent reading will be added to current in-game hour.]],
		configKey = 'timePassedMul'
		,min = 0, max = 100, step = 1, jump = 10
	})

	sideBarPage:createSlider({
		label = 'Max reading time for Speechcraft advancement',
		description = [[The max amount of real time reading (in seconds) to get Speechcraft skill advancement
(0 = disabled).]],
		configKey = 'maxSecReadingForAdvance'
		,min = 0, max = 7200, step = 1, jump = 10,
	})

	sideBarPage:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		configKey = 'logLevel'
	})

	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)


event.register('initialized', function ()
	gameHour = tes3.findGlobal('GameHour')
	assert(gameHour)
	event.register('loaded', loaded)
	event.register('uiActivated', uiMenuBookActivated, {filter = 'MenuBook'})
	event.register('uiActivated', uiMenuBookActivated, {filter = 'MenuScroll'})
end, {doOnce = true})
