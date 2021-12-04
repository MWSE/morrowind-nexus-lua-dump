--[[
Passing Time While Reading
]]

-- begin configurable parameters
local defaultConfig = {
	timePassedMul = 1,
}
-- end configurable parameters

local author = 'abot'
local modName = 'PTWR'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

local lastMenuId
local enterTime

local gameHour -- set in modConfigReady

local function updateHour()
	local hoursPassed = (os.clock() - enterTime) * config.timePassedMul / 3600
	local hour = gameHour.value
	hour = hour + hoursPassed
	gameHour.value = hour
end

local function menuEnter(e)
	lastMenuId = e.menu.id
	enterTime = os.clock()
	---mwse.log("%s: menuEnter lastMenuId = %s", modPrefix, lastMenuId )
end

local function menuExit()
	if not lastMenuId then
		return
	end
	---mwse.log("%s: menuExit lastMenuId = %s", modPrefix, lastMenuId )
	lastMenuId = nil
	updateHour()
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	gameHour = tes3.findGlobal('GameHour')
	assert(gameHour)

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		mwse.saveConfig(configName, config, {indent = false})
	end

	local preferences = template:createSideBarPage({
		label='Preferences',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.2
			self.elements.sideToSideBlock.children[2].widthProportional = 0.8
		end
	})
	preferences.sidebar:createInfo({text = mcmName})

	local controls = preferences:createCategory({})
	
	local desc = "Multiplier for Time Passed While Reading (default: 1)."

	controls:createSlider({
		label = 'Time Passed While Reading Multiplier',
		description = desc,
		variable = createConfigVariable('timePassedMul')
		,min = 1, max = 100, step = 1, jump = 5
	})

	mwse.mcm.register(template)
	mwse.log( json.encode(config, {indent = false}) )

	event.register('menuEnter', menuEnter, { filter = 'MenuBook' })
	event.register('menuExit', menuExit)
	mwse.log("%s: modConfigReady", modPrefix)
end
event.register('modConfigReady', modConfigReady)