local self  = require("openmw.self")
local core  = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local I     = require("openmw.interfaces")
local AI    = I.AI

local damageMult = {}

local registered = false

-- damage boost
local function handleOnHit(attack)
    if not attack or not attack.attacker then return end
    if not attack.attacker:isValid() then return end
    local mult = damageMult[attack.attacker.id]
    if not mult or mult <= 1 then return end
    if attack.damage and attack.damage.health and attack.damage.health > 0 then
        attack.damage.health = attack.damage.health * mult
    end
end

-- combat suppression 
local function followedPlayer()
    local target = nil
    AI.forEachPackage(function(p)
        if p.type == "Follow" and p.target
           and types.Player.objectIsInstance(p.target) then
            target = p.target
        end
    end)
    return target
end

-- a tameable creature was knocked out
local function onSuppressToward(d)
    if not d or not d.victim or not d.duration then return end
    if not d.victim:isValid() then return end
    local victimId = d.victim.id

    local playerTarget = followedPlayer()
    local deadline     = core.getSimulationTime() + d.duration

    if playerTarget then
        -- FOLLOWER PATH: re-issue Follow whenever combat re-targets the victim
        local function loop()
            if types.Actor.isDead(self.object)
               or core.getSimulationTime() >= deadline then
                return
            end
            local active = AI.getActivePackage()
            if active and active.type == "Combat" and active.target
               and active.target.id == victimId then
                AI.startPackage({
                    type        = "Follow",
                    target      = playerTarget,
                    cancelOther = true,
                })
            end
            async:newUnsavableSimulationTimer(0.5, loop)
        end
        loop()
    else
        -- NON-FOLLOWER PATH: filter out Combat against the victim
        local function filterVictimCombat()
            AI.filterPackages(function(p)
                if (p.type == "Combat")
                   and p.target and p.target.id == victimId then
                    return false
                end
                return true
            end)
        end
        filterVictimCombat()

        local function loop()
            if types.Actor.isDead(self.object)
               or core.getSimulationTime() >= deadline then
                return
            end
            if not d.victim:isValid() or types.Actor.isDead(d.victim) then
                return
            end
            filterVictimCombat()
            async:newUnsavableSimulationTimer(0.1, loop)
        end
        loop()
    end
end

-- ENGINE / EVENT HANDLERS

local function onActive()
    if not registered then
        registered = true
        I.Combat.addOnHitHandler(handleOnHit)
    end
    -- ask the global for the current multiplier table
    core.sendGlobalEvent("Tamer_RequestDamageMult", { actor = self.object })
end

local function onInactive()
    core.sendGlobalEvent("Tamer_DamageScriptCleanup", { actor = self.object })
end

-- global pushes the full multiplier table
local function onDamageMultSync(d)
    damageMult = (d and d.mult) or {}
end

return {
    engineHandlers = {
        onActive   = onActive,
        onInactive = onInactive,
    },
    eventHandlers = {
        Tamer_DamageMultSync = onDamageMultSync,
        Tamer_SuppressToward = onSuppressToward,
    },
}