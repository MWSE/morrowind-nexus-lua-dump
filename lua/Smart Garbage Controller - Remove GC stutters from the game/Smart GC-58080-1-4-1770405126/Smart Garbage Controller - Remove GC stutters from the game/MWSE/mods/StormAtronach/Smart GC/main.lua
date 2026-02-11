--- Configuration stuff
local default_config = {
    enabled         = true,
    logLevel        = mwse.logLevel.info,
    delayOnLoaded   = 5,    -- Seconds we wait after loading to stop the GC
    cutOutMemory    = 2750, -- Memory above which the danger of OOM flag gets set to true 
    cutInMemory     = 1500, -- Memory below which the danger of OOM flag gets set to false
    memCheckDelta   = 2,    -- Time between memory checks on simulate
    pause           = 100,
    stepMultiplier  = 500,
    targetFramerate = 72,
    cellChangeTrigger = 250 
}
local name          = "SA_Smart_GC"
local version       = "1.3"
local config        = mwse.loadConfig(name, default_config) ---@cast config table
config.confPath     = name
config.default      = default_config
config.version      = version

local log = mwse.Logger.new{
    modName = "Smart GC",
    level   = config.logLevel
}

-- Variables
local dangerOfOOM   = false
local currentMemory = 0
local bytesToMB     = 1/1024/1024
local activateTimer = nil
local cellChangeCooldown = false
local lastSimulated = 0

--Helper functions
local function makeSureGCisRunning()
    log:debug("GC restarted")
    collectgarbage("restart")
end

local function stopGC()
    if tes3ui.menuMode() then return end
    if dangerOfOOM then return end
    log:debug("GC stopped")
    collectgarbage("stop")
end

local function collect()
    log:debug("GC collection cycle started")
    collectgarbage("collect")
end
local function collectAndStop()
    if tes3ui.menuMode() then return end
    log:debug("GC collection cycle started")
    collectgarbage("collect")
    timer.start({
        type = timer.simulate,
        duration = 1,
        callback = stopGC
    })
end

-- 0. If we are at risk of out of memory errors, set the flag to true. When we go below the cut in, reset it to false
-- If we are at risk and the GC is not running, restart it
local function safetyCheck()
    -- We check if the mod is enabled, and if not, make sure the GC is running
    if not config.enabled then makeSureGCisRunning() return end

    currentMemory = mwse.getVirtualMemoryUsage()*bytesToMB

    local wasDanger = dangerOfOOM
    if not dangerOfOOM then
        dangerOfOOM = currentMemory > config.cutOutMemory
    else
        dangerOfOOM = currentMemory > config.cutInMemory
    end

    -- Log state changes
    if dangerOfOOM and not wasDanger then
        log:info("OOM danger triggered - memory at %d MB (threshold: %d MB)", currentMemory, config.cutOutMemory)
    elseif wasDanger and not dangerOfOOM then
        log:info("OOM danger cleared - memory at %d MB (threshold: %d MB)", currentMemory, config.cutInMemory)
    end

    if dangerOfOOM then
        makeSureGCisRunning()
    end
end

-- 1. If vanity mode is active, restart the GC
local function restartOnVanityMode()
    if tes3ui.menuMode() then return end
    if tes3.mobilePlayer.animationController.vanityCameraEnabled == 0 then return end
    log:debug("GC restarted on vanity camera")
    makeSureGCisRunning()
end


-- 2. On loaded, we stop the GC after config.delayOnLoaded seconds
--- @param e loadedEventData
local function loadedCallback(e)
    -- Make sure the game has started (even if it is silly in this event)
    if not tes3.player then return end

    -- Start the safetyCheck timer
    timer.start( {
        type = timer.simulate,
        duration = config.memCheckDelta,
        callback = safetyCheck,
        iterations = -1
    })

    -- Set garbage collection values.
    collectgarbage("setpause",   config.pause)
    collectgarbage("setstepmul", config.stepMultiplier)

    -- Reset state on load
    dangerOfOOM = false

    -- Start the vanity timers
    timer.start{
        type = timer.simulate,
        duration = 5,
        callback = restartOnVanityMode,
        iterations = -1}

    -- As a safety check
    if not config.enabled then makeSureGCisRunning() return end

    -- Now, give some time for the game to clean up the junk, and stop the GC
    log:debug("Scheduling GC stop in %d seconds", config.delayOnLoaded)
    timer.start{
        type = timer.simulate,
        duration = config.delayOnLoaded,
        callback = stopGC
    }
