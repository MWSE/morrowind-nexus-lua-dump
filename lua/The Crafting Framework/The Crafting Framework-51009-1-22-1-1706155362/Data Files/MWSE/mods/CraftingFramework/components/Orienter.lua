local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("Orienter")

local this = {}
local ID33 = tes3matrix33.new(1, 0, 0, 0, 1, 0, 0, 0, 1)
function this.rotationDifference(vec1, vec2)
    vec1 = vec1:normalized()
    vec2 = vec2:normalized()

    local axis = vec1:cross(vec2)
    local norm = axis:length()
    if norm < 1e-5 then
        return ID33:toEulerXYZ()
    end

    local angle = math.asin(norm)
    if vec1:dot(vec2) < 0 then
        angle = math.pi - angle
    end

    axis:normalize()

    local m = ID33:copy()
    m:toRotation(-angle, axis.x, axis.y, axis.z)
    return m:toEulerXYZ()
end

local function getIngoreList(ref)
    local function doIgnoreMesh(meshRef)
        return meshRef.baseObject.objectType == tes3.objectType.npc or
            meshRef.baseObject.objectType == tes3.objectType.creature
    end
    local ignoreList = {}
    table.insert(ignoreList, tes3.player)
    for thisRef in ref.cell:iterateReferences() do
        if doIgnoreMesh(thisRef) then
            table.insert(ignoreList, thisRef)
        end
    end
    return ignoreList
end

local function isTall(ref)
    local bb = ref.object.boundingBox
    local width = bb.max.x - bb.min.x
    local depth = bb.max.y - bb.min.y
    local height = bb.max.z - bb.min.z
    return (height > depth) or (height > width)
end

local function getMaxSteepness(ref)
    if ref.data and ref.data.positionerMaxSteepness then
        return ref.data.positionerMaxSteepness
    end
    local objType = ref.baseObject.objectType
    if objType == tes3.objectType.npc or objType == tes3.objectType.creature then return 60 end
    if objType == tes3.objectType.light then return 0 end
    if isTall(ref) then return 5 end
    return 50
end

function this.positionRef(ref, rayResult)
    if not rayResult then
        --This only happens when the ref is
        --beyond the edge of the active cells
        return false
    end
    local bb = ref.object.boundingBox
    local newZ = rayResult.intersection.z - (bb.min.z * ref.scale)
    ref.position = {ref.position.x, ref.position.y, newZ}
end

function this.orientRef(ref, rayResult)
    local UP = tes3vector3.new(0, 0, 1)
    local maxSteepness = math.rad(getMaxSteepness(ref))
    local newOrientation = this.rotationDifference(UP, rayResult.normal)
    newOrientation.x = math.clamp(newOrientation.x, (0 - maxSteepness), maxSteepness)
    newOrientation.y = math.clamp(newOrientation.y, (0 - maxSteepness), maxSteepness)
    newOrientation.z = ref.orientation.z

    ref.orientation = newOrientation
end

function this.getGroundBelowRef(e)
    local ref = e.ref
    local offset = (ref.object.boundingBox.max.z) * ref.scale
    if not ref then
        return
    end

    local ignoreList = getIngoreList(ref)
    table.insert(ignoreList, ref)

    local startPos = {ref.position.x, ref.position.y, ref.position.z + offset}

    local result = tes3.rayTest {
        position = startPos,
        direction = {0, 0, -1},
        ignore = ignoreList,
        returnNormal = true,
        useBackTriangles = false,
        root = e.terrainOnly and tes3.game.worldLandscapeRoot or nil,
        accurateSkinned = true,
    }
    if not result then --look up instead
        result = tes3.rayTest {
            position = startPos,
            direction = {0, 0, 1},
            ignore = ignoreList,
            returnNormal = true,
            useBackTriangles = true,
            root = e.terrainOnly and tes3.game.worldLandscapeRoot or nil,
            accurateSkinned = true,
        }
        if not result then
            return
        end
    end
    return result
end

---@class Orienter.orientRefToGround.params
---@field ref tes3reference
---@field maxVerticalDistance number?

---@param params Orienter.orientRefToGround.params
function this.orientRefToGround(params)
    local ref = params.ref
    local result = this.getGroundBelowRef{
        ref = ref,
    }

    if result then
        local tooFar = false
        if params.maxVerticalDistance then
            tooFar = math.abs(result.intersection.z - ref.position.z) > params.maxVerticalDistance
        end
        if not tooFar then
            logger:trace("Orienting %s to ground", ref.id)
            this.positionRef(ref, result)
            this.orientRef(ref, result)
            return true
        else
            logger:trace("Ref %s is too far from the ground", ref.id)
            return false
        end
    end
    return false
end

return this
