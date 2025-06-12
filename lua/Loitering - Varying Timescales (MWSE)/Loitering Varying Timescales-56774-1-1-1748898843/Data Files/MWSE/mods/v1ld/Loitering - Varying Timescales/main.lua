-- v1ld.git@gmail.com, May 2025
-- Reuse freely

local defaultConfig = {
    enableCombatTimescale = true,
    combatTimescale = 6,
    indoorTimescale = 12,
    outdoorTimescale = 24,
    wildernessTimescale = 60,
    enableLoiteringTimescale = true,
    loiterDistance = 25,            -- yards; 1 yard = 64 game units
    loiterCheckInterval = 15,       -- seconds
    loiterTimescale = 12,
    timescaleUpdateInterval = 2,    -- seconds
    displayMessages = false,
    logLevel = "INFO",
}

-- Mod and config file's name
local configPath = "Loitering - Varying Timescales"
local config = mwse.loadConfig(configPath, defaultConfig)

local log = mwse.Logger.new({ modName = configPath })
log:setLogLevel(config.logLevel)

-- The actual timescale updates are done from a timer, these are used to request the updates.
local updateRequestedTime = 0
local newTimescale = 30

local function changeTimescale(new, reason)
    local old = tes3.findGlobal("Timescale").value

    if old == new then
        log:trace("Timescale hasn't changed: %0.f", new)
        return
    end

    log:debug("%s. Timescale %0.f to %0.f", reason, old, new)
    if config.displayMessages then
        tes3.messageBox("%s. Timescale %.0f to %.0f.", reason, old, new)
    end

    updateRequestedTime = os.clock()
    newTimescale = new
end

local timescaleTimer

-- The game can hang in a way that _may_ be due to timescale changing too frequently or updating at the same
-- time as other changes to GMSTs from the same events we use (e.g., cell change or combat start/end). So we
--   1. Do at most one timescale update per interval (has side effect of merging back to back requests)
--   2. Delay setting timescale by the same interval after the event that triggered it
function initTimescaleTimer()
    timescaleTimer = timer.start({
        duration = config.timescaleUpdateInterval,
        type = timer.real,
        iterations = -1,
        callback = function()
            -- Don't do the update if we haven't delayed for the config interval.
            -- If multiple updates happened, we update to the most recent timescale.
            if updateRequestedTime > 0 and (os.clock() - updateRequestedTime) >= config.timescaleUpdateInterval then
                tes3.setGlobal("Timescale", newTimescale)
                updateRequestedTime = 0
                log:trace("Timer set timescale to %f", newTimescale)
            end
        end
    })
end

-- Returns timescale for current cell
local function currentCellTimescale()
    -- Location logic from Necrolesian's excellent Dynamic Timescale mod.
    -- Much thanks to them for their lovely code and permissive license!

    if tes3.player.cell.isInterior then
        -- This check is needed because only interior cells behaving as exteriors (e.g. Mournhold) have a region.
        if tes3.player.cell.region then
            if tes3.player.cell.region.name == "Mournhold Region" then
                return config.outdoorTimescale
            end
        elseif tes3.player.cell.restingIsIllegal then
            -- Town interiors don't allow resting.
            return config.indoorTimescale
        else
            -- If we're inside and can rest it's a dungeon.
            return config.indoorTimescale
        end
    else
        if tes3.player.cell.restingIsIllegal then
            -- A town is defined as an exterior cell where we can't rest.
            return config.outdoorTimescale
        elseif tes3.player.cell.name then
            -- Wilderness cells don't have names.
            return config.outdoorTimescale
        end
    end

    -- We're outside and not in a town or named cell.
    return config.wildernessTimescale
end

-- Loitering

-- Position of player last time we checked for loitering, a tes3vector3 value
local lastPlayerPosition

local function isLoitering()
    if lastPlayerPosition == nil then
        -- Need a tes3vector3 value so make a copy the first time here
        lastPlayerPosition = tes3.mobilePlayer.position:copy()
        return false
    end

    -- 1 yard = 64 game units
    local result = lastPlayerPosition:distance(tes3.mobilePlayer.position) <= (config.loiterDistance * 64)
    log:trace("distance: %f, loiter limit = %f, result = %s", lastPlayerPosition:distance(tes3.mobilePlayer.position), config.loiterDistance * 64, result)

    -- Update in place instead of making new copies (and garbage)
    lastPlayerPosition.x = tes3.mobilePlayer.position.x
    lastPlayerPosition.y = tes3.mobilePlayer.position.y
    lastPlayerPosition.z = tes3.mobilePlayer.position.z

    return result
end

local function onLoiterTimerTick()
    if not config.enableLoiteringTimescale or tes3.player.cell.isInterior or tes3.mobilePlayer.inCombat then return end

    if isLoitering() then
        changeTimescale(config.loiterTimescale, "Loitering")
    else
        changeTimescale(currentCellTimescale(), "Moving on")
    end
end

local loiterTimer

local function initLoiterTimer()
    if loiterTimer then loiterTimer:cancel() end
    loiterTimer = timer.start({ duration = config.loiterCheckInterval, callback = onLoiterTimerTick, iterations = -1, type = timer.simulate })
end

-- Event handlers

local function onGameLoaded(e)
    log:info("Game loaded (log level = %s)", config.logLevel)
    initLoiterTimer()
    initTimescaleTimer()
end
event.register(tes3.event.loaded, onGameLoaded)

