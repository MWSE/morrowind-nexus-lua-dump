---Thin orchestrator module for repair/degradation/enhancement mechanics.
---Delegates all business logic to services and UI components.

local config = require("mer.RealisticRepair.config")
local EnhancementService = require("mer.RealisticRepair.services.EnhancementService")
local RepairService = require("mer.RealisticRepair.services.RepairService")
local RepairMenuUI = require("mer.RealisticRepair.ui.RepairMenuUI")
local TooltipUI = require("mer.RealisticRepair.ui.TooltipUI")

local logger = mwse.Logger.new{
    logLevel = config.mcm.logLevel,
}

---Check if degradation system is enabled
---@return boolean
local function getEnabled()
    return config.mcm.enableRealisticRepair
        and config.mcm.enableDegradation
end

---Handle MenuRepair activation
event.register("uiActivated", function(e)
    if not getEnabled() then return end
    logger:debug("MenuRepair activated, initializing UI")
    RepairMenuUI.initializeMenu(e.element)
end, { filter = "MenuRepair", priority = -100})

---Handle MenuServiceRepair activation
event.register("uiActivated", function(e)
    if not getEnabled() then return end
    logger:debug("MenuServiceRepair activated, overriding buttons")

    local buttonList = e.element:findChild("MenuServiceRepair_ServiceList"):getContentElement()
    for _, button in ipairs(buttonList.children) do
        local stack = button:getPropertyObject("MenuServiceRepair_Object", "tes3itemStack")
        if stack and stack.variables and #stack.variables >= 1 then
            button:registerBefore("mouseClick", function()
                -- Clear degradation on service repair
                RepairService.clearDegradationForServiceRepair(stack.object, stack.variables[1])
            end)
        end
    end
end, { filter = "MenuServiceRepair", priority = -100})

---Handle repair attempts
event.register("repair", function(e)
    if not getEnabled() then return end
    logger:debug("Repair event for %s", e.item.name)

    -- Delegate to RepairService
    RepairService.handleRepairAttempt(e)

    -- Refresh UI
    local repairMenu = tes3ui.findMenu("MenuRepair")
    if repairMenu then
        RepairMenuUI.refreshMenu(repairMenu)
    end
end)

---Handle item tooltips
event.register("uiObjectTooltip", function(e)
    if not getEnabled() then return end
    TooltipUI.updateTooltip(e)
end, { priority = -100 })


-- ---When damaged, check for any condition reduction on enhanced gear, and apply it to the enhancement instead
-- event.register("damaged", function(e)
--     if not getEnabled() then return end
--     EnhancementService.handleDamagedEvent(e)
-- end)


