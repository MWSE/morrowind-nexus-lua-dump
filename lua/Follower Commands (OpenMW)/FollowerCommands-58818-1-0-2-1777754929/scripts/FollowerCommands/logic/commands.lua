local storage = require('openmw.storage')
local self = require("openmw.self")
local types = require("openmw.types")
local nearby = require("openmw.nearby")
local core = require("openmw.core")

local consts = require("scripts.FollowerCommands.utils.consts")
local messages = require("scripts.FollowerCommands.logic.messages")
local followerPicker = require("scripts.FollowerCommands.logic.followerPicker")

local settingsCommands = storage.playerSection("SettingsFollowerCommands_commands")

local commands = {}

local function resetAiPackages(follower)
    follower:sendEvent(
        "StartAIPackage",
        {
            type = "Follow",
            target = self,
        }
    )
end

commands.kill = function(followers, target)
    local pkg = { type = "Combat", target = target }
    for _, actor in ipairs(followers) do
        actor:sendEvent("StartAIPackage", pkg)
    end
    return consts.actions.kill
end

commands.travel = function(followers, pos)
    local pkg = {
        type         = "Travel",
        destPosition = nearby.findNearestNavMeshPosition(pos),
        cancelOther  = false,
    }
    for _, follower in ipairs(followers) do
        resetAiPackages(follower)
        follower:sendEvent("StartAIPackage", pkg)
    end
    return consts.actions.travel
end

--- @class InteractOptions
--- @field action         string
--- @field pickFn         fun(followers: GameObject[], opts: table|nil): GameObject, number
--- @field pickOpts       table|nil
--- @field confirmMsg     string
--- @field checkScoreFn   nil|fun(followers: GameObject[], bestScore: number, obj: GameObject): boolean
--- @field lockFollower   boolean|nil
--- @field lockObject     boolean|nil

--- @param followers          GameObject[]
--- @param obj                GameObject
--- @param occupiedObjects    table<number, boolean>
--- @param occupiedFollowers  table<number, boolean>
--- @param opts               InteractOptions
local function commandInteractWithObject(followers, obj, occupiedObjects, occupiedFollowers, opts)
    local selectedFollower, bestScore = opts.pickFn(followers, opts.pickOpts)
    if not selectedFollower then return end

    if opts.checkScoreFn and not opts.checkScoreFn(followers, bestScore, obj) then
        return
    end

    occupiedObjects[obj.id] = opts.lockObject
    occupiedFollowers[selectedFollower.id] = opts.lockFollower

    local destPos = nearby.findNearestNavMeshPosition(obj.position)
    messages.show(self, followers, opts.confirmMsg)
    resetAiPackages(selectedFollower)
    selectedFollower:sendEvent("StartAIPackage", {
        type         = "Travel",
        destPosition = destPos,
        ---@diagnostic disable-next-line: assign-type-mismatch
        cancelOther  = false,
    })

    core.sendGlobalEvent("FollowerCommands_pausedAction", {
        action   = opts.action,
        target   = obj,
        follower = selectedFollower,
        destPos  = destPos,
        player   = self,
    })
end

local function checkIfUnlockable(followers, bestScore, obj)
    local minScore = settingsCommands:get("minUnlockChance")
    if bestScore - obj.type.getLockLevel(obj) < minScore then
        messages.show(self, followers, consts.messageTypes.lockTooComplex)
        return false
    end
    return true
end

commands.lockpick = function(followers, obj, occupiedObjects, occupiedFollowers)
    local action = consts.actions.lockpick
    commandInteractWithObject(followers, obj, occupiedObjects, occupiedFollowers, {
        action        = action,
        pickFn        = followerPicker.pickprobe,
        pickOpts      = { type = types.Lockpick },
        confirmMsg    = consts.messageTypes.lockpickConfirm,
        checkScoreFn  = checkIfUnlockable,
        lockFollower  = true,
        lockObject    = true,
    })
    return action
end

commands.untrap = function(followers, obj, occupiedObjects, occupiedFollowers)
    local action = consts.actions.untrap
    commandInteractWithObject(followers, obj, occupiedObjects, occupiedFollowers, {
        action        = action,
        pickFn        = followerPicker.pickprobe,
        pickOpts      = { type = types.Probe },
        confirmMsg    = consts.messageTypes.untrapConfirm,
        lockFollower  = true,
        lockObject    = true,
    })
    return action
end

commands.forceUntrap = function(followers, obj, occupiedObjects, occupiedFollowers, forceUntrapIgnoredObjects)
    local action = consts.actions.forceUntrap

    local refused = settingsCommands:get("kamikazeUntrapRefuseChance") > math.random(100)
    if forceUntrapIgnoredObjects[obj.id] or refused then
        forceUntrapIgnoredObjects[obj.id] = true
        messages.show(self, followers, consts.messageTypes.forceUntrapRefuse)
    else
        commandInteractWithObject(followers, obj, occupiedObjects, occupiedFollowers, {
            action        = action,
            pickFn        = followerPicker.forceUntrap,
            confirmMsg    = consts.messageTypes.forceUntrapConfirm,
            lockObject    = true,
        })
    end

    return action
end

commands.lootContainer = function(followers, obj, occupiedObjects, occupiedFollowers)
    local action = consts.actions.lootContainer
    commandInteractWithObject(followers, obj, occupiedObjects, occupiedFollowers, {
        action        = action,
        pickFn        = followerPicker.loot,
        pickOpts      = { target = obj },
        confirmMsg    = consts.messageTypes.lootConfirm,
        lockFollower  = true,
        lockObject    = true,
    })
    return action
end

commands.lootItem = function(followers, obj, occupiedObjects, occupiedFollowers)
    local action = consts.actions.lootItem
    commandInteractWithObject(followers, obj, occupiedObjects, occupiedFollowers, {
        action        = action,
        pickFn        = followerPicker.loot,
        pickOpts      = { target = obj },
        confirmMsg    = consts.messageTypes.lootConfirm,
        lockFollower  = true,
        lockObject    = true,
    })
    return action
end

return commands
