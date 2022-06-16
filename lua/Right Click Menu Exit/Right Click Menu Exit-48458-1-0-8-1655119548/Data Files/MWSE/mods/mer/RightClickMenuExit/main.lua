local config = require("mer.RightClickMenuExit.config")
--in order of priority

local function resolveId(id)
    if type(id) == "string" then
        return tes3ui.registerID(id)
    else
        return id
    end
end

--Allow exiting companion share menu like other menus
local function closeMenu()
    local topMenu = tes3ui.getMenuOnTop()
    if not topMenu then
        return
    end
    --first check that at least one of our menus is on top
    --But it may not be the one we "close", i.e inventory menu might
    local menuOnTop
    for _, data in ipairs(config.buttonMapping) do
        if resolveId(topMenu.id) == resolveId(data.menu) then
            menuOnTop = true
            break
        end
    end
    if menuOnTop then
        for _, data in ipairs(config.buttonMapping) do
            local menu = tes3ui.findMenu(data.menu)
            if menu and resolveId(menu.id) == resolveId(data.menu) then
                local closeButton = menu:findChild(data.button)
                if closeButton and closeButton.visible then
                    tes3.worldController.menuClickSound:play()
                    closeButton:triggerEvent("mouseClick")
                end
                return
            end
        end
    end
end

local function onMouseButtonDown(e)
    if e.button == tes3.worldController.inputController.inputMaps[19].code then
        closeMenu()
    end
end

local function onKeyDown(e)
    if e.keyCode ~= 1 and e.keyCode == tes3.worldController.inputController.inputMaps[19].code then
        closeMenu()
    end
end

event.register("keyDown", onKeyDown)
event.register("mouseButtonDown", onMouseButtonDown)
