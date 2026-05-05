local self = require("openmw.self")
local I = require("openmw.interfaces")
local core = require("openmw.core")
local anim = require("openmw.animation")
local util = require("openmw.util")

local consts = require("scripts.FollowerCommands.utils.consts")
local messages = require("scripts.FollowerCommands.logic.messages")

local iMaxActivateDist = core.getGMST("iMaxActivateDist") + 0.1
local fEncumbranceStrMult = core.getGMST("fEncumbranceStrMult")

local target
local action
local player
local isItem
local upperAnim

local onUpdateFired = false

--- Returns the world-space position of an actor's head center.
--- @param actor      GameObject
--- @param headHeight number|nil  Normalized [0;1] head center height (default 0.85)
--- @return Vector3
local function getHeadPosition(actor, headHeight)
    headHeight   = headHeight or consts.headHeight
    local bbox   = actor:getBoundingBox()
    local center = bbox.center
    local half   = bbox.halfSize
    return util.vector3(
        center.x,
        center.y,
        center.z - half.z + headHeight * (2 * half.z)
    )
end

--- Returns whether a world-space position is above a normalized height threshold on an actor.
--- @param actor     GameObject
--- @param pos       Vector3    Position to test (e.g. item center)
--- @param threshold number|nil Normalized [0;1] cutoff (default 0.2)
--- @return boolean
local function isAboveThreshold(actor, pos, threshold)
    threshold    = threshold or consts.footHeight
    local bbox   = actor:getBoundingBox()
    local center = bbox.center
    local half   = bbox.halfSize
    local t      = (pos.z - center.z + half.z) / (2 * half.z)
    return t > threshold
end

local function lootStack(freeSpace, item)
    local record = item.type.records[item.recordId]
    local count = item.count
    local weight = record.weight

    if freeSpace >= count * weight then
        return count, weight
    else
        return math.floor(freeSpace / weight), weight
    end
end

local function lootContainer()
    local encumbrance = self.type.getEncumbrance(self)
    local strength = self.type.stats.attributes.strength(self)
    local freeSpace = strength.modified * fEncumbranceStrMult - encumbrance

    local inv = target.type.inventory(target)
    if not inv:isResolved() then return end

    local lootedItems = {}
    for _, item in ipairs(inv:getAll()) do
        local lootableStack, weight = lootStack(freeSpace, item)
        freeSpace = freeSpace - lootableStack * weight
        if freeSpace > 0 then
            lootedItems[#lootedItems + 1] = { item = item, count = lootableStack }
        end
    end

    core.sendGlobalEvent(
        "FollowerCommands_lootItems",
        { actor = self, items = lootedItems }
    )
end

local function freeSelf()
    self:enableAI(true)
    core.sendGlobalEvent(
        "FollowerCommands_detachScript",
        { follower = self, action = action }
    )
    player:sendEvent(
        "FollowerCommands_objectFreed",
        { target = target, follower = self, action = action }
    )
end

local function onInit(data)
    action = data.action
    target = data.target
    player = data.player
    isItem = data.action == consts.actions.lootItem
end

local function onUpdate(dt)
    if onUpdateFired
        or not I.AI.getActivePackage()
        or I.AI.getActivePackage().type ~= "Follow"
    then
        return
    end

    onUpdateFired = true

    local activeEffects = self.type.activeEffects(self)
    ---@diagnostic disable-next-line: missing-parameter
    local telekinesis = activeEffects:getEffect(core.magic.EFFECT_TYPE.Telekinesis)
    local teleBonus = telekinesis and telekinesis.magnitude * 22 or 0
    local reach = iMaxActivateDist + teleBonus
    local headPos = getHeadPosition(self)
    if (headPos - target:getBoundingBox().center):length() > reach then
        freeSelf()
        messages.show(player, self, consts.messageTypes.cantReach)
        return
    end

    self:enableAI(false)
    upperAnim = isAboveThreshold(self, target:getBoundingBox().center)

    I.AnimationController.addTextKeyHandler(
        upperAnim and "loot01" or "loot02",
        function(groupname, key)
            if key == "attach" then
                if isItem then
                    local encumbrance = self.type.getEncumbrance(self)
                    local strength = self.type.stats.attributes.strength(self)
                    local freeSpace = strength.modified * fEncumbranceStrMult - encumbrance
                    local lootableStack, _ = lootStack(freeSpace, target)
                    local lootedItems = { { item = target, count = lootableStack } }
                    core.sendGlobalEvent(
                        "FollowerCommands_lootItems",
                        { actor = self, items = lootedItems }
                    )
                else
                    lootContainer()
                end
            elseif key == "stop" then
                freeSelf()
            end
        end
    )

    I.AnimationController.playBlendedAnimation(
        upperAnim and "loot01" or "loot02",
        {
            startKey = 'start',
            stopKey = 'stop',
            priority = anim.PRIORITY.Scripted,
            speed = upperAnim and .9 or 1,
        }
    )
end

local function onLoad(data)
    if not data then return end
    target = data.target or target
    action = data.action or action
    player = data.player or player
end

local function onSave()
    return {
        target = target,
        action = action,
        player = player,
    }
end

return {
    engineHandlers = {
        onInit = onInit,
        onUpdate = onUpdate,
        onLoad = onLoad,
        onSave = onSave,
    },
}
