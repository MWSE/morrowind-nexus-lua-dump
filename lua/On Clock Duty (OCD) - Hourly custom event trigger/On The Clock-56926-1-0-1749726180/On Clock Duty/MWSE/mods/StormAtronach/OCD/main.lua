
-- Start of timer setup logic
local config_default = {
    enabled = true,
    logLevel = "error"
}
local config = mwse.loadConfig("sa_ocd", config_default)
local log = mwse.Logger.new(({modName = "OCD"}))



-- Looping function
local function hourlyTimer()
    if not config.enabled then return end
    local currentHourFP = tes3.worldController.hour.value
    local currentHour = math.round(currentHourFP,0)
    log:trace("Hourly timer event launched. Current hour %s, current hour full precision %s", currentHour, currentHourFP)
    event.trigger("sa_ocd:hourly_timer", {hour = currentHour, hourFullPrecision = currentHourFP})
end

-- Starts the timer and calls the function for the first time
local function setupHourlyTimer()
    -- Starts a timer that will run every hour in-game
    timer.start({
        type = timer.game,
        duration = 1, -- 1 hour in-game time
        iterations = -1, -- Repeat indefinitely
        callback = hourlyTimer
    })
    hourlyTimer() -- Calls the function that fires the event for the first time
    print("OCD - Hourly timer started")
end

-- We fire this function on the loaded event, after all non-persisten timers have been cancelled
local function onLoadCallback()
    log.level = config.logLevel
    -- We check how long until the next hour
    local currentTS = tes3.getSimulationTimestamp()
    local hourRemainder = math.clamp(1 - math.round(currentTS % 1,2), 0,1)
    -- Had a weird issue where hourRemainder was "nil", so introducing a failsafe
    if hourRemainder and hourRemainder >= 0 then
    timer.start({
        type = timer.game,
        duration = hourRemainder,
        callback = setupHourlyTimer,
    })
    end

end
event.register("loaded", onLoadCallback, {priority = -1000})



--- MCM Registration
event.register("modConfigReady", function()
    local template = mwse.mcm.createTemplate({ name = "On Clock Duty" })
    template:saveOnClose("sa_ocd", config)

    local page = template:createSideBarPage({
        label = "Settings",
        description = "This mod creates an event called sa_ocd:hourly_timer, with a payload of 'hour': an integer that shows the current in-game hour, and 'hourFullPrecision', a float with the full precision of the hour for testing purposes.",
    })

    page:createOnOffButton({
        label = "Mod enabled",
        description = "Enables or disables this mod",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = config}

    })
        page:createLogLevelOptions({
        config = config,
        configKey = "logLevel",
        logger = log
    })
    mwse.mcm.register(template)
end)