local function onCellChanged(e)
    if tes3.mobilePlayer.inCombat then return end

    changeTimescale(currentCellTimescale(), "Location changed")
end
event.register(tes3.event.cellChanged, onCellChanged)

local function onCombatStarted(e)
    if not config.enableCombatTimescale then return end

    if e.actor.actorType == tes3.actorType.player then
        changeTimescale(config.combatTimescale, "Combat started")
    end
end
event.register(tes3.event.combatStarted, onCombatStarted)

local function onCombatStopped(e)
    if not tes3.mobilePlayer.inCombat then
        changeTimescale(currentCellTimescale(), "Combat stopped")
    end
end
event.register(tes3.event.combatStopped, onCombatStopped)

-- MCM

local function registerModConfig()
    local template = mwse.mcm.createTemplate({
        name = configPath,
        config = config,
        defaultConfig = defaultConfig,
        showDefaultSetting = true,
    })

    template:register()
    template:saveOnClose(configPath, config)

    local page = template:createSideBarPage{
        label = configPath,
        description = "Settings for controlling timescales and loitering.\n\nFor convenience is using the settings sliders, all timescales have a minimum value of 1 and a maximum of 120 except for wilderness which can go up to 240. If you wish to use higher values, please change the config file directly (MWSE\\config\\Loitering - Varying Timescales.json).\n\nHover over each setting to learn more about it.",
    }

    local combat = page:createCategory{ label = "Combat Timescale" }

    combat:createYesNoButton{
        label = "Enable combat timescale",
        description = "Automatically change timescale when in combat.",
        configKey = "enableCombatTimescale",
    }
    combat:createSlider{
        label = "Combat timescale",
        description = "The timescale to use when you're in combat.",
        configKey = "combatTimescale",
        min = 1,
        max = 120,
    }

    local timescales = page:createCategory{ label = "Location Timescales" }

    timescales:createSlider{
        label = "Indoor timescale",
        description = "The timescale to use when you're indoors in a building, ruin, cave or dungeon of any kind.",
        configKey = "indoorTimescale",
        min = 1,
        max = 120,
    }
    timescales:createSlider{
        label = "Outdoor timescale",
        description = "The timescale to use when you're outdoors in a named location like a town, stronghold, ruins, etc.",
        configKey = "outdoorTimescale",
        min = 1,
        max = 120,
    }
    timescales:createSlider{
        label = "Wilderness timescale",
        description = "The timescale used when you're in a wilderness area. These are unnamed outdoor locations.\n\nUsing higher values here will make game time pass quicker while moving between towns and other locations, making the world feel larger. Try values like 90 or 120 if you want the journey to feel longer.",
        configKey = "wildernessTimescale",
        min = 1,
        max = 240,
    }

    local loitering = page:createCategory{ label = "Loitering Timescale" }

    loitering:createYesNoButton{
        label = "Enable loitering",
        description = "Loitering is when you are not moving very far in some period of time. This option enables loitering timescales while outdoors, it has no effect indoors.\n\nIt uses the loitering timescale while loitering outdoors to capture the feel of interrupting your journey to look around for a bit, talk to people, etc.",
        configKey = "enableLoiteringTimescale",
    }
    loitering:createSlider{
        label = "Loitering timescale",
        description = "The timescale used when you're loitering.  Low values are recommended, similar to combat or indoor timescales.",
        configKey = "loiterTimescale",
        min = 1,
        max = 120,
    }
    loitering:createSlider{
        label = "Loiter distance (yards)",
        description = "Moving less than this distance in the loiter interval is considered loitering.\n\nSetting it to 0 will require you to be completely still to be loitering.",
        configKey = "loiterDistance",
        min = 0,
        max = 120,
    }
    loitering:createSlider{
        label = "Loitering interval (seconds)",
        description = "Moving around less than the loiter distance in this interval is considered loitering.\n\nThe minimum interval allowed is 10 seconds - the default value is a good one.",
        configKey = "loiterCheckInterval",
        min = 10,
        max = 120,
        callback = function(self)
            -- restart the timer, we may have a new interval
            initLoiterTimer()
        end,
    }

    local misc = page:createCategory{ label = "Miscellaneous" }

    misc:createSlider{
        label = "Timescale update delay interval (seconds)",
        description = "Delay & interval between timescale updates.\n\nThe game doesn't seem to like too frequent timescale updates so the mod imposes a minimum interval between successive timescale updates. This can delay all timescale updates by up to twice this value, so the low default value is a good setting.",
        configKey = "timescaleUpdateInterval",
        min = 1,
        max = 5,
    }

    local info = page:createCategory{ label = "Informational" }

    info:createYesNoButton{
        label = "Display messages when timescale changes",
        description = "Shows a popup when the timescale changes.",
        configKey = "displayMessages",
    }
    info:createDropdown{
        label = "Log level",
        description = "Set the log verbosity level.\n\nUseful for debugging or tracing.",
        options = {
            { label = "TRACE", value = "TRACE" },
            { label = "DEBUG", value = "DEBUG" },
            { label = "INFO",  value = "INFO" },
            { label = "WARN",  value = "WARN" },
            { label = "ERROR", value = "ERROR" },
            { label = "NONE",  value = "NONE" },
        },
        configKey = "logLevel",
        callback = function(self) log:setLogLevel(config.logLevel) end,
    }
end
event.register(tes3.event.modConfigReady, registerModConfig)