-- Register UI for standard HUD.
local ids = {
    FillbarBlock = tes3ui.registerID("EncumbranceBar:FillbarBlock"),
    Fillbar = tes3ui.registerID("EncumbranceBar:Fillbar"),
}


local function updateFillbar(fillbar)
    local current = tes3.mobilePlayer.encumbrance.current
    local max = tes3.mobilePlayer.encumbrance.base

    local target = tes3.getPlayerTarget()
    if target then
        if target.object.weight then
            if target.stackSize then
                current = current + target.object.weight * target.stackSize
            else
                current = current + target.object.weight
            end
        end
    end


    fillbar.widget.current = current
    fillbar.widget.max = max

    local green = {r = 0, g = 1, b = 0}
    local red = {r = 1, g = 0, b = 0}
    local percent = math.min(current/max, 1)

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
    --element:reorderChildren(0, -1, 1)

    element:updateLayout()

    return block
end


local menuMultiFillbarsBlock
event.register("loaded", function()
    timer.start({
        duration = .01,
        iterations = -1,
        type = timer.real,
        callback = function()
            if (not menuMultiFillbarsBlock) then return end

            -- Destroy existing element.
            local fillbar = menuMultiFillbarsBlock:findChild(ids.Fillbar)
            if (fillbar) then
                updateFillbar(fillbar)
            end

            menuMultiFillbarsBlock:updateLayout()
        end
    })
end)

local function createMenuMultiBloodFillbar(e)
    if not e.newlyCreated then return end

    -- Find the UI element that holds the fillbars.
    menuMultiFillbarsBlock = e.element:findChild(tes3ui.registerID("MenuMulti_fillbars_layout"))
    menuEncumbranceBar = createFillbar(menuMultiFillbarsBlock)
end
event.register("uiActivated", createMenuMultiBloodFillbar, { filter = "MenuMulti" })