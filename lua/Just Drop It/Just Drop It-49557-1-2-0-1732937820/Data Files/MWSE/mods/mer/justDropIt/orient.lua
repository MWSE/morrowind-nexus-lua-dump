local this = {}
local config = require("mer.justDropIt.config")
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
    return height > depth or height > width
end

local function getMaxSteepness(ref)
    local objType = ref.baseObject.objectType
    if objType == tes3.objectType.npc or objType == tes3.objectType.creature then return 60 end

    local registeredItem = config.registeredItems[ref.baseObject.id:lower()]
    if registeredItem and registeredItem.maxSteepness then
        return registeredItem.maxSteepness
    else
        return isTall(ref)
            and config.mcmConfig.maxSteepnessTall
            or config.mcmConfig.maxSteepnessFlat
    end
end

local function doOrient(result)
    local isStatic = result.reference and result.reference.object.objectType == tes3.objectType.static
    return not (isStatic and config.mcmConfig.noOrientNonStatic)
end

local function isBlacklisted(ref)
    if ref.object.sourceMod then
        return config.mcmConfig.blacklist[ref.object.sourceMod:lower()]
    end
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

function this.resetXYOrientation(ref)
    ref.orientation = { 0, 0, ref.orientation.z}
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
    local offset = e.offset or 0 --ref.object.boundingBox.max.z-ref.object.boundingBox.min.z
    if not ref then
        return
    end
    local ignoreList = getIngoreList(ref)
    table.insert(ignoreList, ref)
    local result = tes3.rayTest {
        position = {ref.position.x, ref.position.y, ref.position.z + offset},
        direction = {0, 0, -1},
        ignore = ignoreList,
        returnNormal = true,
        useBackTriangles = false,
        root = e.terrainOnly and tes3.game.worldLandscapeRoot or nil
    }

    if not result then --look up instead
        result = tes3.rayTest {
            position = {ref.position.x, ref.position.y, ref.position.z + offset},
            direction = {0, 0, 1},
            ignore = ignoreList,
            returnNormal = true,
            useBackTriangles = true,
            root = e.terrainOnly and tes3.game.worldLandscapeRoot or nil
        }
    end
    return result
end

function this.orientRefToGround(params)
    local ref = params.ref
    if isBlacklisted(ref) and not params.ignoreBlackList then
        return
    end

    local result = this.getGroundBelowRef({ref = ref, offset = params.offset})
    if result then
        this.positionRef(ref, result)
        if doOrient(result) then
            this.orientRef(ref, result)
        end
    end
end

function this.getCloseEnough(e)
    local maxDistanceHorizontal = e.distHorizontal or math.huge
    local maxDistanceVertical = e.distVertical or math.huge
    local pos1 = tes3vector3.new(e.ref1.position.x, e.ref1.position.y, 0)
    local pos2 = tes3vector3.new(e.ref2.position.x, e.ref2.position.y, 0)
    local distHorizontal = pos1:distance(pos2)
    local distVertical = math.abs(e.ref1.position.z - e.ref2.position.z)
    return  distHorizontal < maxDistanceHorizontal
        and distVertical < maxDistanceVertical
end


return this
