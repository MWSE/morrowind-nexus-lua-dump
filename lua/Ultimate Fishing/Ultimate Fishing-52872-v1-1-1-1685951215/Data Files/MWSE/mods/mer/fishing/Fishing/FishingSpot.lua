--[[
    This class is used to check whether the player is standing in
    a valid spot for fishing, by performing ray tests to check for
    unobstructed water with an appropriate depth.
]]
local common = require("mer.fishing.common")
local logger = common.createLogger("FishingSpot")

---@class Fishing.FishingSpot
local FishingSpot = {}

local DISTANCE_AHEAD = 1000 --How far in front of the player to check
local MAX_DISTANCE_DOWN = 3000 --How far below the player to check
local MINIMUM_DEPTH = 50 --How deep the water must be to be valid

--Make sure the player is above water
local function checkPlayerAboveWater(_)
    local waterLevel = tes3.player.cell.waterLevel
    if not waterLevel then return false end
    if tes3.player.position.z < waterLevel then
        logger:warn("Player is below water")
        return false, "You must be on dry land to fish."
    end
    logger:debug("Player is above water")
    return true
end

local function getOrientation()
    local playerOrientation = tes3.getPlayerEyeVector()
    return tes3vector3.new(
        playerOrientation.x,
        playerOrientation.y,
        0
    )
end

local function getDistanceAhead(castStrength)
    return (DISTANCE_AHEAD * castStrength) + 250
end

local function checkFrontIsClear(castStrength)
    local result = tes3.rayTest{
        position = tes3.getPlayerEyePosition(),
        direction = getOrientation(),
        maxDistance = getDistanceAhead(castStrength),
        ignore = { tes3.player },
    }
    if result then
        logger:warn("Hit %s in front of player at %s", result.reference, result.intersection)
        return false, "You can not fish here."
    end
    logger:debug("Nothing in front of player")
    return true
end

--Check that immediately below the position ahead if player is water
local function checkForWater(castStrength)
    local playerPosition = tes3.getPlayerEyePosition()
    local startPosition = playerPosition + getOrientation() * getDistanceAhead(castStrength)

    logger:debug("Player position = %s", playerPosition)
    logger:debug("Start position = %s", startPosition)

    local result = tes3.rayTest{
        position = startPosition,
        direction = tes3vector3.new(0,0,-1),
        maxDistance = MAX_DISTANCE_DOWN,
        ignore = { tes3.player },
    }
    if not result then
        logger:warn("Hit nothing below")
        return false, "You can not fish here."
    end
    --check that intersection is underwater
    local waterLevel = tes3.player.cell.waterLevel
    if not waterLevel then return false end

    if result.intersection.z > waterLevel then
        logger:warn("Hit %s above water", result.reference)
        return false, "You can not fish here."
    end
    local depth = waterLevel - result.intersection.z
    --check that water is deep enough
    if depth < MINIMUM_DEPTH then
        logger:warn("Water is not deep enough")
        return "The water is not deep enough."
    end
    logger:debug("Water is deep enough")
    return true
end

function FishingSpot.check(castStrength)
    local checks = {
        checkPlayerAboveWater,
        checkFrontIsClear,
        checkForWater,
    }
    for _, check in ipairs(checks) do
        local isValid, invalidMessage = check(castStrength)
        if not isValid then
            return isValid, invalidMessage
        end
    end
    return true, nil
end

function FishingSpot.getDepth(position, ignoreList)
    logger:debug("Getting depth at %s", position)
    local INT_MAX = 0x7FFFFFFF
    local result = tes3.rayTest{
        position = position,
        direction = tes3vector3.new(0,0,-1),
        ignore = ignoreList,
        maxDistance = 5000,
    }
    if not result then
        logger:warn("Hit nothing below")
        return INT_MAX
    end
    local waterLevel = tes3.player.cell.waterLevel
    if not waterLevel then
        logger:warn("No water level")
        return INT_MAX
    end
    local depth = waterLevel - result.intersection.z
    logger:debug("Depth = %s", depth)
    return depth
end

function FishingSpot.getLurePosition(castStrength)
    local playerPosition = tes3.getPlayerEyePosition()
    local startPosition = playerPosition + getOrientation() * getDistanceAhead(castStrength)
    local result = tes3.rayTest{
        position = startPosition,
        direction = tes3vector3.new(0,0,-1),
        maxDistance = MAX_DISTANCE_DOWN,
        ignore = { tes3.player },
    }
    if (not result) or (not result.intersection) then
        logger:warn("Hit nothing below")
        return nil
    end

    local waterLevel = tes3.player.cell.waterLevel
    if not waterLevel then return nil end
    if result.intersection.z > waterLevel then
        logger:warn("Hit %s above water", result.reference)
        return nil
    end
    --Return position at water level
    return tes3vector3.new(
        result.intersection.x,
        result.intersection.y,
        waterLevel
    )
end

return FishingSpot