local common = require("mer.RightClickMenuExit.common")
local logger = common.createLogger("buttons")
local config = common.config

local MAIN_MENUS = {
    "MenuMulti",
    "MenuStat",
    "MenuInventory",
    "MenuMagic",
    "MenuMap",
}

local function checkAndReOpenInventory()
    if not config.mcm.reopenInventory then return end
    local inventoryMenu = tes3ui.findMenu("MenuInventory")
    -- if its open, we'll need to open  it again after closing
    if inventoryMenu and inventoryMenu.visible then
        timer.delayOneFrame(function()
            for _, menuId in ipairs(MAIN_MENUS) do
                local menuToOpen = tes3ui.findMenu(menuId)
                if menuToOpen and not menuToOpen.visible then
                    logger:debug("  * reopening %s", menuId)
                    menuToOpen.visible = true
                end
            end
            tes3ui.enterMenuMode("MenuInventory")
        end)
    end
end

local function clickButton(button)
    if config.mcm.enableClickSound then
        logger:debug("  * playing sound")
        tes3.worldController.menuClickSound:play()
    end
    button:triggerEvent("mouseClick")
end

local function closeMenu()
    local menuOnTop = tes3ui.getMenuOnTop()
    if not menuOnTop then
        return
    end
    logger:debug("Closing Menu")
    local rootUI = menuOnTop.parent
    -- iterate over rootUI.children in reverse order
    for i = #rootUI.children, 1, -1 do
        --find registered menu with close button
        local menu = rootUI.children[i]
        logger:debug("- %s", menu.name)
        if menu.visible then
            logger:debug("  * is visible")
            local menuData = config.registeredButtons[menu.name]
            if menuData then
                logger:debug("  * is registered")
                local button = menu:findChild(menuData.closeButton)
                if menuData.closeButton and button and button.visible then
                    logger:debug("  * has close button, closing menu")
                    clickButton(button)
                    checkAndReOpenInventory()
                    return
                end
            else
                ---A non registered menu sits on top, cancel
                logger:debug("  * is not registered")
                return
            end
        end
    end
end

---@param e mouseButtonDownEventData
local function onMouseButtonDown(e)
    if not config.mcm.enableRightClickExit then return end
    if not tes3ui.menuMode() then return end
    if e.button == tes3.worldController.inputController.inputMaps[19].code then
        closeMenu()
    end
end
event.register("mouseButtonDown", onMouseButtonDown)

local function onKeyDown(e)
    if not config.mcm.enableRightClickExit then return end
    if not tes3ui.menuMode() then return end
    if e.keyCode ~= 1 and e.keyCode == tes3.worldController.inputController.inputMaps[19].code then
        closeMenu()
    end
end
event.register("keyDown", onKeyDown)