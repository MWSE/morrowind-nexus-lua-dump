local utils = require("firemoth.utils")
local quest = require("firemoth.quests.lib")
local lightning = require("firemoth.weather.lightning")

local MAX_DISTANCE = 8192 * 3
local STRIKE_MAX_RANGE = 8192 * 1.0

local DOWN = tes3vector3.new(0, 0, -1)
local XY = tes3vector3.new(1, 1, 0)

---@type mwseTimer
local STRIKE_TIMER

---@param strikePos tes3vector3
---@return number
local function nearestAntiMarkerDistance(strikePos)
    if not quest.diversionStarted() then
        return math.fhuge
    end

    local closestMarkerDistance = math.huge

    for _, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.static) do
            ---@cast ref tes3reference
            if ref.id == "fm_anti_strike" then
                local dist = utils.math.xyDistance(ref.position, strikePos)
                if dist < closestMarkerDistance then
                    closestMarkerDistance = dist
                end
            end
        end
    end

    return closestMarkerDistance
end

---@return tes3vector3, boolean
local function getStrikePos()
    local x = STRIKE_MAX_RANGE * (math.random() * 2 - 1)
    local y = STRIKE_MAX_RANGE * (math.random() * 2 - 1)

    local offset = tes3vector3.new(x, y, 8192)
    local origin = utils.cells.FIREMOTH_REGION_ORIGIN + offset

    local rayhit = tes3.rayTest({ position = origin, direction = DOWN })
    local position = rayhit and rayhit.intersection:copy() or (origin * XY)

    local waterLevel = tes3.player.cell.waterLevel or 0
    position.z = math.max(position.z, waterLevel)

    return position, (position.z <= waterLevel)
end

---@param target tes3reference
---@param position tes3vector3|nil
local function applyDamage(target, position)
    target.mobile:applyDamage({
        damage = math.max(target.mobile.health.base / 4, 25),
        resistAttribute = tes3.effectAttribute.resistShock,
    })
    tes3.createVisualEffect({
        position = position or target.position,
        object = "VFX_LightningArea",
        lifespan = 1.0,
    })
end

local lastStrikeTime = os.clock()
local function update()
    if tes3.player.cell.isInterior then
        return
    end

    local distance = utils.cells.getFiremothDistance()
    if distance > MAX_DISTANCE then
        return
    end

    --- Ticks 4 times per second.
    --- Forces at least one strike per 4.35 seconds.
    --- Strikes must be at least 2.35 seconds apart.
    --- Each tick has n% chance of making a strikes.
    local dt = os.clock() - lastStrikeTime
    if dt < 4.35 then
        if dt <= 2.35 then -- last strike too recent
            return
        elseif math.random() > (25 / 100) then
            return
        end
    end
    lastStrikeTime = os.clock()

    local strikePos, isWaterStrike = getStrikePos()
    local strikeAoE = 2500 * (isWaterStrike and 2 or 1)

    local eyepos = tes3.getPlayerEyePosition()
    local strikeDist = utils.math.xyDistance(strikePos, eyepos)

    if not tes3.player.data.fm_lightningDisabled then
        -- discourage strikes near anti-strike markers
        if nearestAntiMarkerDistance(strikePos) <= 512 then
            return
        end

        -- target companions first
        for _, companion in ipairs(utils.cells.getNearbyCompanions()) do
            if utils.math.xyDistance(strikePos, companion.position) <= strikeAoE then
                strikePos = companion.position
                applyDamage(companion)
            end
        end

        -- prefer targeting the player if they're closer
        if strikeDist <= strikeAoE then
            local eyevec = tes3.getPlayerEyeVector()
            strikePos = (eyepos + eyevec * 512) * XY
            applyDamage(tes3.player, eyepos + eyevec * 128)
        end
    end

    --- TODO: move strength calculating into `createLightningStrike`
    local strength = math.min(strikeDist, MAX_DISTANCE)
    strength = math.remap(strength, 0, MAX_DISTANCE, 0.4, 0)
    lightning.createLightningStrike(strikePos, strength)

    -- tes3.messageBox("distance: %.2f | shake: %.2f", strikeDist, shakeStrength)
end

event.register(tes3.event.cellChanged, function(e)
    local dist = utils.cells.getFiremothDistance()
    if (dist > MAX_DISTANCE) or e.cell.isInterior then
        STRIKE_TIMER:pause()
    else
        STRIKE_TIMER:resume()
    end
end)

event.register(tes3.event.loaded, function()
    STRIKE_TIMER = timer.start({
        iterations = -1,
        duration = 0.25,
        callback = update,
    })
end)
