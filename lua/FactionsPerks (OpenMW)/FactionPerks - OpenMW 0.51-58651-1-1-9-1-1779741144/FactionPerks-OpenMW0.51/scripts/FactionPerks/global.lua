--[[
    FactionPerks global.lua

    Handles effects that require global script access:

    House Hlaalu - Guile of the Hlaalu merchant effects:
        FPerks_HH_ApplyMerchant   - apply Disposition and Mercantile
                                    modifiers to a specific NPC when
                                    dialogue opens with a merchant.
        FPerks_HH_RemoveMerchant  - reverse the above when dialogue closes.

    East Empire Company - Empire's Coffers:
        FPerks_EEC_BoostMerchant   - permanently increase a merchant's
                                     barter gold by a given amount.
        FPerks_EEC_RestoreMerchant - reduce a merchant's barter gold by a
                                     given amount (used on perk loss / cleanup).
        FPerks_EEC_SetMerchantGold - set a merchant's barter gold to an exact
                                     value (used by debug console commands).
]]

local world = require('openmw.world')
local types = require('openmw.types')

-- ============================================================
--  HLAALU MERCHANT DISPOSITION
--  modifyBaseDisposition and skill modifiers are global-only,
--  so FPerks_HH.lua sends us the NPC + values to apply/remove.
-- ============================================================

local function onApplyMerchant(data)
    local npc    = data.npc
    local player = world.players[1]
    if not npc or not npc:isValid() then return end
    types.NPC.modifyBaseDisposition(npc, player, data.disp)
    local ms = types.NPC.stats.skills.mercantile(npc)
    if ms then ms.modifier = ms.modifier + data.merc end
end

local function onRemoveMerchant(data)
    local npc    = data.npc
    local player = world.players[1]
    if not npc or not npc:isValid() then return end
    types.NPC.modifyBaseDisposition(npc, player, -data.disp)
    local ms = types.NPC.stats.skills.mercantile(npc)
    if ms then ms.modifier = ms.modifier - data.merc end
end

-- ============================================================
--  EEC MERCHANT GOLD
--  setBarterGold and getBarterGold are global-only APIs.
--  FPerks_EEC.lua sends the NPC + amount to apply or remove.
--  RestoreMerchant floors at 0 to prevent negative gold.
--  SetMerchantGold sets an exact value; used by debug commands.
-- ============================================================

local function onEECBoostMerchant(data)
    local npc = data.npc
    if not npc or not npc:isValid() then return end
    local current = types.Actor.getBarterGold(npc)
    types.Actor.setBarterGold(npc, current + data.amount)
end

local function onEECRestoreMerchant(data)
    local npc = data.npc
    if not npc or not npc:isValid() then return end
    local current = types.Actor.getBarterGold(npc)
    types.Actor.setBarterGold(npc, math.max(0, current - data.amount))
end

local function onEECSetMerchantGold(data)
    local npc = data.npc
    if not npc or not npc:isValid() then return end
    types.Actor.setBarterGold(npc, data.amount)
end

-- ============================================================
--  RETURN
-- ============================================================
return {
    eventHandlers = {
        FPerks_HH_ApplyMerchant    = onApplyMerchant,
        FPerks_HH_RemoveMerchant   = onRemoveMerchant,
        FPerks_EEC_BoostMerchant   = onEECBoostMerchant,
        FPerks_EEC_RestoreMerchant = onEECRestoreMerchant,
        FPerks_EEC_SetMerchantGold = onEECSetMerchantGold,
    },
}
