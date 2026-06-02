local util = require("openmw.util")

local patterns = {}

patterns.DEFAULT_SPREAD_PRESET = 2
patterns.DEFAULT_BURST_PARAM_COUNT = 5

local SPREAD_PRESET_SIDE_ANGLE_DEGREES = {
    [1] = 10,
    [2] = 15,
    [3] = 22,
    [4] = 30,
}

local function vectorComponents(vector)
    local ok, x, y, z = pcall(function()
        return vector.x, vector.y, vector.z
    end)
    if not ok or type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
        return nil, nil, nil
    end
    return x, y, z
end

local function vectorLength(vector)
    local ok, length = pcall(function()
        return vector:length()
    end)
    if ok then
        return tonumber(length)
    end
    return nil
end

local function normalizeVector(vector)
    if vector == nil then
        return nil, "direction is missing"
    end
    local ok, normalized, length = pcall(function()
        return vector:normalize()
    end)
    if not ok or normalized == nil then
        return nil, "direction is not a vector"
    end
    length = tonumber(length) or vectorLength(vector)
    if length == nil or length <= 0.0001 then
        return nil, "direction has zero length"
    end
    return normalized, nil
end

function patterns.vectorKey(vector)
    local x, y, z = vectorComponents(vector)
    if x == nil then
        return nil
    end
    return string.format("%.5f,%.5f,%.5f", x, y, z)
end

function patterns.spreadSideAngleDegrees(params)
    local preset = tonumber(params and params.preset) or patterns.DEFAULT_SPREAD_PRESET
    local angle = SPREAD_PRESET_SIDE_ANGLE_DEGREES[preset]
    if angle == nil then
        preset = patterns.DEFAULT_SPREAD_PRESET
        angle = SPREAD_PRESET_SIDE_ANGLE_DEGREES[preset]
    end
    return angle, preset
end

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

function patterns.burstRingAngleDegrees(params)
    local param_count = tonumber(params and params.count) or patterns.DEFAULT_BURST_PARAM_COUNT
    param_count = clamp(param_count, 2, 16)
    -- Burst.count is a required opcode parameter, but Multicast owns emission count.
    -- In this dev-only pass it acts as a bounded pattern-intensity hint.
    return clamp(10 + param_count, 12, 20), param_count
end

local function normalizedOffset(index, count)
    if count <= 1 then
        return 0
    end

    if count % 2 == 1 then
        if index == 1 then
            return 0
        end
        local max_pair = (count - 1) / 2
        local pair = math.ceil((index - 1) / 2)
        local sign = (index % 2 == 0) and -1 or 1
        return sign * (pair / max_pair)
    end

    local max_pair = (count / 2) - 0.5
    local pair = math.ceil(index / 2)
    local sign = (index % 2 == 1) and -1 or 1
    return sign * ((pair - 0.5) / max_pair)
end

local function rotateYaw(vector, radians)
    local x, y, z = vectorComponents(vector)
    if x == nil then
        return nil, "direction components unavailable"
    end
    local cos_a = math.cos(radians)
    local sin_a = math.sin(radians)
    return util.vector3(
        (x * cos_a) - (y * sin_a),
        (x * sin_a) + (y * cos_a),
        z
    ), nil
end

local function applyVerticalOffset(vector, radians)
    local x, y, z = vectorComponents(vector)
    if x == nil then
        return nil, "direction components unavailable"
    end
    -- TODO(2.2c): replace this world-Z approximation with camera-basis burst math.
    return util.vector3(x, y, z + math.sin(radians)), nil
end

function patterns.computeSpreadDirections(base_direction, count, params)
    local emission_count = tonumber(count) or 0
    if emission_count < 1 then
        return { ok = false, error = "Spread direction count must be >= 1" }
    end

    local normalized, normalize_err = normalizeVector(base_direction)
    if not normalized then
        return { ok = false, error = normalize_err }
    end

    local side_angle_degrees, preset = patterns.spreadSideAngleDegrees(params)
    local directions = {}
    local direction_keys = {}
    local angle_offsets_degrees = {}
    local side_angle_radians = math.rad(side_angle_degrees)

    for index = 1, emission_count do
        local offset = normalizedOffset(index, emission_count)
        local angle_degrees = side_angle_degrees * offset
        local rotated, rotate_err = rotateYaw(normalized, side_angle_radians * offset)
        if not rotated then
            return { ok = false, error = rotate_err }
        end
        local direction, direction_err = normalizeVector(rotated)
        if not direction then
            return { ok = false, error = direction_err }
        end
        local key = patterns.vectorKey(direction)
        if key == nil then
            return { ok = false, error = "direction components unavailable" }
        end
        directions[index] = direction
        direction_keys[index] = key
        angle_offsets_degrees[index] = angle_degrees
    end

    return {
        ok = true,
        preset = preset,
        side_angle_degrees = side_angle_degrees,
        directions = directions,
        direction_keys = direction_keys,
        angle_offsets_degrees = angle_offsets_degrees,
        rotation_axis = "world_up_yaw",
    }
end

function patterns.computeBurstDirections(base_direction, count, params)
    local emission_count = tonumber(count) or 0
    if emission_count < 1 then
        return { ok = false, error = "Burst direction count must be >= 1" }
    end

    local normalized, normalize_err = normalizeVector(base_direction)
    if not normalized then
        return { ok = false, error = normalize_err }
    end

    local ring_angle_degrees, param_count = patterns.burstRingAngleDegrees(params)
    local ring_angle_radians = math.rad(ring_angle_degrees)
    local ring_count = emission_count - 1
    local directions = {}
    local direction_keys = {}
    local yaw_offsets_degrees = {}
    local pitch_offsets_degrees = {}

    for index = 1, emission_count do
        local yaw_degrees = 0
        local pitch_degrees = 0
        if index > 1 and ring_count > 0 then
            local phase = ((index - 2) / ring_count) * math.pi * 2
            yaw_degrees = ring_angle_degrees * math.cos(phase)
            pitch_degrees = ring_angle_degrees * math.sin(phase)
        end

        local yawed, yaw_err = rotateYaw(normalized, math.rad(yaw_degrees))
        if not yawed then
            return { ok = false, error = yaw_err }
        end
        local pitched, pitch_err = applyVerticalOffset(yawed, math.rad(pitch_degrees))
        if not pitched then
            return { ok = false, error = pitch_err }
        end
        local direction, direction_err = normalizeVector(pitched)
        if not direction then
            return { ok = false, error = direction_err }
        end
        local key = patterns.vectorKey(direction)
        if key == nil then
            return { ok = false, error = "direction components unavailable" }
        end

        directions[index] = direction
        direction_keys[index] = key
        yaw_offsets_degrees[index] = yaw_degrees
        pitch_offsets_degrees[index] = pitch_degrees
    end

    return {
        ok = true,
        burst_param_count = param_count,
        ring_angle_degrees = ring_angle_degrees,
        directions = directions,
        direction_keys = direction_keys,
        yaw_offsets_degrees = yaw_offsets_degrees,
        pitch_offsets_degrees = pitch_offsets_degrees,
        distribution = "world_up_yaw_vertical_ring",
    }
end

return patterns
