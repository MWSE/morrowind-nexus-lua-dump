local core = require("openmw.core")

require("scripts.ShelfControl.messages.utils")
require("scripts.ShelfControl.utils.tables")
require("scripts.ShelfControl.utils.consts")
require("scripts.ShelfControl.utils.random")
require("scripts.ShelfControl.utils.openmw_utils")

local l10n = core.l10n("ShelfControl_messages")
local msgSrc = "factionOwned_"

-- +-------------------------------------------------------+
-- | Functions for collecting all messages based on groups |
-- +-------------------------------------------------------+

local function collectGenericMessages(subgroups, ctx)
    local prefix = msgSrc .. "generic"
    local npc = GetRecord(GetRandomLocalNpc(ctx))
    return CollectAllMessagesByPrefix(
        prefix, l10n, AdditionalMsgCtx(npc))
end

local function collectSpecificMessages(subgroups, ctx)
    local msgs = {}
    local npc = GetRecord(GetRandomLocalNpc(ctx))
    for group, _ in pairs(subgroups) do
        local prefix = msgSrc .. "specific_" .. group
        local collectedMsgs = CollectAllMessagesByPrefix(
            prefix, l10n, AdditionalMsgCtx(npc))
        AppendArray(msgs, collectedMsgs)
    end
    return msgs
end

local function collectArchetypeMessages(subgroups, ctx)
    local msgs = {}
    local npc = GetRecord(GetRandomLocalNpc(ctx))
    for group, _ in pairs(subgroups) do
        local prefix = msgSrc .. "archetype_" .. group
        local collectedMsgs = CollectAllMessagesByPrefix(
            prefix, l10n, AdditionalMsgCtx(npc))
        AppendArray(msgs, collectedMsgs)
    end
    return msgs
end

local msgCollectors = {
    generic = collectGenericMessages,
    easterEgg = CollectEggMessages,
    specific = collectSpecificMessages,
    archetype = collectArchetypeMessages,
}

-- +----------+
-- | The core |
-- +----------+

function PickFactionOwnedMessage(ctx)
    local factionId = ctx.owner.factionId
    local msgGroups = {
        generic = true,
        easterEgg = true,
        specific = {
            hlaalu = factionId == "hlaalu",
            redoran = factionId == "redoran",
            tevanni = factionId == "tevanni",
            moragTong = factionId == "morag tong",
        },
        archetype = {
            mage = FactionArchetypes.mage[string.lower(factionId)] == true,
            warrior = FactionArchetypes.warrior[string.lower(factionId)] == true,
            rogue = FactionArchetypes.rogue[string.lower(factionId)] == true,
        },
    }
    local weights = {
        generic   = 20,
        easterEgg = .05,
        specific  = 80,
        archetype = 40,
    }

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