end
event.register(tes3.event.loaded, loadedCallback)

-- 3. On Menu Enter, we reenable it
local lastTime = 0
--- @param e menuEnterEventData
local function menuEnterCallback(e)
    -- Make sure the game has started
    if not tes3.player then return end
    -- We check if the mod is enabled, and if not, make sure the GC is running
    if not config.enabled then makeSureGCisRunning() return end

    log:debug("Restarting GC on menu enter")
    makeSureGCisRunning()
    local now = tes3.getSimulationTimestamp(false)
    -- Wait a little before triggering too many collects - I think this was causing the fades from bushcrafting to not work smoothly when bushcrafting too many stuff
    if now - lastTime > 5 then
        timer.delayOneFrame(collect)
        lastTime = now
    end

end
event.register(tes3.event.menuEnter, menuEnterCallback)

-- 4. When we exit menu mode, stop it again
--- @param e menuExitEventData
local function menuExitCallback(e)
    -- Make sure the game has started
    if not tes3.player then return end
    -- We check if the mod is enabled, and if not, make sure the GC is running
    if not config.enabled then makeSureGCisRunning() return end
    -- If we are in danger of OOM, do not stop the garbage collector
    if dangerOfOOM then log:debug("GC kept running on menu exit due to OOM danger") return end
    log:debug("GC stopped on menu exit")
    stopGC()
end
event.register(tes3.event.menuExit, menuExitCallback)

-- 5. When we change from exterior to interior, or from interior to exterior, run one full cycle
local function resetCooldown()
    cellChangeCooldown = false
end

local function cellChangeGC()
        collectgarbage("collect")
        timer.start({
            type = timer.real,
            duration = 2,
            callback = stopGC
        })

        timer.start({
            type = timer.real,
            duration = 4,
            callback = resetCooldown
        })
end

--- @param e cellChangedEventData
local function cellChangedCallback(e)
    -- Make sure the game has started
    if not tes3.player then return end
    -- Don't run on startup
    if not e.previousCell then return end
    -- We check if the mod is enabled, and if not, make sure the GC is running
    if not config.enabled then makeSureGCisRunning() return end
    if cellChangeCooldown then log:debug("Avoiding spam on cell change") return end
    log:debug("GC collect cycle run on cell change")
    local outside = e.previousCell.isOrBehavesAsExterior and e.cell.isOrBehavesAsExterior
    if collectgarbage("count") > config.cellChangeTrigger and outside then
        cellChangeGC()
    elseif not outside then
        collectAndStop()
    end
    cellChangeCooldown = true
end
event.register(tes3.event.cellChanged, cellChangedCallback)

-- 6. When we activate a reference, do a collection cycle
--- @param e activateEventData
local function activateCallback(e)
    if e.activator ~= tes3.player then return end
    -- If timer exists and is still active, reset it
    if activateTimer and activateTimer.state == timer.active then
        activateTimer:reset()
        log:debug("Activation timer reset")
        return
    end
    log:debug("GC collect cycle scheduled on the activate event")
    if collectgarbage("count") > config.cellChangeTrigger then
        activateTimer = timer.start({
            type = timer.real,
            duration = 5,
            callback =  function()
                        collectAndStop()
                        activateTimer = nil
                        end
        })
    end
end
event.register(tes3.event.activate, activateCallback)


-- Let's try the budget thing
--[[
local targetFrameTime = 1/config.targetFramerate
-- local lastSimulated = 0
local collectionLimit = 0.003
local os_clock = os.clock
--- @param e simulatedEventData
local function simulatedCallback(e)
    if not config.enabled then return end
    -- First we calculate how much time we have to do garbage collection
    local count = 0
    if os_clock() - lastSimulated > collectionLimit then
        local done = false
        while not done and targetFrameTime - (os_clock() - lastSimulated) > collectionLimit do
            done = collectgarbage("step",0)
            --count = count + 1
        end
    end
    --tes3ui.showNotifyMenu("Performed %d cleaning steps", count)
    stopGC()
    lastSimulated = os_clock()
end
event.register(tes3.event.simulated, simulatedCallback, {priority = 9001})
]]

--- MCM stuff
--- @param self mwseMCMInfo|mwseMCMHyperlink
local function center(self)
	self.elements.info.absolutePosAlignX = 0.5
end

