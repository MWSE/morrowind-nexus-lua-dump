local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("NodeManager")
local ReferenceManager = require("mer.joyOfPainting.services.ReferenceManager")
--[[
    Enums for node names
]]
local NodeManager = {}

NodeManager.nodes = {
    --Canvas nodes
    PAINT_SWITCH = "SWITCH_PAINT",
        PAINT_SWITCH_OFF = "OFF",
        PAINT_SWITCH_ANIMATING = "ANIMATING",
        PAINT_SWITCH_PAINTED = "PAINTED",

    PAINT_ANIM_TEX_NODE = "CANVAS_PAINT_ANIM",
    PAINT_ANIM_UNDER = "CANVAS_PAINT_ANIM_UNDER",
    PAINT_TEX_NODE = "CANVAS_PAINT",
    --Easel nodes
    ATTACH_CANVAS = "ATTACH_CANVAS",
    EASEL_CLAMP = "EASEL_CLAMP",

    --Frame
    ATTACH_FRAME = "ATTACH_FRAME",


}

---@param node niNode
---@param name string
---@return integer?
function NodeManager.getIndex(node, name)
	for i, child in ipairs(node.children) do
        local isMatch = name and child and child.name
            and child.name:lower() == name:lower()
		if isMatch then
			return i - 1
		end
	end
end

---@param node niNode
function NodeManager.cloneTextureProperty(node)
    ---@diagnostic disable-next-line
    local prop = node:detachProperty(ni.propertyType.texturing)
    assert(prop ~= nil, "No material property found on node")
    local clonedProp = prop:clone() --[[@as any]]
    node:attachProperty(clonedProp)
    return clonedProp
end

---@param sceneNode niNode
function NodeManager.getCanvasAttachNode(sceneNode)
    return sceneNode:getObjectByName(NodeManager.nodes.ATTACH_CANVAS)
end

---@param node niNode
function NodeManager.moveOriginToAttachPoint(node)
    local attachPoint = node:getObjectByName("ATTACH_POINT")
    if attachPoint then
        node.rotation = attachPoint.rotation:copy()
        node.translation.x = node.translation.x - attachPoint.translation.x
        node.translation.y = node.translation.y - attachPoint.translation.y
        node.translation.z = node.translation.z - attachPoint.translation.z
        node.scale = node.scale * attachPoint.scale
    end
end

---@class JOP.Switch
---@field id string The id of the switch
---@field switchName string The name of the switch node
---@field additionalReqs? function The condition to check if the switch should be active
---@field requirements? function The full requirements check including whether the switch node exists
---@field getActiveNode function The function to determine which node should be active

---@type table<string, JOP.Switch>
NodeManager.switches = {}


---@param e JOP.Switch
function NodeManager.registerSwitch(e)
    logger:assert(type(e.switchName) == "string", "switchName must be a string")
    logger:assert(type(e.getActiveNode) == "function", "getActiveNode must be a function")
    e.requirements = function(_, reference)
        local hasSceneNode = reference and reference.sceneNode
        local hasSwitch = hasSceneNode and reference.sceneNode:getObjectByName(e.switchName) ~= nil
        local meetsRequirements = e.additionalReqs == nil or e.additionalReqs(reference)
        return hasSwitch and meetsRequirements
    end

    ReferenceManager.registerReferenceController{
        id = e.id,
        requirements = e.requirements,
        onActive = function(_, reference)
            logger:debug("Updating switches for %s", reference.id)
            NodeManager.processSwitch(e, reference)
        end
    }

    logger:debug("Registering switch %s", e.switchName)
    NodeManager.switches[e.id] = e
end

---@param switch JOP.Switch
function NodeManager.processSwitch(switch, reference)

    logger:debug("Processing switch %s", switch.switchName)
    local sceneNode = reference.sceneNode
    local switchNode = sceneNode:getObjectByName(switch.switchName)
    if not switchNode then return end
    local activeNode = switchNode:getObjectByName(switch.getActiveNode{
        reference = reference,
        switchNode = switchNode
    })
    if not activeNode then return end
    local activeIndex = NodeManager.getIndex(switchNode, activeNode.name)
    switchNode.switchIndex = activeIndex
end

function NodeManager.updateSwitches()
    for _, switch in pairs(NodeManager.switches) do
        ReferenceManager.iterateReferences(switch.id, function(reference)
            NodeManager.processSwitch(switch, reference)
        end)
    end
end

function NodeManager.updateSwitch(id)
    logger:debug("Updating switch %s", id)
    local switch = NodeManager.switches[id]
    if not switch then
        logger:warn("Switch %s not found", id)
        return
    end
    ReferenceManager.iterateReferences(switch.id, function(reference)
        NodeManager.processSwitch(switch, reference)
    end)
end


return NodeManager