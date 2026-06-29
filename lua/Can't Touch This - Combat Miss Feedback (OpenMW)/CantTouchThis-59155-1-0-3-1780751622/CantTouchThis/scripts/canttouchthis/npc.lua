---@omw-context local
local I                = require("openmw.interfaces")
local core             = require('openmw.core')
local self             = require('openmw.self')
local types            = require('openmw.types')
local isDead           = types.Actor.isDead
local isFleeing        = I.AI.isFleeing
local getActivePackage = I.AI.getActivePackage
local releaseActor     = false
local stateManager     = require('scripts.canttouchthis.controllers.state').new()

local function hasWeirdAIPackage()
    local activeAIPackage = getActivePackage()
    if activeAIPackage then
        if (activeAIPackage.type:lower() == "cast" or
                activeAIPackage.type:lower() == "unknown") then
            return true
        end
    end
    return false
end

local function ferncerEarlyOut()
    if isDead(self) or
        isFleeing() or
        releaseActor or
        hasWeirdAIPackage() then
        return true
    end
    return false
end

I.Combat.addOnHitHandler(function(attack)
    if I.NGardeFencer then return end
    if releaseActor then return end -- turning the onHitHandler into noop if the script is detached
    stateManager:playMissAnimation(attack)
end)

local function onUpdate(dt)
    if I.NGardeFencer then return end
    if core.isWorldPaused() then return end
    if ferncerEarlyOut() then
        stateManager.isStaggered = false
        return
    end
    stateManager:checkStaggerState()
end

local function onScriptAttached()
    releaseActor = false
end
local function onPrepareDetach()
    releaseActor = true
    core.sendGlobalEvent("canttouchthis_actorCleanedUp",{actor = self})
end


return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        canttouchthis_scriptAttached = onScriptAttached,
        canttouchthis_prepareDetach = onPrepareDetach,
    }
}
