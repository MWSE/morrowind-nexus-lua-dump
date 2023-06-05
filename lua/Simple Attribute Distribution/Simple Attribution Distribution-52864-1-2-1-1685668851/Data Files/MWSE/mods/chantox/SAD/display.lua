local log = require("chantox.SAD.log")

local statMenuId = tes3ui.registerID("MenuStat")
local hudMenuId = tes3ui.registerID("MenuMulti")
local healthBarId = tes3ui.registerID("MenuStat_health_fillbar")
local levelLabelId = tes3ui.registerID("MenuStat_level")

local this = {}

---Update "MenuStat_level" label with current player level
---@param menu tes3uiElement
local function updateLevel(menu)
    local label = menu:findChild(levelLabelId)

    if label then
        label.text = tostring(tes3.mobilePlayer.object.level)
    else
        log:error("Failed to locate " .. label.name .. " in menu " .. menu.name)
    end
end

---Update "MenuStat_health_fillbar" with current player health values
---@param menu tes3uiElement
local function updateBars(menu)
    if menu then
        local maxHealth = tes3.mobilePlayer.health.base
        local currentHealth = tes3.mobilePlayer.health.current

        local bar = menu:findChild(healthBarId)

        if bar then
            bar.widget.current = currentHealth
            bar.widget.max = maxHealth
        else
            log:error("Failed to locate " .. bar.name .. " in menu " .. menu.name)
        end
    end
end

---Update player level and health display values
this.update = function ()
    local statMenu = tes3ui.findMenu(statMenuId)
    local hudMenu = tes3ui.findMenu(hudMenuId)

    if statMenu and hudMenu then
        updateLevel(statMenu)
        updateBars(statMenu)
        updateBars(hudMenu)
    else
        log:error("Failed to locate menus MenuStat and MenuMulti.")
    end
end

return this
