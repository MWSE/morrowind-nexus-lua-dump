-- Dirt'O'Meter: HUD element for Vvardenfell Ablutions
-- Register UI IDs for Dirt'O'Meter
local ids = {
    FillbarBlock = tes3ui.registerID("DirtOMeter:FillbarBlock"),
    Fillbar = tes3ui.registerID("DirtOMeter:Fillbar"),
}

-- Robust logger initialization (supports mwse.Logger.new, mwse.getLogger, or fallback to mwse.log)
local log
if mwse and mwse.Logger and mwse.Logger.new then
    -- Preferred documented API
    log = mwse.Logger.new("DirtOMeter")
elseif mwse and mwse.getLogger then
    -- Older examples in the wild
    log = mwse.getLogger("DirtOMeter")
else
    -- Safe fallback for very old MWSE builds or odd load contexts
    log = {}
    function log:debug(fmt, ...) mwse.log("[DirtOMeter] " .. string.format(fmt, ...)) end
    function log:info(fmt, ...)  mwse.log("[DirtOMeter] " .. string.format(fmt, ...)) end
    function log:warn(fmt, ...)  mwse.log("[DirtOMeter] " .. string.format(fmt, ...)) end
    function log:error(fmt, ...) mwse.log("[DirtOMeter] " .. string.format(fmt, ...)) end
end

-- Single set of cached UI references
local menuMultiFillbarsBlock = nil
local dirtBlock = nil
local dirtFillbar = nil

------------------------------------------------------------
-- Configuration (initial load; kept for compatibility)
------------------------------------------------------------
local initialConfig = (mwse and mwse.loadConfig and mwse.loadConfig("lack_bath_config", { hours = 30 })) or { hours = 30 }
local hoursPerLevel = (initialConfig.hours or 30)

-- Initialize interop after MWSE initialized
local function initialized()
    require("evrex.dirtometer.sephInterop")
end
event.register("initialized", initialized, { priority = -49 })

------------------------------------------------------------
-- Update Dirt'O'Meter fillbar
------------------------------------------------------------
local function updateDirtFillbar(fillbar)
    if not fillbar or not fillbar.widget then
        return
    end

    -- Read Ablutions data
    local abl = tes3.player and tes3.player.data and tes3.player.data.VvardenfellAblutions or {}
    local current = tonumber(abl.currentDirtLevel) or 0
    local max = 5

    -- Clamp display value to valid range
    local displayValue = math.max(0, math.min(current, max))

    -- Apply values to widget
    fillbar.widget.current = displayValue
    fillbar.widget.max = max

    -- Base ivory color (255, 255, 240)
	if not abl.ashy and not abl.blighty then
		fillbar.widget.fillColor = { 1.0, 1.0, 0.94 }
	end
	
    -- Ashy override
    if abl.ashy then
        fillbar.widget.fillColor = { 0.47, 0.47, 0.47 }
    end

    -- Blighty override
    if abl.blighty then
        fillbar.widget.fillColor = { 0.55, 0.20, 0.20 }
    end
end

