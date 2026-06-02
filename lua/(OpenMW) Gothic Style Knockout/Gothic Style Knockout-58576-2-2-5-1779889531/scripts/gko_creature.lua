local self  = require("openmw.self")
local core  = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local AI    = require("openmw.interfaces").AI

local function getFollowTarget()
    local target = nil
    AI.forEachPackage(function(p)
        if (p.type == "Follow") and p.target
           and types.Player.objectIsInstance(p.target)
        then
            target = p.target
        end
    end)
    return target
end


local function requestCleanup()
    core.sendGlobalEvent("GKD_CreatureScriptCleanup", { creature = self.object })
end

local function onFollowerSuppressCombat(d)
    if not d or not d.duration or not d.victim then
        requestCleanup()
        return
    end
    if not d.victim:isValid() then
        requestCleanup()
        return
    end

    local victimId = d.victim.id
    local playerTarget = getFollowTarget()

    if playerTarget then
        -- FOLLOWER PATH
        AI.startPackage({
            type = "Follow",
            target = playerTarget,
            cancelOther = true,
        })

        local deadline = core.getSimulationTime() + d.duration
        local function loop()
            if not self:isActive() or types.Actor.isDead(self.object) then
                return
            end
            if core.getSimulationTime() >= deadline then
                requestCleanup()
                return
            end

            local activePack = AI.getActivePackage()
            if activePack and activePack.type == "Combat" and activePack.target
               and activePack.target.id == victimId
            then
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
        -- NON-FOLLOWER PATH
        local function filterVictimCombat()
            AI.filterPackages(function(p)
                if (p.type == "Combat" or p.type == "Pursue")
                   and p.target and p.target.id == victimId
                then
                    return false
                end
                return true
            end)
        end

        filterVictimCombat()

        local deadline = core.getSimulationTime() + d.duration
        local function loop()
            if not self:isActive() or types.Actor.isDead(self.object) then
                return
            end
            if core.getSimulationTime() >= deadline then
                requestCleanup()
                return
            end
            if not d.victim:isValid() or types.Actor.isDead(d.victim) then
                requestCleanup()
                return
            end

            filterVictimCombat()
            async:newUnsavableSimulationTimer(0.05, loop)
        end
        loop()
    end
end

local function onActive()
    if getFollowTarget() then
        core.sendGlobalEvent("GKD_RegisterFollower", { actor = self.object })
    else
        -- not a follower, no reason to keep the script attached
        requestCleanup()
    end
end

local function onInactive()
    core.sendGlobalEvent("GKD_UnregisterFollower", { id = self.object.id })
    if getFollowTarget() ~= nil then return end
    requestCleanup()
end

return {
    engineHandlers = {
        onActive   = onActive,
        onInactive = onInactive,
    },
    eventHandlers = {
        GKD_FollowerSuppressCombat = onFollowerSuppressCombat,
    },
}