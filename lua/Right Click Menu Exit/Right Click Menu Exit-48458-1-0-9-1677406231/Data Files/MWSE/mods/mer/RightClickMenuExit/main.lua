local config = require("mer.RightClickMenuExit.config")

local function closeMenu()
    local menuOnTop = tes3ui.getMenuOnTop()
    if not menuOnTop then
        return
    end
    local rootUI = menuOnTop.parent
    -- iterate over rootUI.children in reverse order
    for i = #rootUI.children, 1, -1 do
        --find registered menu with close button
        local menu = rootUI.children[i]
        if menu.visible then
            local menuData = config[menu.name]
            if menuData then
                local button = menu:findChild(menuData.closeButton)
                if button and button.visible then
                    tes3.worldController.menuClickSound:play()
                    button:triggerEvent("mouseClick")
                    return
                end
            end
        end
    end
end

local function onMouseButtonDown(e)
    if tes3ui.menuMode() then
        if e.button == tes3.worldController.inputController.inputMaps[19].code then
            closeMenu()
        end
    end
end
event.register("mouseButtonDown", onMouseButtonDown)

local function onKeyDown(e)
    if tes3ui.menuMode() then
        if e.keyCode ~= 1 and e.keyCode == tes3.worldController.inputController.inputMaps[19].code then
            closeMenu()
        end
    end
end
event.register("keyDown", onKeyDown)
