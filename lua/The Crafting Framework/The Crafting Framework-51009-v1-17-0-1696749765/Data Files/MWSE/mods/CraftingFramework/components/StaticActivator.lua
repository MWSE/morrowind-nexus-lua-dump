local Util = require("CraftingFramework.util.Util")
local Indicator = require("CraftingFramework.components.Indicator")
local logger = Util.createLogger("StaticActivator")
local config = require("CraftingFramework.config")

---@class CraftingFramework.StaticActivator : CraftingFramework.StaticActivator.data
---@field indicator CraftingFramework.Indicator
---@field reference tes3reference
local StaticActivator = {
    registeredObjects = {}
}

---@class CraftingFramework.StaticActivator.data : CraftingFramework.Indicator.data
---@field onActivate fun(reference: tes3reference) @Called when the object is activated

---@param data CraftingFramework.StaticActivator.data
function StaticActivator.register(data)
    logger:assert(type(data.objectId) == "string", "objectId must be a string")
    logger:assert(type(data.onActivate) == "function", "onActivate must be a function. If you want a tooltip without an activator, register an Indicator instead")
    if StaticActivator.registeredObjects[data.objectId:lower()] then
        logger:warn("Object %s is already registered", data.objectId)
        --merge
        table.copy(data, StaticActivator.registeredObjects[data.objectId:lower()])
    else
        StaticActivator.registeredObjects[data.objectId:lower()] = data
    end
    Indicator.register(data)
    logger:debug("Registered %s as StaticActivator", data.objectId)
end

function StaticActivator:new(reference)
    if not reference then return end
    local data = StaticActivator.registeredObjects[reference.baseObject.id:lower()]
    if not data then return end
    local staticActivator = table.copy(data)
    staticActivator.indicator = Indicator:new{
        reference = reference,
        craftedOnly = data.craftedOnly,
    }
    staticActivator.reference = reference
    setmetatable(staticActivator, self)
    self.__index = self
    return staticActivator
end

local isBlocked
local function blockScriptedActivate(e)
    logger:debug("BlockScriptedActivate doBlock: %s", e.doBlock)
    isBlocked = e.doBlock
end
event.register("BlockScriptedActivate", blockScriptedActivate)

function StaticActivator:doActivate()
    logger:debug("doActivate()")

    local isCrafted = self.reference
        and self.reference.data
        and self.reference.data.crafted
    if self.craftedOnly and not isCrafted then
        logger:debug("not crafted, skipping activation")
        return
    end
    logger:debug("Activating %s", self.reference.id)
    local data = StaticActivator.registeredObjects[self.reference.baseObject.id:lower()]
    if data then
        event.trigger("BlockScriptedActivate", { doBlock = true })
        timer.delayOneFrame(function()
            event.trigger("BlockScriptedActivate", { doBlock = false })
        end)
        data.onActivate(self.reference)
    end
end

function StaticActivator.doTriggerActivate()
    logger:debug("doTriggerActivate()")
    local activationBlocked =
        config.persistent.positioningActive
        or isBlocked
        or tes3ui.menuMode()
        or tes3.mobilePlayer.controlsDisabled
    if not activationBlocked then
        logger:debug("Triggered Activate")
        local ref = StaticActivator.updateIndicator{
            eventName = "CraftingFramework:StaticActivation"
        }
        local staticActivator = StaticActivator:new(ref)
        if staticActivator then
            staticActivator:doActivate()
        end
    end
end

---@class CraftingFramework.StaticActivator.updateIndicator.params
---@field eventName string? The name of the event to trigger when a reference is found

---@param e CraftingFramework.StaticActivator.updateIndicator.params
function StaticActivator.updateIndicator(e)
    local result = StaticActivator.getLookingAt()
    if e.eventName then
        ---@class CraftingFramework.StaticActivator.eventData
        local eventData = {
            rayResult = result,
            reference = result and result.reference
        }
        event.trigger(e.eventName, eventData)
    end
    if result and result.reference then
        local indicator = Indicator:new{ reference = result.reference }
        if indicator then
            indicator:update(result.object)
        else
            Indicator.disable()
        end
        return result.reference
    end
    logger:trace("No reference found, disabling tooltip")
    Indicator.disable()
end

function StaticActivator.getLookingAt()
    local eyePos = tes3.getPlayerEyePosition()
    local eyeDirection = tes3.getPlayerEyeVector()
    --If in menu, use cursor position
    if tes3ui.menuMode() then
        local inventory = tes3ui.findMenu("MenuInventory")
        local inventoryVisible = inventory and inventory.visible == true
        if inventoryVisible then
            local cursor = tes3.getCursorPosition()
            ---@diagnostic disable-next-line: undefined-field
            local camera = tes3.worldController.worldCamera.camera
            eyePos, eyeDirection = camera:windowPointToRay{cursor.x, cursor.y}
        end
    end
    if not (eyeDirection or eyeDirection) then return end
    local activationDistance = tes3.getPlayerActivationDistance()
    local result = tes3.rayTest{
        position = eyePos,
        direction = eyeDirection,
        ignore = { tes3.player },
        maxDistance = activationDistance,
    }
    return result
end

return StaticActivator