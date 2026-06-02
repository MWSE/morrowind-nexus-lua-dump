local types = require("openmw.types")
local world = require("openmw.world")
local core = require("openmw.core")

require("scripts.ShelfControl.messages.utils")
require("scripts.ShelfControl.utils.tables")
require("scripts.ShelfControl.utils.consts")
require("scripts.ShelfControl.utils.random")

local l10n = core.l10n("ShelfControl_messages")
local msgSrc = "buyable_"

-- +------------------------------------------+
-- | Dedicated functions for conditial groups |
-- +------------------------------------------+

local function ordinatorCity(ctx)
    -- by city name
    local cell = ctx.book.cell
    local cellName = string.lower(cell.name)
    for _, city in pairs(CitiesWithOrdinators) do
        if string.find(string.lower(cellName), city) then
            return true
        end
    end
    -- by ordinators nearby
    for _, actor in pairs(world.activeActors) do
        if actor.type ~= types.NPC then goto continue end
        if string.find(string.lower(actor.recordId), "ordinator") then
            return true
        end
        ::continue::
    end
    return false
end

local function multipleVendorsNearby(ctx)
    local vendorCount = 0

    for _, actor in pairs(world.activeActors) do
        if actor.type ~= types.NPC then goto continue end

        local actorRecord = GetRecord(actor)
        local isVendor = false
        for _, isOffered in pairs(actorRecord.servicesOffered) do
            if isOffered then
                isVendor = true
                break
            end
        end
        if not isVendor then goto continue end

        vendorCount = vendorCount + 1
        if vendorCount >= MANY_VENDORS_THRESHOLD then
            return true
        end

        ::continue::
    end
    return false
end

-- +------------------------------+
-- | Rules for conditional groups |
-- +------------------------------+

local unlockableRules = {
    {
        cond = function(ctx)
            local quests = ctx.player.type.quests(ctx.player)
            return quests["A1_1_FindSpymaster"].stage >= 14
        end,
        key = "caiusMet"
    },
    {
        cond = function(ctx)
            local quests = ctx.player.type.quests(ctx.player)
            return quests["A2_6_Incarnate"].stage >= 70
        end,
        key = "nerevarine"
    },
}

local specificRules = {
    {
        cond = function(ctx) return ctx.owner.recordId == "jobasha" end,
        key = "ownedByJobasha",
    },
    {
        cond = ordinatorCity,
        key = "ordinatorsNearby",
    },
    {
        cond = multipleVendorsNearby,
        key = "multipleVendorsNearby",
    },
    {
        cond = function(ctx)
            local disp = ctx.owner.self.type.getDisposition(ctx.owner.self, ctx.player)
            return disp <= LOW_DISPOSITION
        end,
        key = "dispositionLow"
    },
}

-- +----------------------------------+
-- | Rules for non-conditional groups |
-- +----------------------------------+

local function checkRacialMessages(actor)
    local race = GetRecord(actor).race
    local firstRacialMsgKey = msgSrc .. "racial_" .. race .. "_1"
    return l10n(firstRacialMsgKey) ~= firstRacialMsgKey
end

local function checkFactionMessages(actor)
    for _, faction in pairs(actor.type.getFactions(actor)) do
        local firstFactionMsgKey = msgSrc .. "faction_" .. faction .. "_1"
        if l10n(firstFactionMsgKey) ~= firstFactionMsgKey then
            return true
        end
    end
    return false
end

-- +-------------------------------------------------------+
-- | Functions for collecting all messages based on groups |
-- +-------------------------------------------------------+

local function collectGenericMessages(subgroups, ctx)
    local prefix = msgSrc .. "generic"
    return CollectAllMessagesByPrefix(prefix, l10n)
end

local function collectUnlockableMessages(subgroups, ctx)
    local msgs = {}
    for group, _ in pairs(subgroups) do
        local prefix = msgSrc .. "unlockable_" .. group
        local collectedMsgs = CollectAllMessagesByPrefix(prefix, l10n)
        AppendArray(msgs, collectedMsgs)
    end
    return msgs
end

local function collectRacialMessages(subgroups, ctx)
    local msgs = {}
    for group, _ in pairs(subgroups) do
        local actor = ctx[group].self
        local race = GetRecord(actor).race
        local prefix = msgSrc .. "racial_" .. group .. race
        local collectedMsgs = CollectAllMessagesByPrefix(prefix, l10n)
        AppendArray(msgs, collectedMsgs)
    end
    return msgs
end

local function collectFactionMessages(subgroups, ctx)
    local msgs = {}
    for group, _ in pairs(subgroups) do
        local actor = ctx[group].self
        for _, faction in pairs(actor.type.getFactions(actor)) do
            local prefix = msgSrc .. "faction_" .. group .. faction
            local collectedMsgs = CollectAllMessagesByPrefix(prefix, l10n)
            AppendArray(msgs, collectedMsgs)
        end
    end
    return msgs
end

local function collectSpecificMessages(subgroups, ctx)
    local msgs = {}
    for group, _ in pairs(subgroups) do
        local prefix = msgSrc .. "specific_" .. group
        local collectedMsgs = CollectAllMessagesByPrefix(prefix, l10n)
        AppendArray(msgs, collectedMsgs)
    end
    return msgs
end

local msgCollectors = {
    generic = collectGenericMessages,
    easterEgg = CollectEggMessages,
    unlockable = collectUnlockableMessages,
    racial = collectRacialMessages,
    faction = collectFactionMessages,
    specific = collectSpecificMessages,
}

-- +----------+
-- | The core |
-- +----------+

function PickBuyableMessage(ctx)
    local msgGroups = {
        generic = true,
        easterEgg = true,
        unlockable = {
            caiusMet = false,
            nerevarine = false,
        },
        racial = {
            player = false,
            owner = false,
        },
        faction = {
            player = false,
            owner = false,
        },
        specific = {
            ownedByJobasha = false,
            ordinatorsNearby = false,
            multipleVendorsNearby = false,
            dispositionLow = false,
        },
    }
    local weights = {
        generic    = 30,
        easterEgg  = .1,
        unlockable = 1,
        racial     = 10,
        faction    = 10,
        specific   = 100,
    }

    -- collect all possible message groups
    -- racial
    msgGroups.racial.owner = checkRacialMessages(ctx.owner.self)
    msgGroups.racial.player = checkRacialMessages(ctx.player)
    -- faction
    msgGroups.faction.owner = checkFactionMessages(ctx.owner.self)
    msgGroups.faction.player = checkFactionMessages(ctx.player)
    -- unlockable
    for _, rule in ipairs(unlockableRules) do
        if rule.cond(ctx) then
            msgGroups.unlockable[rule.key] = true
        end
    end
    -- specific
    for _, rule in ipairs(specificRules) do
        if rule.cond(ctx) then
            msgGroups.specific[rule.key] = true
        end
    end

    PruneMessageGroups(msgGroups, weights)

    local pickedGroup = PickRandomWeightedKey(NormalizeWeights(weights))

    local msgCollector = msgCollectors[pickedGroup]
    local msgs = msgCollector(msgGroups[pickedGroup], ctx)
    if msgs then
        return RandomChoice(msgs)
    else
        return l10n("error")
    end
end
