local log = require("JosephMcKean.MistyStep.log")
local config = require("JosephMcKean.MistyStep.config")

local blink = {}

local UNITS_PER_FOOT = 22.1
local MAX_BLINK_DISTANCE = 60 * UNITS_PER_FOOT

---@class getBlinkRayResult
---@field position tes3vector3
---@field direction tes3vector3

--- Gets the origin and direction for the misty step blink based on the caster's facing and a configurable mode (camera vs facing).
--- @param caster tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer The caster of the spell.
--- @return getBlinkRayResult The origin and direction for the blink ray.
function blink.getBlinkRay(caster)
    if config.targetMode == "camera" and caster == tes3.mobilePlayer then
        local pos = tes3.getPlayerEyePosition()
        local dir = tes3.getPlayerEyeVector()
        return {position = pos, direction = dir}
    end

    local facing = caster.facing
    local pos = caster.position +
                    tes3vector3.new(0, 0, (caster.height or 0) * 0.93)
    local dir = tes3vector3.new(math.sin(facing), math.cos(facing), 0)
    return {position = pos, direction = dir}
end

--- Find a safe landing position given a caster reference and a blink ray (position+direction).
--- @param casterRef tes3reference The reference of the caster
--- @param ray getBlinkRayResult The origin and direction for the blink ray
--- @return tes3vector3|nil
function blink.findLandingPosition(casterRef, ray)
    if not casterRef then return nil end
    local caster = casterRef.mobile
    if not caster then return nil end

    local blinkHit = tes3.rayTest({
        position = ray.position,
        direction = ray.direction,
        ignore = {casterRef},
        maxDistance = MAX_BLINK_DISTANCE
    })

    local blinkDistance = blinkHit and
                              math.max(0, blinkHit.distance - UNITS_PER_FOOT * 2) or
                              MAX_BLINK_DISTANCE
    log:debug("blink.findLandingPosition: initial distance=%.3f (%.3f ft)",
              blinkDistance, blinkDistance / UNITS_PER_FOOT)

    local downOffset = tes3vector3.new(0, 0, UNITS_PER_FOOT)
    local maxAttempts = 5
    local attempts = 0

    while attempts < maxAttempts and blinkDistance > 0 do
        attempts = attempts + 1
        local candidatePosition = ray.position + ray.direction * blinkDistance
        log:debug(
            "blink.findLandingPosition: attempt %d candidate=%s distance=%.3f",
            attempts, candidatePosition, blinkDistance)
        -- debug.mark(candidatePosition, niColor.new(0, 1, 0)) -- Mark candidate position in green

        local floorHit = tes3.rayTest({
            position = candidatePosition + downOffset,
            direction = tes3vector3.new(0, 0, -1),
            maxDistance = (caster.height or 0) * 2
        })

        if floorHit then
            candidatePosition.z = floorHit.intersection.z
            log:debug(
                "blink.findLandingPosition: floorHit on attempt %d -> z=%.3f",
                attempts, candidatePosition.z)
            -- debug.mark(candidatePosition, niColor.new(0, 0, 1)) -- Mark floor hit position in blue
            return candidatePosition
        end

        blinkDistance = blinkDistance - UNITS_PER_FOOT * 2
    end

    log:debug(
        "blink.findLandingPosition: no valid landing found after %d attempts",
        attempts)
    return nil
end

--- Perform teleport for a reference to a given position. Returns true on success.
--- @param casterRef tes3reference The reference of the caster
--- @param position tes3vector3 The target position for the teleport
--- @return boolean
function blink.performTeleport(casterRef, position)
    if not casterRef or not position then return false end
    local teleportParams = {
        reference = casterRef,
        position = position,
        orientation = casterRef.orientation,
        suppressFader = true,
        teleportCompanions = false
    }
    local caster = casterRef.mobile
    if caster and caster.cell and caster.cell.isInterior then
        teleportParams.cell = caster.cell
        teleportParams.forceCellChange = true
    end
    local execuated = tes3.positionCell(teleportParams)
    if execuated then
        log:debug("blink.performTeleport: teleport successful to %s", position)
    else
        log:error("blink.performTeleport: teleport failed for unknown reason")
    end
    return execuated
end

return blink
