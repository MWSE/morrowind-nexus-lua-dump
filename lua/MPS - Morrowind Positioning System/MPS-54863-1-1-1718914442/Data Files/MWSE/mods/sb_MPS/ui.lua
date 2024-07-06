local ui = {}

local function uiMultiActivatedCallback(e)
    ---@type tes3uiElement
    local MenuMulti_main = e.element:findChild(tes3ui.registerID("MenuMulti_main"))

    ---@type tes3uiElement
    ui.coords = MenuMulti_main:createLabel{text = "placeholder"}
end

function ui.init()
    event.register(tes3.event.uiActivated, uiMultiActivatedCallback, { filter = "MenuMulti" })
end

return ui