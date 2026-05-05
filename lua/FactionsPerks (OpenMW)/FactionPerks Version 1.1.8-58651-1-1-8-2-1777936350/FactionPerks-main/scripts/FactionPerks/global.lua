--[[
    FactionPerks global.lua

    Handles effects that require global script access:

    House Hlaalu - Guile of the Hlaalu merchant effects:
        FPerks_HH_ApplyMerchant   - apply Disposition and Mercantile
                                    modifiers to a specific NPC when
                                    dialogue opens with a merchant.
        FPerks_HH_RemoveMerchant  - reverse the above when dialogue closes.
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
--  RETURN
-- ============================================================
return {
    eventHandlers = {
        FPerks_HH_ApplyMerchant  = onApplyMerchant,
        FPerks_HH_RemoveMerchant = onRemoveMerchant,
    },
}