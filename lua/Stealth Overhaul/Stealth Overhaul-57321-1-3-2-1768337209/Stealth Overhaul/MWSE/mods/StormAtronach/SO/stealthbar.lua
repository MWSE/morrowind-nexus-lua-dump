-- Register UI for standard HUD.
local ids = {
    FillbarBlock = tes3ui.registerID("SA_StealthBar:FillbarBlock"),
    Fillbar = tes3ui.registerID("SA_StealthBar:Fillbar"),
}

local util = require("StormAtronach.SO.util")

-- Variables
local block = nil
local fillbar = nil
local menuStealthBar
local menuMultiFillbarsBlock

-- Track last update time for decay
local lastUpdateTime = 0
local lastFillbarValue = 0
local decayDelay = 5 -- seconds before decay starts
local decayRate = 20 -- units per second to decay

local function updateFillbar(fillbar)
    local currentTime = tes3.getSimulationTimestamp(false)
    local currentValue = util.fillbarCurrent or 0
    local maxValue = util.fillbarMax or 100
    
    -- Check if the fillbar value has changed (new detection event)
    if currentValue ~= lastFillbarValue then
        lastFillbarValue = currentValue
        lastUpdateTime = currentTime
    end
    
    -- Calculate time since last update
    local timeSinceUpdate = currentTime - lastUpdateTime
    
    -- Apply decay if no updates for decayDelay seconds
    local displayValue = currentValue
    if timeSinceUpdate > decayDelay then
        local decayTime = timeSinceUpdate - decayDelay
        local decayAmount = decayTime * decayRate
        displayValue = math.max(0, currentValue - decayAmount)
        
        -- If fully decayed, reset the util values too
        if displayValue <= 0 then
            util.fillbarCurrent = 0
            lastFillbarValue = 0
        end
    end
    
    fillbar.widget.current = displayValue
    fillbar.widget.max = maxValue

    -- Color gradient: green (safe) to red (detected)
    local green = {r = 0, g = 1, b = 0}
    local red = {r = 1, g = 0, b = 0}
    local percent = maxValue > 0 and math.min(displayValue / maxValue, 1) or 0

    local resultRed = red.r * percent
    local resultGreen = green.g * (1 - percent)

    fillbar.widget.fillColor = { resultRed, resultGreen, 0.0 }
end

local function createFillbar(element)
    local block = element:createRect({
        id = ids.FillbarBlock,
        color = {0.0, 0.0, 0.0}
    })
    block.width = 65
    block.height = 12
    block.borderAllSides = 2
    block.alpha = 0.8

    local fillbar = block:createFillBar({id = ids.Fillbar})
    fillbar.width = 65
    fillbar.height = 12
    fillbar.widget.showText = false
    updateFillbar(fillbar)

    -- Uncomment to have bar on top of menu.
    -- element:reorderChildren(0, -1, 1)

    element:updateLayout()

    return block
end


event.register(tes3.event.simulate, function()
    if (not menuMultiFillbarsBlock) then return end
    if not block then
        block = menuMultiFillbarsBlock:findChild(ids.FillbarBlock)
    end
    if not fillbar then
        fillbar = menuMultiFillbarsBlock:findChild(ids.Fillbar)
    end
    

    if block and fillbar then
        -- Only show when sneaking
        local isSneaking = tes3.mobilePlayer.isSneaking
        block.visible = isSneaking

        if isSneaking then
            updateFillbar(fillbar)
            menuMultiFillbarsBlock:updateLayout()
        end
    end

    
end)

local function createMenuMultiBloodFillbar(e)
    if not e.newlyCreated then return end

    -- Find the UI element that holds the fillbars.
    menuMultiFillbarsBlock = e.element:findChild(tes3ui.registerID("MenuMulti_fillbars_layout"))
    menuStealthBar = createFillbar(menuMultiFillbarsBlock)
    block = menuMultiFillbarsBlock:findChild(ids.FillbarBlock)
     fillbar = menuMultiFillbarsBlock:findChild(ids.Fillbar)
end
event.register("uiActivated", createMenuMultiBloodFillbar, { filter = "MenuMulti" })