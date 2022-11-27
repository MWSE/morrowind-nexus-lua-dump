local types = require('openmw.types')
local self = require('openmw.self')
local I = require('openmw.interfaces')

local events = require('scripts.Imperial Stables.common').events

local minDistance = 50

local followingPlayers = {}

local S = {
    stable = nil,
    owner = nil,
}

local function filter(t, callback)
    local result = {}
    for k, v in pairs(t) do
        if callback(k, v) then
            result[k] = v
        end
    end
    return result
end

local function map(t, callback)
    local result = {}
    for k, v in pairs(t) do
        local newK, newV = callback(k, v)
        result[newK] = newV
    end
    return result
end

local function notifyPlayer(player, status)
    player:sendEvent(events.FollowerStatus, {
        actor = self.object,
        status = status,
    })
end

local function isDead()
    local health = self.type.stats.dynamic.health(self)
    return health.current == 0
end

local function moveToStable()
    local activeAI = I.AI.getActivePackage()
    if activeAI
        and (activeAI.type == 'Travel')
        and (activeAI.position == S.stable.position)
    then
        return
    end
    I.AI.filterPackages(function() return false end)
    I.AI.startPackage {
        type = 'Travel',
        destPosition = S.stable.position,
    }
end

local function stayAtStable()
    local activeAI = I.AI.getActivePackage()
    if activeAI and activeAI.type == 'Wander' then
        return
    end
    I.AI.filterPackages(function() return false end)
    I.AI.startPackage {
        type = 'Wander',
        distance = 0,
    }
end

local function follow(actor)
    I.AI.filterPackages(function() return false end)
    I.AI.startPackage {
        type = 'Follow',
        target = actor,
    }
end

local function isAtStable()
    if not S.stable:isValid() then return true end
    if (self.position - S.stable.position):length() < minDistance then return true end
end

local function updateFollowedPlayers()
    local playerTargets = map(
        filter(I.AI.getTargets('Follow'), function(_,target)
            return target and target.type == types.Player and target:isValid()
        end),
        function(_, target)
            return tostring(target), target
        end
    )
    local newPlayers = filter(playerTargets, function(k)
        return not followingPlayers[k]
    end)
    local removedPlayers = filter(followingPlayers, function(k)
        return not playerTargets[k]
    end)
    for _, player in pairs(removedPlayers) do
        followingPlayers[tostring(player)] = nil
        notifyPlayer(player, false)
    end
    for _, player in pairs(newPlayers) do
        followingPlayers[tostring(player)] = player
        notifyPlayer(player, true)
    end
end

local function notifyStable(active)
    if S.stable then
        S.stable:sendEvent(events.CreatureStatus, {
            creature = self.object,
            active = active,
        })
    end
end

local function clearFollowingPlayers()
    for k, player in pairs(followingPlayers) do
        notifyPlayer(player, false)
        followingPlayers[k] = nil
    end
end

local active = true

return {
    engineHandlers = {
        onUpdate = function()
            if not active then return end
            if isDead() then
                clearFollowingPlayers()
            end
            if S.stable then
                if isAtStable() then
                    stayAtStable()
                else
                    moveToStable()
                end
            end
            updateFollowedPlayers()
        end,
        onSave = function()
            return S
        end,
        onLoad = function(saved)
            S = saved
        end,
        onActive = function()
            active = true
            notifyStable(true)
        end,
        onInactive = function()
            active = false
            notifyStable(false)
            clearFollowingPlayers()
        end,
    },
    eventHandlers = {
        [events.Housed] = function(e)
            S.stable = e.stable
            S.owner = e.owner
            moveToStable()
        end,
        [events.Release] = function()
            if not S.owner then return end
            follow(S.owner)
            S.stable = nil
            S.owner = nil
        end,
    },
}