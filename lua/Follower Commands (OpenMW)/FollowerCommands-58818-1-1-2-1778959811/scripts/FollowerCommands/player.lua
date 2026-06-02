local storage = require('openmw.storage')
local self = require("openmw.self")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local async = require("openmw.async")
local camera = require("openmw.camera")
local types = require("openmw.types")
local nearby = require("openmw.nearby")
local anim = require("openmw.animation")
local core = require("openmw.core")

local deps = require("scripts.FollowerCommands.utils.dependencies")
local consts = require("scripts.FollowerCommands.utils.consts")
local camUtil = require("scripts.FollowerCommands.utils.camera")
local ownership = require("scripts.FollowerCommands.logic.ownership")
local commands = require("scripts.FollowerCommands.logic.commands")
local messages = require("scripts.FollowerCommands.logic.messages")

local settings = storage.playerSection("SettingsFollowerCommands_settings")
local settingsCommands = storage.playerSection("SettingsFollowerCommands_commands")

deps.checkAll(self, "Follower Commands", { {
    plugin = "FollowerDetectionUtil.omwscripts",
    interface = I.FollowerDetectionUtil,
} })

local lastCommand
local lastHitObj
local occupiedObjects = {}
local occupiedFollowers = {}
local forceUntrapIgnoredObjects = {}

local function playCommandAnim()
    local animKey = settings:get("animationVariant") == "kcommand_random"
        and "kcommand0" .. tostring(math.random(1, 4))
        or settings:get("animationVariant")
    I.AnimationController.playBlendedAnimation(
        animKey,
        {
            startKey = 'start',
            stopKey = 'stop',
            ---@diagnostic disable-next-line: assign-type-mismatch
            priority = {
                [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted,
                [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted,
            },
            autoDisable = true,
            blendMask = anim.BLEND_MASK.LeftArm
                + anim.BLEND_MASK.Torso
                + anim.BLEND_MASK.RightArm
                + anim.BLEND_MASK.LowerBody,
            speed = 1
        }
    )
end

local function getMyFollowers()
    local myFollowers = {}
    local followerList = I.FollowerDetectionUtil.getFollowerList()
    if not followerList or not next(followerList) then
        return myFollowers
    end

    for _, state in pairs(followerList) do
        local isMyFollower = state.leader and state.leader.id == self.id
            or state.superLeader and state.superLeader.id == self.id
        if isMyFollower and not occupiedFollowers[state.actor.id] then
            myFollowers[#myFollowers + 1] = state.actor
        end
    end
    return myFollowers
end

local function isEmpty(container)
    local inv = container.type.inventory(container)
    print(not inv:isResolved(), inv.resolve)
    if not inv:isResolved() then
        return false
    else
        return #container.type.inventory(container):getAll() == 0
    end
end

input.registerTriggerHandler(
    consts.commandTriggerKey,
    async:callback(function()
        playCommandAnim()

        local myFollowers = getMyFollowers()
        if #myFollowers == 0 then return end

        -- raycast
        local pos, v = camUtil.getCameraDirData(camera.getPosition(), false)
        local dist = settings:get("maxDistance")
        local destPos = (pos + v * dist)
        local cast = nearby.castRenderingRay(pos, destPos, { ignore = { table.unpack(myFollowers), self } })
        if not cast.hitPos then return end

        local obj = cast.hitObject
        -- no object was hit
        if not obj then
            lastCommand = commands.travel(myFollowers, cast.hitPos)
            return
            -- object was hit, but is unavailable
        elseif occupiedObjects[obj.id] or not obj:isValid() then
            return
        end

        -- determining the action
        -- object classification
        local isLockable    = types.Lockable.objectIsInstance(obj)
        local isActor       = types.Actor.objectIsInstance(obj)
        local isContainer   = types.Container.objectIsInstance(obj)
        local isItem        = types.Item.objectIsInstance(obj)

        -- object state
        local isScripted = obj.type.records[obj.recordId].mwscript
        local isDead        = isActor and types.Actor.isDead(obj)
        local isLocked      = isLockable and types.Lockable.isLocked(obj)
        local isTrapped     = isLockable and types.Lockable.getTrapSpell(obj)
        local isLootalbeItem = isItem and obj.type.isCarriable(obj) and not isScripted

        -- ownership permissions
        local isOwned       = ownership.isOwned(self, obj)
        local unlockOwned   = not isOwned or settingsCommands:get("unlockOwned")
        local lootOwned     = not isOwned or settingsCommands:get("lootOwned")

        -- interaction predicates
        local hitAliveActor = isActor and not isDead
        local hitContainer  = (isContainer or isDead)
            and not isEmpty(obj)
            and not isScripted
        local isIllegal     = (isLocked and not unlockOwned)
            or (isContainer and not lootOwned)
            or (isItem and not lootOwned)
        local forceUntrap   = isTrapped
            and lastCommand == consts.actions.untrap
            and lastHitObj == obj

        if hitAliveActor then
            lastCommand = commands.kill(myFollowers, obj)
        elseif isIllegal then
            lastCommand = nil
            messages.show(self, myFollowers, consts.messageTypes.illegal)
        elseif isLocked then
            lastCommand = commands.lockpick(myFollowers, obj, occupiedObjects, occupiedFollowers)
        elseif forceUntrap then
            lastCommand = commands.forceUntrap(myFollowers, obj,
                occupiedObjects, occupiedFollowers, forceUntrapIgnoredObjects)
        elseif isTrapped then
            lastCommand = commands.untrap(myFollowers, obj, occupiedObjects, occupiedFollowers)
        elseif hitContainer then
            lastCommand = commands.lootContainer(myFollowers, obj, occupiedObjects, occupiedFollowers)
        elseif isLootalbeItem then
            lastCommand = commands.lootItem(myFollowers, obj, occupiedObjects, occupiedFollowers)
        else
            lastCommand = commands.travel(myFollowers, cast.hitPos)
        end

        -- resole the inventory while actor is walking towards the container
        if hitContainer and not obj.type.inventory(obj):isResolved() then
            core.sendGlobalEvent("FollowerCommands_resolve", obj)
        end

        -- print(lastCommand)
        lastHitObj = obj
    end)
)

local function onLoad(data)
    if not data then return end
    forceUntrapIgnoredObjects = data.forceUntrapIgnoredObjects or forceUntrapIgnoredObjects
end

local function onSave()
    return {
        forceUntrapIgnoredObjects = forceUntrapIgnoredObjects,
    }
end

-- I.AnimationController.addTextKeyHandler(
--     "",
--     function(groupname, key)
--         print(groupname, "|", key)
--     end
-- )

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        FollowerCommands_objectFreed = function(data)
            occupiedObjects[data.target.id] = nil
            occupiedFollowers[data.follower.id] = nil
        end,
        FollowerCommands_triggerCommand = function()
            input.activateTrigger(consts.commandTriggerKey)
        end,
    }
}
