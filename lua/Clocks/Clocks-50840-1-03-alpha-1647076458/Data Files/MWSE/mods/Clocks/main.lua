local constants = require("Clocks.common.constants")
local helpers = require("Clocks.common.helpers")
local config = require("Clocks.config").config

local availableUISetups = constants.availableUISetups
local numAvailableUISetups = constants.numAvailableUISetups
local relativePositions = constants.enumRelativePositions

local runtimeStatus = {
    isModEnabled = false,
    features = {
        UISetupsCycling = {
            isEnabled = false,
            activeUISetupID = helpers.getActiveUISetupID(config),
            registeredKeyCode = nil
        }
    },
    UI = {
        clocksBlock = {
            ID = tes3ui.registerID("Clocks:ClocksUIBlock"),
            e = nil,
            relativePosition = nil
        }
    }
}

local clocksBlock = runtimeStatus.UI.clocksBlock
local UISetupsCycling = runtimeStatus.features.UISetupsCycling

-- Clocks UI --

local clocksTable = {
    gameClock = {
        name = "Game Clock",
        blockID = tes3ui.registerID("Clocks:gameClockUIBlock"),
        labelID = tes3ui.registerID("Clocks:gameClockLabel"),
        color = { 0.79, 0.64, 0.37 },
        isVisible = function()
                return config.showGameTime
            end,
        getTime = function()
                return helpers.getTime(tes3.getSimulationTimestamp() * 3600.0,
                    { inUTCTime = false, inTwelveHour = config.useTwelveHourTime })
            end
    },
    realClock = {
        name = "Real-Time Clock",
        blockID = tes3ui.registerID("Clocks:realClockUIBlock"),
        labelID = tes3ui.registerID("Clocks:realClockLabel"),
        color = { 0.37, 0.43, 0.79 },
        isVisible = function()
                return config.showRealTime
            end,
        getTime = function()
                return helpers.getTime(os.time(),
                    { inUTCTime = true, inTwelveHour = config.useTwelveHourTime })
            end
    }
}

local function updateClockUI(clock)
    if clocksBlock.e then
        clocksBlock.e:findChild(clock.labelID).text = clock.getTime()
    end
end

local function setRelativePositionClockUI(relativePosition)

    if clocksBlock.e and clocksBlock.relativePosition ~= relativePosition then
        local startingBlock = clocksBlock.e.parent
        local menuMapBlock = startingBlock:findChild(tes3ui.registerID("MenuMap_panel"))

        if relativePosition == relativePositions.above then
            startingBlock:reorderChildren(menuMapBlock, clocksBlock.e, 1)
        elseif relativePosition == relativePositions.below then
            startingBlock:reorderChildren(clocksBlock.e, menuMapBlock, 1)
        else
            mwse.log("[Clocks] Error: Attempted to set invalid UI position")
            return
        end

        clocksBlock.relativePosition = relativePosition
    end
end

local function createClocksUI(e)
    local menuMapBlock  = e.element:findChild(tes3ui.registerID("MenuMap_panel"))
    local startingBlock = menuMapBlock.parent

    startingBlock.flowDirection = "top_to_bottom"
    startingBlock.alpha         = tes3.worldController.menuAlpha

    -- Clock Blocks --

    clocksBlock.e = startingBlock:findChild(clocksBlockID)
    if clocksBlock.e then
        clocksBlock.e:destroy()
    end

    clocksBlock.e = startingBlock:createThinBorder{ id = clocksBlock.ID }

    clocksBlock.e.autoHeight        = true
    clocksBlock.e.autoWidth         = true
    clocksBlock.e.widthProportional = 1
    clocksBlock.e.flowDirection     = "top_to_bottom"

    clocksBlock.relativePosition = relativePositions.below
    setRelativePositionClockUI(config.clocksRelativePosition)

    for _, clockID in ipairs{ "gameClock", "realClock" } do
        local clock = clocksTable[clockID]

        local block = clocksBlock.e:createThinBorder{ id = clock.blockID }

        block.flowDirection = "left_to_right"
        block.height        = 20
        block.width         = 65
        block.visible       = clock.isVisible()
        
        block:register("help", function(e)
            local tooltip = tes3ui.createTooltipMenu()
            tooltip:createLabel{ text = clock.name }
        end)

        local label = block:createLabel{ id = clock.labelID }

        label.absolutePosAlignX = 0.5
        label.color             = clock.color

        updateClockUI(clock)
    end

    startingBlock:getTopLevelMenu():updateLayout()
end

-- UI Setups --

local function cycleUISetups(e)
    if tes3.isKeyEqual{actual = e, expected = config.keyUISetupsCycling} and not tes3.menuMode() then

        if UISetupsCycling.activeUISetupID then
            UISetupsCycling.activeUISetupID = (UISetupsCycling.activeUISetupID % numAvailableUISetups) + 1
        else
            UISetupsCycling.activeUISetupID = 1
        end

        local activeUISetup = availableUISetups[UISetupsCycling.activeUISetupID]
        config.showGameTime = activeUISetup.showGameTime
        config.showRealTime = activeUISetup.showRealTime

        config.save(true)
    end
