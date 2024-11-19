--[[
    Ground orientation functions, OpenMW port

    Source: Just Drop It by Merlord
    Used with permission.
]]--

local util = require('openmw.util')
local ui = require('openmw.ui')

local this = {}

-- Different steepness limits than Just Drop It.
-- The limit should still demonstrate the need to change to vertical mode.
local maxSteepnessFlat = 65
local maxSteepnessTall = 5

local function mutableVec3(v)
	return { x = v.x, y = v.y, z = v.z }
end

local function transformToAngles(t)
	local x, y, z
	local forward = t * util.vector3(0, 1, 0)
	local up = t * util.vector3(0, 0, 1)
	forward = forward:normalize()
	up = up:normalize()
	y = -math.asin(up.x)
	x = math.atan2(up.y, up.z)
	local fz = (util.transform.rotateY(-y) * util.transform.rotateX(-x)) * forward
	z = math.atan2(fz.x, fz.y)

	--z, y, x = t:getAnglesZYX() -- broken in 0.49 dev
	return { x = x, y = y, z = z }
end

function this.rotationDifference(vec1, vec2)
    vec1 = vec1:normalize()
    vec2 = vec2:normalize()

    local axis = vec1:cross(vec2)
    local norm = axis:length()
    if norm < 1e-5 then
        return util.vector3(0, 0, 0)
    end

    local angle = math.asin(norm)
    if vec1:dot(vec2) < 0 then
        angle = math.pi - angle
    end

    axis = axis:normalize()

    local m = util.transform.rotate(angle, axis) -- OpenMW edit
	return transformToAngles(m)
end

local function isTall(ref)
    local bb = ref:getBoundingBox() -- OpenMW edit
    local width = bb.halfSize.x * 2
    local depth = bb.halfSize.y * 2
    local height = bb.halfSize.z * 2
    return height > depth or height > width
end

local function getMaxSteepness(ref)
    return math.rad(isTall(ref) and maxSteepnessTall or maxSteepnessFlat)
end

function this.orientRef(ref, orientation, tall, hitNormal)
    local UP = util.vector3(0, 0, 1)
    --local maxSteepness = getMaxSteepness(ref)
    local maxSteepness = math.rad(tall and maxSteepnessTall or maxSteepnessFlat)
    local newOrientation = mutableVec3(this.rotationDifference(UP, hitNormal))

    newOrientation.x = util.clamp(newOrientation.x, -maxSteepness, maxSteepness)
    newOrientation.y = util.clamp(newOrientation.y, -maxSteepness, maxSteepness)
    newOrientation.z = orientation.z
    return newOrientation
end

return this
