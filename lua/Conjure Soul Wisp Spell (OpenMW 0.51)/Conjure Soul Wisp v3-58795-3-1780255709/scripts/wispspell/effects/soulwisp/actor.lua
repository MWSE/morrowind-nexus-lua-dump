local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local common = require('scripts.wispspell.common')

local state = {
    nextPoll = 0,
    lastCombatTargetId = nil,
    lastIsPlayerAlly = nil,
}

local function valid(object)
    return common.isValid(object)
end

local function currentCombatTarget()
    if not I.AI or not I.AI.getActiveTarget then return nil end

    local ok, target = pcall(I.AI.getActiveTarget, 'Combat')
    if ok and valid(target) then return target end
    return nil
end

local function packageTargets(packageType)
    if not I.AI or not I.AI.getTargets then return {} end

    local ok, targets = pcall(I.AI.getTargets, packageType)
    if ok and type(targets) == 'table' then return targets end
    return {}
end

local function packageTargetsPlayer(packageType)
    for _, target in ipairs(packageTargets(packageType)) do
        if valid(target) and types.Player.objectIsInstance(target) then
            return true
        end
    end
    return false
end

local function isFollowingOrEscortingPlayer()
    -- Follow/Escort packages usually sit underneath Combat while a follower is
    -- defending itself. AI.getTargets checks all packages, so this still works
    -- while Combat is the active package.
    return packageTargetsPlayer('Follow') or packageTargetsPlayer('Escort')
end

local function report(force)
    local combatTarget = currentCombatTarget()
    local combatTargetId = valid(combatTarget) and combatTarget.id or nil
    local isPlayerAlly = isFollowingOrEscortingPlayer()

    -- Positive reports are repeated to keep the global cache fresh. Peaceful
    -- actors report only when their relevant state changes or the script is
    -- forced to report, which avoids noisy events from every nearby actor.
    if force or isPlayerAlly or valid(combatTarget)
        or combatTargetId ~= state.lastCombatTargetId
        or isPlayerAlly ~= state.lastIsPlayerAlly
    then
        state.lastCombatTargetId = combatTargetId
        state.lastIsPlayerAlly = isPlayerAlly
        core.sendGlobalEvent('RT_SoulWispHostilityUpdate', {
            actor = self.object,
            combatTarget = combatTarget,
            isPlayerAlly = isPlayerAlly,
        })
    end
end

local function reportInactive()
    state.lastCombatTargetId = nil
    state.lastIsPlayerAlly = false
    core.sendGlobalEvent('RT_SoulWispHostilityUpdate', {
        actor = self.object,
        combatTarget = nil,
        isPlayerAlly = false,
    })
end

return {
    engineHandlers = {
        onInit = function()
            report(true)
        end,
        onLoad = function(save)
            state = save or state
            state.nextPoll = 0
            state.lastCombatTargetId = nil
            state.lastIsPlayerAlly = nil
        end,
        onSave = function()
            -- The global script keeps only a short-lived combat-state cache, so
            -- there is no need to preserve transient combat state across saves.
            return {}
        end,
        onInactive = reportInactive,
        onUpdate = function()
            local now = core.getSimulationTime()
            if now < (state.nextPoll or 0) then return end
            state.nextPoll = now + common.hostilityPollInterval
            report(false)
        end,
    },
}