local authors = {
	{
		name = "Storm Atronach",
		url = "https://next.nexusmods.com/profile/StormAtronach0",
	},
}

local modDescription =
    "Smart Garbage Controller v" .. version .. "\n\n" ..
    "A lightweight mod that optimizes Lua's garbage collector to reduce frame stutters during gameplay.\n\n" ..
    "How it works:\n" ..
    "- During gameplay: GC is paused to prevent random stutters\n" ..
    "- In menus: GC runs freely since performance isn't critical\n" ..
    "- Cell transitions: A full GC cycle runs when moving between interior and exterior cells\n" ..
    "- Memory safety: If memory usage gets too high, GC automatically restarts\n\n" ..
    "Made by:"

--- Adds default text to sidebar. Has a list of all the authors that contributed to the mod.
--- @param container mwseMCMSideBarPage
local function createSidebar(container)
	container.sidebar:createInfo({
		text =  modDescription,
		postCreate = center,
	})
	for _, author in ipairs(authors) do
		container.sidebar:createHyperlink({
			text = author.name,
			url = author.url,
			postCreate = center,
		})
	end
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Smart GC",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
        onClose = function()
            if config.cutInMemory > config.cutOutMemory then
                tes3ui.showNotifyMenu("Cut in has to be lower than cut out!! Restoring default values")
                config.cutOutMemory = config.default.cutOutMemory
                config.cutInMemory = config.default.cutInMemory
            end
            log.level = config.logLevel
            -- Set garbage collection values.
            collectgarbage("setpause",   config.pause)
            collectgarbage("setstepmul", config.stepMultiplier)
            mwse.saveConfig(config.confPath, config)
            targetFrameTime = 1 / config.targetFramerate
        end
	})
	template:register()

	local page = template:createSideBarPage({
		label = "Settings",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

    page:createOnOffButton{
        label = "Enable Mod",
        description = "Toggle the mod on or off.",
        configKey = "enabled",
    }

    page:createSlider{
        label = "Delay after load (seconds)",
        description = "How many seconds to wait after loading a save before stopping the GC.",
        min = 0, max = 10, step = 1, jump = 1,
        configKey = "delayOnLoaded",
    }

    page:createSlider{
        label = "Cell change lua memory threshold (MB)",
        description = "Memory usage by lua (in MB) above which a collect cycle will be triggered on cell change",
        min = 1000, max = 4000, step = 100, jump = 100,
        configKey = "cellChangeTrigger",
    }

    page:createSlider{
        label = "Cut-out memory threshold (MB)",
        description = "Memory usage (in MB) above which the danger of OOM flag gets set to true and GC restarts. Has to be higher than Cut-in",
        min = 1000, max = 4000, step = 100, jump = 100,
        configKey = "cutOutMemory",
    }

    page:createSlider{
        label = "Cut-in memory threshold (MB)",
        description = "Memory usage (in MB) below which the danger of OOM flag gets reset to false. Has to be lower than Cut-out",
        min = 1000, max = 4000, step = 100, jump = 100,
        configKey = "cutInMemory",
    }

    page:createSlider{
        label = "Memory check interval (seconds)",
        description = "How often to check memory usage. Lower values are more responsive but use slightly more CPU.",
        min = 0.5, max = 5, step = 0.5, jump = 0.5, decimalPlaces = 1,
        configKey = "memCheckDelta",
    }

    page:createLogLevelOptions{
        configKey = "logLevel"
    }

    page:createSlider{
        label = "GC Pause",
        description = "DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING!\n"..
                      "Controls how long the GC waits before starting a new collection cycle.\n" ..
                      "Higher values make the GC run less frequently, but result in longer frame spikes.",
        min = 50, max = 300, step = 10, jump = 50,
        configKey = "pause",
    }

    page:createSlider{
        label = "GC Step Multiplier",
        description = "DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING!\n"..
                      "Controls how much work the GC does for each step relative to memory allocation.\n" ..
                      "Higher values make the GC more aggressive but may cause more stuttering.\n" ..
                      "Lower values spread the work over more steps.",
        min = 100, max = 1000, step = 100, jump = 200,
        configKey = "stepMultiplier",
    }
        page:createSlider{
        label = "Target frame rate",
        description = "The target frame rate",
        min = 30, max = 240, step = 1, jump = 30,
        configKey = "targetFramerate",
    }

    mwse.log("Smart GC v%s loaded", version)
end
event.register("modConfigReady", registerModConfig)