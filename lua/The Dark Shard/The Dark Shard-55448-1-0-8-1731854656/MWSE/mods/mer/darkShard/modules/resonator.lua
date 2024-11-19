local common = require("mer.darkShard.common")
local logger = common.createLogger("resonator")
local Resonator = require("mer.darkShard.components.Resonator")
local CraftingFramework = require("CraftingFramework")
local StaticActivator = CraftingFramework.StaticActivator
local ReferenceManager = CraftingFramework.ReferenceManager

StaticActivator.register{
    name = "Chromatic Resonator",
    objectId = Resonator.object_id,
    additionalUI = function(self, parent)
        local node = self.nodeLookingAt
        if not node then return end
        local wheelColor = Resonator.getWheelColor(node)
        if not wheelColor then return end
        local text = string.format("Wheel: %s", wheelColor)
        parent:createLabel{text = text}
    end,
    onActivate = function(reference)
        local resonator = Resonator:new({ reference = reference })--[[@as DarkShard.Resonator]]
        resonator:activate()
    end
}

local validIds = {
    [Resonator.object_id] = true,
}
ReferenceManager:new{
    id = "DarkShard:Resonator",
    onActivated = function(self, reference)
        logger:debug("Activating resonator - updating nodes")
        Resonator:new({ reference = reference }):updateNodes()
    end,
    requirements = function(self, reference)
        return validIds[reference.object.id:lower()]
    end
}

---@param e simulateEventData
event.register("simulate", function(e)
    local delta = e.delta
    for node, data in pairs(common.config.tempData.resonatorAnimatingNodes) do
        logger:debug("Animating resonator node %s", node)
        local startingPhase = data.startingPhase
        logger:debug(" - startingPhase: %s", startingPhase)
        local targetPhase = data.targetPhase
        logger:debug(" - targetPhase: %s", targetPhase)
        local timePassed = data.timePassed + delta
        logger:debug(" - timePassed: %s", timePassed)
        local duration = data.duration
        logger:debug(" - duration: %s", duration)
        local newPhase = data.startingPhase + (targetPhase - data.startingPhase) * (timePassed / duration)
        newPhase = math.clamp(newPhase, 0, 1)
        logger:debug(" - newPhase: %s", newPhase)
        node:update{ time = newPhase, controllers = true}
        if timePassed >= duration then
            logger:debug("Animation finished, removing node")
            node:update{ time = targetPhase, controllers = true}
            common.config.tempData.resonatorAnimatingNodes[node] = nil
        else
            data.timePassed = timePassed
        end
    end
end)

event.register("DarkShard:TelescopeCalibrated", function()
    local resonator = Resonator.findNearbyResonator{
        distance = 500,
        position = tes3.player.position,
        cell = tes3.player.cell
    }
    if resonator then
        logger:debug("Telescope is calibrated, removing resonator")
        resonator:removeResonator()
    end
end)