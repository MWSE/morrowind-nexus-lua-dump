local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("backpackService")

---@class JOP.BackPack.Config.offset
---@field translation table
---@field rotation table
---@field scale number

---@class JOP.BackPack.Config
---@field id string id of the backpack object
---@field filename string path to the nif to attach
---@field offset? JOP.BackPack.Config.offset table of transation, rotation and scale to apply

---@class JOP.BackpackService
local BackpackService = {
    BACKPACK_SLOT = 11
}

function BackpackService.registerBackpack(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:debug("registering backpack %s", e.id)
    local obj = tes3.getObject(e.id)
    if not obj then
        logger:warn("backpack %s not found", e.id)
        return
    end
    local id = e.id:lower()
    local obj = tes3.getObject(id)
    -- remap slot to custom backpackSlot
    obj.slot = BackpackService.BACKPACK_SLOT
    -- store the bodypart mesh for later

    config.backpacks[id] = {
        id = id,
        filename = obj.mesh,
    }

    if e.offset then
        local translation
        local rotation
        if e.offset.translation then
            translation = tes3vector3.new(
                e.offset.translation.x,
                e.offset.translation.y,
                e.offset.translation.z
            )
        end
        if e.offset.rotation then
            local m = tes3matrix33.new()
            m:fromEulerXYZ(
                math.rad(e.offset.rotation.x),
                math.rad(e.offset.rotation.y),
                math.rad(e.offset.rotation.z)
            )
            rotation = m
        end
        config.backpacks[id].offset = {
            translation = translation,
            rotation = rotation,
            scale = e.offset.scale
        }
    end
    -- clear bodypart so it doesn't overwrite left pauldron
        obj.parts[1].type = 255
        obj.parts[1].male = nil
end

function BackpackService.loadMesh(mesh)
    return tes3.loadMesh(mesh):clone()
end

function BackpackService.adjustBodyWeight(ref, node)
    local weight = ref.object.race.weight.male
    local height = ref.object.race.height.male
    if ref.object.female then
        weight = ref.object.race.weight.female
        height = ref.object.race.height.female
    end

    --scale by weight, but only so much
    local heightScale = math.min(1, height)

    local weightMod = 1 / weight * heightScale
    local heightMod = 1 / height * heightScale

    local r = node.rotation
    local scale = tes3vector3.new(heightMod, weightMod, weightMod)
    node.rotation = tes3matrix33.new(r.x * scale, r.y * scale, r.z * scale)
end

---@param reference tes3reference
---@param packId string
function BackpackService.attachBackpack(reference, packId)
    local backpack = config.backpacks[packId]
    local parent = reference.sceneNode:getObjectByName("Bip01 Spine1")
    local node = BackpackService.loadMesh(backpack.filename)
    if node then
        node = node:clone()
        node:clearTransforms()
        -- rename the root node so we can easily find it for detaching
        node.name = "Bip01 AttachBackpack"
        -- offset the node to emulate vanilla's left pauldron behavior
        node.translation = backpack.offset.translation:copy()
        node.rotation = backpack.offset.rotation:copy()
        node.scale = backpack.offset.scale
        parent:attachChild(node, true)

        BackpackService.adjustBodyWeight(reference, node)
    end
end

function BackpackService.detachBackpack(parent)
    local node = parent:getObjectByName("Bip01 AttachBackpack")
    if node then
        parent:detachChild(node)
    end
end



return BackpackService
