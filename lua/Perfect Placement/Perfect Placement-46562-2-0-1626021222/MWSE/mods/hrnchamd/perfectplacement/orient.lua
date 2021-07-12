--[[
    Ground orientation functions

    Source: Just Drop It by Merlord
    Used with permission.
]]--

local this = {}

-- Different steepness limits than Just Drop It.
-- The limit should still demonstrate the need to change to vertical mode.
local maxSteepnessFlat = 65
local maxSteepnessTall = 5

function this.rotationDifference(vec1, vec2)
    vec1 = vec1:normalized()
    vec2 = vec2:normalized()

    local axis = vec1:cross(vec2)
    local norm = axis:length()
    if norm < 1e-5 then
        return tes3vector3.new(0, 0, 0)
    end

    local angle = math.asin(norm)
    if vec1:dot(vec2) < 0 then
        angle = math.pi - angle
    end

    axis:normalize()

    local m = tes3matrix33.new()
    m:toRotation(-angle, axis.x, axis.y, axis.z)
    return m:toEulerXYZ()
end

local function isTall(ref)
    local bb = ref.object.boundingBox
    local width = bb.max.x - bb.min.x
    local depth = bb.max.y - bb.min.y
    local height = bb.max.z - bb.min.z
    return height > depth or height > width
end

local function getMaxSteepness(ref)
    return math.rad(isTall(ref) and maxSteepnessTall or maxSteepnessFlat)
end

function this.positionRef(ref, rayResult)
    if not rayResult then
        --This only happens when the ref is
        --beyond the edge of the active cells
        return false
    end
    local bb = ref.object.boundingBox
    local newZ = rayResult.intersection.z - bb.min.z
    ref.position = {ref.position.x, ref.position.y, newZ}
end

function this.orientRef(ref, rayResult)
    local UP = tes3vector3.new(0, 0, 1)
    local maxSteepness = getMaxSteepness(ref)
    local newOrientation = this.rotationDifference(UP, rayResult.normal)

    newOrientation.x = math.clamp(newOrientation.x, -maxSteepness, maxSteepness)
    newOrientation.y = math.clamp(newOrientation.y, -maxSteepness, maxSteepness)
    newOrientation.z = ref.orientation.z

    ref.orientation = newOrientation
    return newOrientation
end

function this.getGroundBelowRef(ref)
    local offset = -ref.object.boundingBox.min.z + 5
    local rayOri = tes3vector3.new(ref.position.x, ref.position.y, ref.position.z + offset)

    local result = tes3.rayTest{
        position = rayOri,
        direction = {0, 0, -1},
        maxDistance = 800,
        ignore = {ref},
        returnNormal = true,
        useBackTriangles = false,
    }

    if not result then --look up instead
        result = tes3.rayTest{
            position = rayOri,
            direction = {0, 0, 1},
            maxDistance = 800,
            ignore = {ref},
            returnNormal = true,
            useBackTriangles = true,
        }
    end

    return result
end

function this.orientRefToGround(ref)
    local result = this.getGroundBelowRef(ref)
    if result then
        this.positionRef(ref, result)
        this.orientRef(ref, result)
    end
end

return this
