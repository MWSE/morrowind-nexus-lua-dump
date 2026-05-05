local self = require('openmw.self')
local types = require('openmw.types')
local config = require('config.config')

local Actor = types.Actor
local NPC = types.NPC

local function computePenalty()
    local encumbrance = Actor.getEncumbrance(self)
    local capacity = Actor.getCapacity(self)
    local encumbrancePercent = 0
    if capacity > 0 then
        encumbrancePercent = encumbrance / capacity
    end
    return encumbrancePercent * (config.swimSpeedMultiplier * 3)
end

local function getAthleticsReduction()
    local athletics = 0
    if NPC.objectIsInstance(self) then
        local stat = NPC.stats.skills.athletics(self)
        athletics = stat and stat.modified or 0
    end
    athletics = math.max(0, math.min(athletics, 100))
    return (athletics / 100) * config.athleticsPenaltyReductionCap
end

local function applyAthleticsReduction(basePenalty)
    return basePenalty * (1 - getAthleticsReduction())
end

local function penaltyToSpeedScale(penalty)
    local scale = 1 / (1 + penalty / 100)
    return math.max(config.minSwimSpeedScale, scale)
end

local function onUpdate(dt)
    if dt <= 0 then
        return
    end

    if not NPC.objectIsInstance(self) then
        return
    end

    if not Actor.isSwimming(self) then
        return
    end

    local penalty = applyAthleticsReduction(computePenalty())
    local speedScale = penaltyToSpeedScale(penalty)
    self.controls.movement = self.controls.movement * speedScale
    self.controls.sideMovement = self.controls.sideMovement * speedScale
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
}
