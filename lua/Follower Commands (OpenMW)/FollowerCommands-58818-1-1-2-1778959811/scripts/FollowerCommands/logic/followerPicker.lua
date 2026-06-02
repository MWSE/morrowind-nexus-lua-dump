local types = require("openmw.types")
local storage = require("openmw.storage")
local core = require("openmw.core")
local self = require("openmw.self")

local consts = require("scripts.FollowerCommands.utils.consts")
local messages = require("scripts.FollowerCommands.logic.messages")

local settingsCommands = storage.playerSection("SettingsFollowerCommands_commands")

local fEncumbranceStrMult = core.getGMST("fEncumbranceStrMult")

local picker = {}

---@class PickprobeOptions
---@field type anyType

---@param followers GameObject[]
---@param opts PickprobeOptions
---@return GameObject|nil
---@return integer
picker.pickprobe = function(followers, opts)
    local isLockpick = opts.type == types.Lockpick
    local selectedFollower
    local biggestCount = 0
    local bestScore = 0
    for _, follower in ipairs(followers) do
        if not types.NPC.objectIsInstance(follower) then
            goto continue
        end

        local pickprobes = follower.type.inventory(follower):getAll(opts.type)
        if not pickprobes then goto continue end

        local bestQuality = 0
        local count = 0
        for _, pickprobe in ipairs(pickprobes) do
            local record = pickprobe.type.records[pickprobe.recordId]
            if record.quality >= bestQuality and pickprobe.count > count then
                bestQuality = record.quality
                count = pickprobe.count
            end
        end

        local security = follower.type.stats.skills.security(follower).modified
        local agility = follower.type.stats.attributes.agility(follower).modified
        local luck = follower.type.stats.attributes.luck(follower).modified
        local statModifier = security + agility / 5 + luck / 10

        local score = statModifier * bestQuality
        if score > bestScore and count > biggestCount then
            bestScore = score
            biggestCount = count
            selectedFollower = follower
        end

        ::continue::
    end

    if not selectedFollower then
        local msgType = isLockpick
            and consts.messageTypes.noLockpicks
            or consts.messageTypes.noProbes
        messages.show(self, followers, msgType)
    end

    return selectedFollower, bestScore
end

local function isSummon(recordId)
    return string.find(recordId, "_summon$")
        or recordId == "bonewalker_greater_summ"
end

---@param followers GameObject[]
---@return GameObject|nil
picker.forceUntrap = function(followers)
    local selectedFollower
    local highestHP = settingsCommands:get("kamikazeUntrapMinHealth")
    for _, follower in ipairs(followers) do
        -- summons are disposable
        if isSummon(follower.recordId) then
            return follower
        end

        local health = follower.type.stats.dynamic.health(follower)
        if health.current >= highestHP then
            highestHP = health.current
            selectedFollower = follower
        end
    end

    if not selectedFollower then
        messages.show(self, followers, consts.messageTypes.noForceUntrap)
    end

    return selectedFollower
end

---@class PickprobeOptions
---@field target GameObject

---@param followers GameObject[]
---@param opts PickprobeOptions
---@return GameObject|nil, number
picker.loot = function(followers, opts)
    local selectedFollower
    local biggestCarry = 0
    local totalObjWeight = 0
    local lightestItemWeight = 2 ^ 53
    local cantCarryAll = false

    if types.Item.objectIsInstance(opts.target) then
        totalObjWeight = opts.target.type.records[opts.target.recordId].weight
    else
        local inv = opts.target.type.inventory(opts.target)
        if inv:isResolved() then
            for _, item in ipairs(inv:getAll()) do
                local record = item.type.records[item.recordId]
                totalObjWeight = totalObjWeight + record.weight
                if record.weight < lightestItemWeight then
                    lightestItemWeight = record.weight
                end
            end
        end
    end

    for _, follower in ipairs(followers) do
        if not types.NPC.objectIsInstance(follower) then
            goto continue
        end

        local encumbrance = follower.type.getEncumbrance(follower)
        local strength = follower.type.stats.attributes.strength(follower)
        local freeSpace = strength.modified * fEncumbranceStrMult - encumbrance
        if freeSpace >= totalObjWeight then
            biggestCarry = freeSpace - totalObjWeight
            selectedFollower = follower
            break
        elseif freeSpace >= lightestItemWeight and freeSpace < biggestCarry then
            biggestCarry = freeSpace
            selectedFollower = follower
            cantCarryAll = true
        end

        ::continue::
    end

    if not selectedFollower then
        messages.show(self, followers, consts.messageTypes.noFreeSpace)
    elseif cantCarryAll then
        messages.show(self, selectedFollower, consts.messageTypes.notEnoughFreeSpace)
    end

    return selectedFollower, biggestCarry
end

return picker
