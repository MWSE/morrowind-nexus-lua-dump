local common = require("mer.fishing.common")
local logger = common.createLogger("Bait")
local config = require("mer.fishing.config")
local BaitType = require("mer.fishing.Bait.BaitType")

--[[
    The object representing a configred lure or bait item.
]]
---@class Fishing.Bait.config
---@field id string The id of the item that represents this bait
---@field type Fishing.Bait.type
---@field uses? number How many times this bait can be used before it is destroyed. If not set, bait is infinite and can be recovered after attaching
---@field floatMesh string path to the mesh override for the floater. If not set, the default float will be used.

---@class Fishing.Bait : Fishing.Bait.config
local Bait = {
    ---@type table<string, Fishing.Bait>
    registeredBait = {}
}

---@param itemId string The id of the bait item
---@return Fishing.Bait|nil
function Bait.get(itemId)
    return Bait.registeredBait[itemId:lower()]
end

--[[
    Check if the item is cooked
]]
---@param data table? The itemData.data table of a reference or inventory item
---@return boolean
function Bait.isCooked(data)
    local cookedAmount = data
        and data.cookedAmount
        or 0
    if cookedAmount > 0 then
        return true
    end
    return false
end

--Register a new Bait item
---@param o Fishing.Bait.config
function Bait.register(o)
    Bait.registeredBait[o.id:lower()] = Bait:new(o)
end

function Bait:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Bait:getInstance(uses)
    local o = self:new()
    o.uses = uses
    return o
end

function Bait:getType()
    return BaitType.get(self.type)
end

function Bait:getTypeName()
    return self:getType().name
end

function Bait:getName()
    local obj = tes3.getObject(self.id)
    return obj.name or "[unknown]"
end

function Bait:reusable()
    return self.uses == nil
end

function Bait:getFloaterMesh()
    local mesh = self.floatMesh
    if not mesh then
        local obj = tes3.getObject("mer_lure_01")
        mesh = obj.mesh
    end
    return tes3.loadMesh(mesh):clone() --[[@as niNode]]
end

---@param animRef tes3reference
function Bait:attachToAnim(animRef)
    if not animRef then
        logger:error("No animRef provided")
        return
    end
    if not animRef.sceneNode then
        logger:error("No sceneNode on animRef")
        return
    end
    local attachNode = animRef.sceneNode:getObjectByName("AttachAnimLure") --[[@as niNode]]
    if not attachNode then
        logger:error("No attach node on animRef")
        return
    end
    local baitMesh = self:getFloaterMesh()
    attachNode:attachChild(baitMesh)
    attachNode:update()
    attachNode:updateProperties()
    attachNode:updateEffects()
    logger:debug("Attached %s to %s", self:getName(), animRef.object.name)
end

return Bait