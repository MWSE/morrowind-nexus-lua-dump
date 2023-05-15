
local config = require("longod.DPSTooltips.config").Load()
if config.unittest then
    require("longod.DPSTooltips.test").new().Run(false)
end

local dps = require("longod.DPSTooltips.dps").new(config)
local drawer = require("longod.DPSTooltips.drawer").new(config)

---@param object tes3physicalObject
---@return boolean
local function IsWeapon(object)
    if object then
        if object.objectType == tes3.objectType.weapon
        or object.objectType == tes3.objectType.ammunition then
            return true
        end
    end
    return false
end

---@param e uiObjectTooltipEventData
local function OnUiObjectTooltip(e)
    if config.enable and IsWeapon(e.object) then
        local useBestAttack = tes3.worldController.useBestAttack
        local difficulty = tes3.worldController.difficulty
        local object = e.object ---@cast object tes3weapon
        local data = dps:CalculateDPS(object, e.itemData, useBestAttack, difficulty)
        drawer:Display(e.tooltip, data)
    end
end

local function OnInitialized()
    dps:Initialize()
    drawer:Initialize()
    event.register(tes3.event.uiObjectTooltip, OnUiObjectTooltip, { priority = 0 }) -- TODO tweaks priority
end

event.register(tes3.event.initialized, OnInitialized)

event.register(tes3.event.modConfigReady, require("longod.DPSTooltips.mcm").OnModConfigReady)