------------------------------------------------------------
-- Create Dirt'O'Meter fillbar
------------------------------------------------------------
local function createDirtFillbar(element)
    if not element then return nil end

    -- Create the outer block
    local block = element:createRect({
        id = ids.FillbarBlock,
        color = { 0.0, 0.0, 0.0 }
    })
    block.width = 65
    block.height = 12
    block.borderAllSides = 2
    block.alpha = 0.8

    -- Create the actual fillbar widget
    local fillbar = block:createFillBar({ id = ids.Fillbar })
    fillbar.width = 65
    fillbar.height = 12
    fillbar.widget.showText = false

    -- Initial update
    updateDirtFillbar(fillbar)

    --------------------------------------------------------
    -- Create Dirt'O'Meter tooltip
    --------------------------------------------------------
    fillbar:register("help", function()
    local tooltip = tes3ui.createTooltipMenu()

    -- Inner block to force left alignment (tooltip defaults to centered)
    local block = tooltip:createBlock()
    block.flowDirection = "top_to_bottom"
    block.childAlignX = 0.0  -- left align
    block.autoWidth = true
    block.autoHeight = true

    -- Load config (fallback if MCM is unavailable)
    local cfg = (mwse and mwse.loadConfig and mwse.loadConfig("lack_bath_config", { hours = 30 })) or { hours = 30 }
    local localHoursPerLevel = cfg and cfg.hours or 30

    -- Adjectives by dirt level
    local adjectives = {
        [0] = "Clean",
        [1] = "Unwashed",
        [2] = "Messy",
        [3] = "Dirty",
        [4] = "Stinky",
        [5] = "Filthy"
    }

    -- Retrieve Ablutions data safely
    local abl = tes3.player and tes3.player.data and tes3.player.data.VvardenfellAblutions or {}
    local dirtLevel = tonumber(abl.currentDirtLevel) or 0
    local hygiene = tonumber(abl.hygiene) or 0

    -- Calculate progress toward next dirt level
    local progress
    if dirtLevel >= 5 then
        progress = 100
    else
        local hpl = (localHoursPerLevel and localHoursPerLevel > 0) and localHoursPerLevel or 30
        progress = ((hygiene % hpl) / hpl) * 100
        progress = math.floor(progress + 0.5)
    end

    -- Pick adjective
    local adjective = adjectives[dirtLevel] or "Unknown"

    -- First line: adjective
    local adjectiveLabel = block:createLabel{
        text = adjective
    }
    adjectiveLabel.color = tes3ui.getPalette("header_color")

    -- Second line: hygiene loss
    local hygieneLabel = block:createLabel{
        text = string.format("Hygiene Loss: %d%%", progress)
    }
    hygieneLabel.color = tes3ui.getPalette("normal_color")
end)

element:updateLayout()

    return block
end

------------------------------------------------------------
-- Periodic update (aligned with Ablutions: every 5 seconds)
------------------------------------------------------------
event.register("loaded", function()
    timer.start{
        duration = 5,      -- Ablutions updates hygiene every 5 seconds
        iterations = -1,
        type = timer.real,

        -- Named timer to prevent duplicates
        tag = "DirtOMeter:UpdateTimer",

        callback = function()
            if not menuMultiFillbarsBlock then
                return
            end

            -- Lazy lookup: find block once
            if not dirtBlock then
                dirtBlock = menuMultiFillbarsBlock:findChild(ids.FillbarBlock)
            end

            -- Lazy lookup: find fillbar once
            if not dirtFillbar then
                dirtFillbar = menuMultiFillbarsBlock:findChild(ids.Fillbar)
            end

            -- Update if both exist
            if dirtBlock and dirtFillbar then
                dirtBlock.visible = true
                updateDirtFillbar(dirtFillbar)
                menuMultiFillbarsBlock:updateLayout()
            end
        end
    }
end)

------------------------------------------------------------
-- Create Dirt'O'Meter inside MenuMulti
------------------------------------------------------------
local function createMenuMultiDirtFillbar(e)
    if not e.newlyCreated then
        return
    end

    -- Find the UI element that holds the fillbars
    menuMultiFillbarsBlock = e.element:findChild(tes3ui.registerID("MenuMulti_fillbars_layout"))
    if not menuMultiFillbarsBlock then
        return
    end

    -- Create the Dirt'O'Meter fillbar (avoid duplicates)
    if not menuMultiFillbarsBlock:findChild(ids.FillbarBlock) then
        createDirtFillbar(menuMultiFillbarsBlock)
    end

    -- Cache references immediately
    dirtBlock = menuMultiFillbarsBlock:findChild(ids.FillbarBlock)
    dirtFillbar = menuMultiFillbarsBlock:findChild(ids.Fillbar)
end

event.register("uiActivated", createMenuMultiDirtFillbar, { filter = "MenuMulti" })
