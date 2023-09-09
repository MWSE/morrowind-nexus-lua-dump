local config = require("autoloot.config")
local logger = require("logging.logger")
local log = logger.new{
    name = "Autoloot",
    logLevel = config.logLevel or "INFO",
    logToConsole = false,
    includeTimestamp = true,
}
local loot = include("autoloot.loot")
autoLootTimer = nil

--[[
	TODO:
		register/unregister on mod on/off 
]]--
local function checkIsManualLootActivated(e)
	if config.enableMod == true then
		return
	end
	if e.keyCode ~= config.hotkey.keyCode then
		return
	end
    if config.hotkey.isControlDown and not e.isControlDown then
		return
    end
	if config.hotkey.isShiftDown and not e.isShiftDown then
		return
    end
	if config.hotkey.isAltDown and not e.isAltDown then
		return
    end
	loot.run()
	return false
end

event.register("keyDown", checkIsManualLootActivated)

local function timerCallback()
    loot.run()
end

function startAutoLootTimer()
	if not config.enableMod or not config.enableTimer then
		log:debug('startAutoLootTimer timer disabled')
		return
	end
	
	if tes3.mobilePlayer == nill or tes3.mobilePlayer.cell == nil then
		log:info('startAutoLootTimer game not loaded')
		return
	end

	local ms = config.timer / 1000;
	autoLootTimer = timer.start({ type = timer.real, iterations = -1, duration = ms, callback = timerCallback })
	log:info(tostring('startAutoLootTimer started: "%s" ms "%s" s'):format(config.timer, ms))
end

event.register(tes3.event.initialized, function()
	GUI_Sneak_Multi = tes3ui.registerID("MenuMulti")
	GUI_Sneak_Icon = tes3ui.registerID("MenuMulti_sneak_icon")
		
end)

event.register(tes3.event.loaded, startAutoLootTimer)
	
local function registerModConfig()
    require("autoloot.mcm")
end

-- local modConfig = require("Autoloot.mcm")
-- modConfig.config = config
-- local function registerModConfig()
	-- mwse.registerModConfig("Autoloot", modConfig)
-- end
-- event.register("modConfigReady", registerModConfig)

-- local function registerModConfig()
    -- local page = require("autoloot.ExtraExclusionsPage")
    -- local mcmData = require("autoloot.mcm3")
    -- local modData = mwse.mcm.registerModData(mcmData)
    -- mwse.registerModConfig(mcmData.name, modData)
-- end


event.register("modConfigReady", registerModConfig)