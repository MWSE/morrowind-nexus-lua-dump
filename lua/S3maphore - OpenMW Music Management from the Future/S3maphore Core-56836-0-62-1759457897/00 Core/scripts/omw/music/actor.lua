local I = require("openmw.interfaces")
local core = require 'openmw.core'
local self = require("openmw.self")
local types = require("openmw.types")
local nearby = require("openmw.nearby")

local AI = I.AI

if core.API_REVISION >= 91 then
    local Combat = I.Combat
    Combat.addOnHitHandler(
        function(attack)
            if not attack.successful then return end

            for _, player in ipairs(nearby.players) do
                player:sendEvent('S3maphoreClearTargetCache', self.id)
            end
        end
    )
end

local targets = {}

local function emitTargetsChanged()
    for _, actor in ipairs(nearby.players) do
        actor:sendEvent("OMWMusicCombatTargetsChanged", { actor = self, targets = targets })
    end
end

local function onUpdate(dt)
    if types.Actor.isDeathFinished(self) or not types.Actor.isInActorsProcessingRange(self) then
        if next(targets) ~= nil then
            targets = {}
            emitTargetsChanged()
        end

        return
    end

    -- Early-out for actors without targets and without combat state when the game is not paused
    -- TODO: use events or engine handlers to detect when targets change
    local isStanceNothing = types.Actor.getStance(self) == types.Actor.STANCE.Nothing
    if isStanceNothing and next(targets) == nil and not AI.isFleeing() and dt > 0 then
        return
    end

    local newTargets = AI.getTargets("Combat")

    local changed = false
    if #newTargets ~= #targets then
        changed = true
    else
        for i, target in ipairs(targets) do
            if target ~= newTargets[i] then
                changed = true
                break
            end
        end
    end

    targets = newTargets
    if changed then
        emitTargetsChanged()
    end
end

local function onInactive()
    if next(targets) ~= nil then
        targets = {}
        emitTargetsChanged()
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInactive = onInactive,
    },
}