end

local function disableUISetupsCycling()
    event.unregister(tes3.event.keyDown, cycleUISetups, { filter = UISetupsCycling.registeredKeyCode })

    UISetupsCycling.isEnabled = false
end

local function enableUISetupsCycling()
    local registeredKeyCode = config.keyUISetupsCycling.keyCode

    event.register(tes3.event.keyDown, cycleUISetups, { filter = registeredKeyCode })

    UISetupsCycling.isEnabled = true
    UISetupsCycling.registeredKeyCode = registeredKeyCode
end

-- Timers --

local function startClockTimers()

    for _, clock in pairs(clocksTable) do
        if clock.timer and timer.state ~= timer.expired then
            clock.timer:cancel()
        end
    end

    clocksTable.gameClock.timer = timer.start{
        type     = timer.game,
        duration = 1.0 / 60.0,
        callback = function()
                updateClockUI(clocksTable.gameClock)
            end,
        iterations = -1
    }

    clocksTable.realClock.timer = timer.start{
        type     = timer.real,
        duration = 60,
        callback = function()
                updateClockUI(clocksTable.realClock)
            end,
        iterations = -1
    }

    for _, clock in pairs(clocksTable) do
        if not clock.isVisible() then
            clock.timer:pause()
        end
    end

end

local function startClockTimersDelayed()
    timer.delayOneFrame(startClockTimers)
end

-- Configuration --

local function disableClocks()

    event.unregister("uiCreated", createClocksUI, { filter = "MenuMulti" })
    event.unregister(tes3.event.loaded, startClockTimersDelayed)

    disableUISetupsCycling()

    for _, clock in pairs(clocksTable) do
        if clock.timer then
            clock.timer:cancel()
        end
    end

    if clocksBlock.e then
        clocksBlock.e:destroy()
        clocksBlock.e = nil
    end

    runtimeStatus.isModEnabled = false

    mwse.log("[Clocks] Unregistered")
end

local function enableClocks(isInitialization)

    event.register("uiCreated", createClocksUI, { filter = "MenuMulti" })
    event.register(tes3.event.loaded, startClockTimersDelayed) -- 

    if config.enableUISetupsCycling then
        enableUISetupsCycling()
    end

    if not isInitialization then
        createClocksUI{element = tes3ui.findMenu("MenuMulti")}
        startClockTimersDelayed()
    end

    runtimeStatus.isModEnabled = true

    mwse.log("[Clocks] Registered")
end

local function updateConfiguration()

    -- Enable/Disable Mod --

    if config.enableMod ~= runtimeStatus.isModEnabled then

        if config.enableMod then
            enableClocks(false)
        else
            disableClocks()
        end

    --[[
        Info: We only need to update status of each features if the mod is enabled and its status
        wasn't just updated. In the later case the status of the features has already been updated.
    ]]--
    elseif config.enableMod then

        if config.enableUISetupsCycling ~= UISetupsCycling.isEnabled then
            if config.enableUISetupsCycling then
                enableUISetupsCycling()
            else
                disableUISetupsCycling()
            end
        --[[
            Info: Even if the status of the UI Setup Cycling feature wasn't updated we still need to
            check whether the assigned key combination was updated and register cycleUISetups under
            the correct event. This means that we need to both unregister it from the previous key
            combination and register it under the updated one.
        ]]--
        elseif config.keyUISetupsCycling.keyCode ~= UISetupsCycling.registeredKeyCode then
            disableUISetupsCycling()
            enableUISetupsCycling()
        end

    end

    if clocksBlock.e then
    
        activeUISetupUpdateIsRequired = false

        -- Show/Hide Clocks --

        for _, clock in pairs(clocksTable) do
            local block = clocksBlock.e:findChild(clock.blockID)

            --[[
                Info: In order for the timers to do not run into runtime errors we need to carefully
                pause them before updating the clocks. Primarily, we update the clocks vivsibility
                according to the current settings. Secondary, we update the time and reset the
                timers, if neccessary, to accomodate for any style changes on the clocks and keep
                the interval between the updates constant.
            ]]--
            if not clock.isVisible() then

                if block.visible then
                    block.visible = false
                    activeUISetupUpdateIsRequired = true

                    if clock.timer then
                        clock.timer:pause()
                    end
                end

                updateClockUI(clock)
            else

                if block.visible then
                    if clock.timer then
                        clock.timer:pause()
                    end
                else
                    block.visible = true
                    activeUISetupUpdateIsRequired = true
                end
                updateClockUI(clock)

                if clock.timer then
                    clock.timer:resume()
                    clock.timer:reset()
                end

            end

        end

        -- Update Active UI Setup --

        if activeUISetupUpdateIsRequired then
            activeUISetupID = helpers.getActiveUISetupID(config)
        end

        -- Update Clocks Relative Position --

        setRelativePositionClockUI(config.clocksRelativePosition)
    end
end

-- Initialization --

local function initialized()

    if config.enableMod then
        enableClocks(true)
    end

end

event.register("initialized", initialized)
event.register("Clocks:UpdateConfiguration", updateConfiguration)

require("Clocks.mcm")