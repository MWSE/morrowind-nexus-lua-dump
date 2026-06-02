local menuMode = require("scripts.quest_guider_lite.ui.menuMode")
local controllerScrollTimer = require("scripts.quest_guider_lite.input.controllerScroll")

local this = {}

---@type table<string, any>
this.activeMenus = {}


this.onMenuModeActivated = nil
this.onMenuModeDeactivated = nil


local function deactivateMenuMode()
    menuMode.deactivate()
    controllerScrollTimer.stop()
    if this.onMenuModeDeactivated then
        this.onMenuModeDeactivated()
    end
end


function this.registerMenu(menuId, menu)
    if this.activeMenus[menuId] then
        this.activeMenus[menuId]:close()
    end

    this.activeMenus[menuId] = menu
    controllerScrollTimer.start()
end


function this.unregisterMenu(menuId)
    this.activeMenus[menuId] = nil
    if not this.hasActiveMenus() and menuMode.isActive() then
        deactivateMenuMode()
    end
end


function this.destroyMenu(menuId)
    local menuEl = this.activeMenus[menuId]
    if not menuEl then return end

    if menuEl.menu and menuEl.menu.layout then
        menuEl:close()
    end
    this.activeMenus[menuId] = nil

    if not this.hasActiveMenus() and menuMode.isActive() then
        deactivateMenuMode()
    end
end


function this.getMenu(menuId)
    local el = this.activeMenus[menuId]
    if not el or not el.menu or not el.menu.layout then
        return
    end

    return el
end


function this.destroyAllMenus()
    for id, handler in pairs(this.activeMenus) do
        handler:close()
        this.activeMenus[id] = nil
    end
    if menuMode.isActive() then
        deactivateMenuMode()
    end
end


function this.hasActiveMenus()
    for _, _ in pairs(this.activeMenus) do
        return true
    end
    return false
end


function this.activateMenuMode()
    menuMode.activate()
    if this.onMenuModeActivated then
        this.onMenuModeActivated()
    end
end


function this.triggerMethod(method, params)
    for _, menu in pairs(this.activeMenus) do
        if menu[method] then
            menu[method](table.unpack(params))
        end
    end
end


function this.onMouseReleaseCallback(buttonId)
    for _, menu in pairs(this.activeMenus) do
        if menu.onMouseClick then
            menu:onMouseClick(buttonId)
        end
    end
end


function this.onMouseWheelCallback(vertical, isController)
    for _, menu in pairs(this.activeMenus) do
        if isController and menu.onControllerScroll then
            menu:onControllerScroll(vertical)
        elseif menu.onMouseWheel then
            menu:onMouseWheel(vertical)
        end
    end
end


return this