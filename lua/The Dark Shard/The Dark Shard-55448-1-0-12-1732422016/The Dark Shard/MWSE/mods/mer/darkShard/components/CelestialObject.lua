local common = require("mer.darkShard.common")
local logger = common.createLogger("celestialObject")

---@class DarkShard.CelestialObject.params
---@field id string The id of the object, used as the name of the node
---@field meshPath string The path to the mesh, relative to /Data Files/Meshes/
---@field position? tes3vector3
---@field rotation? tes3vector3
---@field scale number

---@class DarkShard.CelestialObject : DarkShard.CelestialObject.params
local CelestialObject = {}

local skyRoot = tes3.worldController.weatherController.sceneSkyRoot

---@param e DarkShard.CelestialObject.params
---@return DarkShard.CelestialObject
function CelestialObject:new(e)
    local self = table.copy(e)
    return setmetatable(self, { __index = CelestialObject })
end

function CelestialObject:getNode()
    return skyRoot:getObjectByName(self.id)
end

function CelestialObject:isEnabled()
    return self:getNode() ~= nil
end

function CelestialObject.getParent()
    return skyRoot.children[6]
end

function CelestialObject.attachToStart(parent, node)
    local children = {}
    for _, child in ipairs(parent.children) do
        table.insert(children, child)
        parent:detachChild(child)
    end
    parent:attachChild(node, true)
    for _, child in ipairs(children) do
        parent:attachChild(child, true)
    end
end

function CelestialObject:enable()
    local existingNode = self:getNode()
    if existingNode then
        logger:trace("%s already enabled", self.id)
        existingNode.scale = self.scale
        return false
    end

    local mesh = skyRoot:getObjectByName(self.id)

    --mesh = tes3.loadMesh("o\\contain_crate_01.nif"):clone()
    mesh = tes3.loadMesh(self.meshPath):clone()
    mesh.name = self.id
    if self.position then
        mesh.translation = self.position:copy()
    end
    if self.rotation then
        local m = tes3matrix33.new()
        m:fromEulerXYZ(self.rotation.x, self.rotation.y, self.rotation.z)
        mesh.rotation = m
    end
    mesh.scale = self.scale

    -- insert the mesh in the scene graph immediately before the clouds
    local parent = self.getParent()
    self.attachToStart(parent, mesh)

    skyRoot:update()
    skyRoot:updateProperties()
    skyRoot:updateEffects()
    logger:debug("Enabled %s", self.id)
end

function CelestialObject:disable()
    local node = self:getNode()
    if not node then
        logger:trace("%s already disabled", self.id)
        return false
    end
    node.parent:detachChild(node)
    --Reorder to remove gap
    local children = {}
    for _, child in ipairs(node.children) do
        if child then
            table.insert(children, child)
            node:detachChild(child)
        end
    end
    for _, child in ipairs(children) do
        node:attachChild(child, true)
    end
    logger:debug("Disabled %s", self.id)
    return true
end

return CelestialObject