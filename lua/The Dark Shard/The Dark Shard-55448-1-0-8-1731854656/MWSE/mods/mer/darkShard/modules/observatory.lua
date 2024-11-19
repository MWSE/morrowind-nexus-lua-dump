local common = require("mer.darkShard.common")
local logger = common.createLogger("observatory")
local ObservatoryHatch = require("mer.darkShard.components.ObservatoryHatch")
local Telescope = require("mer.darkShard.components.Telescope")
local CraftingFramework = require("CraftingFramework")
local ReferenceManager = CraftingFramework.ReferenceManager
local Quest = require("mer.darkShard.components.Quest")
local DISTANCE_TO_ACTIVATE = 300

local MESH_OVERRIDES = {
    [common.config.static.vanilla_observatory_id] = "afq\\afq_Observatory.nif"
}
for objectId, meshPath in pairs(MESH_OVERRIDES) do
    local object = tes3.getObject(objectId)
    if object then
        logger:debug("Overriding mesh for %s with %s", objectId, meshPath)
        object.mesh = meshPath
    end
end

--Observatory Ref Manager
ReferenceManager:new{
    id = "DarkShard:Observatory",
    onActivated = function(self, reference)
        logger:debug("Observatory onActivated - spawning hatch")
        if reference.data.afq_hasHatch then
            logger:debug(" - already has hatch")
            return
        end
        reference.data.afq_hasHatch = true
        reference.modified = true
        local hatchRef = tes3.createReference{
            object = common.config.static.observatory_hatch_id,
            position = reference.position:copy(),
            orientation = reference.orientation:copy(),
            cell = reference.cell
        }
        ObservatoryHatch.hatchManager:addReference(hatchRef)
        logger:debug(" - added hatch to observatory")
    end,
    requirements = function(self, reference)
        return reference.object.id:lower() == common.config.static.vanilla_observatory_id
    end
}



local function getHatch()
    local hatchRef
    ObservatoryHatch.hatchManager:iterateReferences(function(reference)
        if reference.cell == tes3.player.cell then
            hatchRef = reference
        end
    end)
    return hatchRef
end

---@param e activateEventData
event.register("activate", function(e)
    if e.activator ~= tes3.player then return end
    --activate hatch
    if e.target.object.id:lower() == common.config.static.observatory_hatch_id then
        ObservatoryHatch:new({ reference = e.target }):activate()
    end
end)



local function checkProximity()
    local quest = Quest.quests.afq_main
    if not quest:isActive() then
        return
    end
    local hatchRef = getHatch()
    if not hatchRef then
        logger:trace("hatch not found")
        return
    end
    if hatchRef.cell ~= tes3.player.cell then
        logger:trace("hatch not in the same cell")
        return
    end
    if not ObservatoryHatch.playerHasResonator() then
        logger:trace("Player does not have resonator")
        return
    end

    local attachPoint = hatchRef.sceneNode:getObjectByName(ObservatoryHatch.attachNodeName)
    if not attachPoint then
        logger:trace("Attach point not found")
        return
    end
    local attachPos = attachPoint.worldTransform.translation
    local distance = tes3.player.position:distance(attachPos)
    local hatch = ObservatoryHatch:new({ reference = hatchRef })--[[@as DarkShard.ObservatoryHatch]]
    if distance > DISTANCE_TO_ACTIVATE then
        local doClose = hatch:isOpen()
            and (not hatch:isAnimating())
            and (not hatch:hasResonator())
            and (not Telescope.isActive())

        if doClose then
            logger:debug("Closing hatch due to distance")
            hatch:close()
        end
    else
        if (not hatch:isOpen()) and (not hatch:isAnimating()) then
            logger:debug("Opening hatch due to proximity")
            hatch:open()
            hatch:showOpenMessage()
        end
    end
end

event.register("loaded", function()
    timer.start{
        duration = 1,
        iterations = -1,
        callback = checkProximity
    }
end)