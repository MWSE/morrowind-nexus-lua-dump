local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("Verticaliser")
local ReferenceManager = require("CraftingFramework.components.ReferenceManager")

--[[
 This class performs "verticalisation", which involves resetting the vertical orientation
    of specific parts of a mesh after the mesh has been rotated. This is useful for meshes that
    are placed on uneven surfaces, but which have parts that need to remain completely upright.
    Examples include the wooden supports and flame particles of a campfire, the hanging lantern
    on a tent, and so on.

 To make a mesh verticalise-compatible, simply add a node in your mesh called ALIGN_VERTICAL,
    and place any parts of the mesh that need to be verticalised as children of that node.
    Ensure the origin point of the ALIGN_VERTICAL node is at the point you wish the child
    elements to rotate.

 To enable verticalisation, simply call `include("CraftingFramework.components.Verticaliser")`
    in your mod's main.lua file and ensure Crafting Framework is listed as a requirement of your mod.
]]
---@class Verticaliser
local Verticaliser = {
    UPDATE_FREQUENCY_SECONDS = 0.05,
    VERTICAL_NODE_NAMES = {
        ALIGN_VERTICAL = true,
        COLLISION_VERTICAL = true,
    },
}

---@class Verticalise.nodeData
---@field node niNode
---@field position tes3vector3

--The reference manager that keeps track of references that need to be verticalised
---@class VerticaliserReferenceManager : CraftingFramework.ReferenceManager
---@field references table<tes3reference, Verticalise.nodeData[]>
Verticaliser.referenceManager = ReferenceManager:new{
    id = "Verticalised Refs",
    requirements = function(self, reference)
        if not reference.sceneNode then return false end
        local verticalNodes = Verticaliser.getVerticalNodes(reference.sceneNode)
        return verticalNodes ~= nil
    end,
    onActivated = function(self, reference)
        Verticaliser.registerReferenceForVerticalisation(reference)
    end,
}

--Starts a timer that periodically checks for references that need to be verticalised
function Verticaliser.startTimer()
    Verticaliser.verticaliseTimer = timer.start{
        type = timer.simulate,
        duration = Verticaliser.UPDATE_FREQUENCY_SECONDS,
        iterations = -1,
        callback = function()
            Verticaliser.referenceManager:iterateReferences(function(ref, verticalNodes)
                logger:trace("Verticalising %s", ref.id)
                Verticaliser.verticaliseNodes(verticalNodes)
            end)
        end
    }
end
event.register("loaded", Verticaliser.startTimer)

--Resets the vertical orientation of a node
---@param node niNode
function Verticaliser.verticaliseNode(node)
    local r = node.worldTransform.rotation:transpose()
    local eulers = r:toEulerXYZ()
    r:fromEulerXYZ(eulers.x, eulers.y, 0.0)
    node.rotation = node.rotation * r
    node:update()
end

---Performs verticalisation on a set of nodes
---@param verticalNodes Verticalise.nodeData[]
function Verticaliser.verticaliseNodes(verticalNodes)
    --verticalise each node that moved
    for _, nodeData in ipairs(verticalNodes) do
        local nodeMoved = true --TODO
        if nodeMoved then
            Verticaliser.verticaliseNode(nodeData.node)
        end
    end
end

function Verticaliser.getVerticalNodes(sceneNode)
    ---@type Verticalise.nodeData[]
    local verticalNodes = {}
    for child in table.traverse{ sceneNode } do
        if Verticaliser.VERTICAL_NODE_NAMES[child.name] then
            table.insert(verticalNodes, {
                node = child,
                position = child.worldTransform.translation:copy()
            })
        end
    end
    if #verticalNodes == 0 then
        return nil
    end
    return verticalNodes
end

--[[
    Searches sceneNode for vertical nodes and
    registers a function that periodically checks if the node has moved,
    and if so, resets its vertical orientation
]]
---@param reference tes3reference
function Verticaliser.registerReferenceForVerticalisation(reference)
    local sceneNode = reference.sceneNode
    if sceneNode == nil then
        logger:error("Tried to verticalise ref %s before sceneNode was available", reference.id)
        return
    end
    local verticalNodes = Verticaliser.getVerticalNodes(sceneNode)
    --Exit if no vertical nodes found
    if not verticalNodes then return end
    logger:debug("Found %s vertical nodes for ref %s", #verticalNodes, reference.id)
    Verticaliser.referenceManager.references[reference] = verticalNodes
    Verticaliser.verticaliseNodes(verticalNodes)
end

return Verticaliser