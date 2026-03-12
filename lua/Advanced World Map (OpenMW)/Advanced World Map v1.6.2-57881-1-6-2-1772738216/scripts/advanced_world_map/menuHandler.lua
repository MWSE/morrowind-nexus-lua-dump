
local this = {}

---@type table<string, any>
this.activeMenus = {}


function this.registerMenu(menuId, menu)
    if this.activeMenus[menuId] then
        this.activeMenus[menuId]:close()
    end

    this.activeMenus[menuId] = menu
end


function this.destroyMenu(menuId)
    local menuEl = this.activeMenus[menuId]
    if not menuEl then return end

    if menuEl.menu and menuEl.menu.layout then
        menuEl:close()
    end
    this.activeMenus[menuId] = nil
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
end


function this.hasActiveMenus()
    for _, _ in pairs(this.activeMenus) do
        return true
    end
    return false
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