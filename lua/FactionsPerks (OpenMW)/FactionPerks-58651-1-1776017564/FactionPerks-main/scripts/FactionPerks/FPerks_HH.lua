--[[
    HH:
        FPerks_HH1_Passive          - +5 Personality, +10 Speechcraft
        FPerks_HH2_Passive          - +15 Personality, +25 Speechcraft, +25 Illusion
        FPerks_HH3_Passive          - +25 Personality, +50 Mercantile
        FPerks_HH4_Passive          - +25 Personality, +75 Speechcraft

    Honour The Great House (P1+): Guile of the Hlaalu
        Merchant Disposition bonus and Mercantile debuff scale
        continuously with faction reputation via honourScale.
        At rep cap:  +100 Disposition / -30 Mercantile
        Post-cap:    continues growing at 30% of pre-cap rate.
        Applied during active conversation via UiModeChanged,
        removed when dialogue closes. Routed through global script
        since modifyBaseDisposition is global-only.
        Shows "You Honour House Hlaalu." on first merchant
        interaction per conversation.
]]

local ns         = require("scripts.FactionPerks.namespace")
local utils      = require("scripts.FactionPerks.utils")
local notExpelled = utils.notExpelled
local interfaces = require("openmw.interfaces")
local types      = require('openmw.types')
local self       = require('openmw.self')
local core       = require('openmw.core')
local ui         = require('openmw.ui')

-- ============================================================
--  CORE HELPERS
-- ============================================================

local R = interfaces.ErnPerkFramework.requirements

-- Create a table with all the Faction spell effects in it, each object is the perk of that rank
local perkTable = {
    [1] = { passive = {"FPerks_HH1_Passive"} },
    [2] = { passive = {"FPerks_HH2_Passive"} },
    [3] = { passive = {"FPerks_HH3_Passive"} },
    [4] = { passive = {"FPerks_HH4_Passive"} },
}

local setRank = utils.makeSetRank(perkTable, nil)

-- ============================================================
--  HLAALU DIALOGUE EFFECTS
--  Two separate effects are applied on NPC interaction and
--  removed when dialogue closes, both via UiModeChanged:
--
--  1. GUILE OF THE HLAALU - Honour The Great House (P1+)
--     Merchant Disposition bonus and Mercantile debuff scale
--     continuously with faction reputation rather than jumping
--     at perk tiers. Reaches the P4 values at the rep cap.
--     Beyond the cap growth slows significantly.
--     Shows "You Honour House Hlaalu." on first application
--     each conversation.
--
--     At rep cap:  +100 Disposition / -20 Mercantile
--     Formula scales linearly from 0 to cap, then trickles.
--
--  2. GLOBAL DISP DOWNSIDE (P4 only) - -25 Disposition
--     applied to every NPC the player speaks to while holding
--     P4. Removed when dialogue closes.
--
--  Both effects route through global script since
--  modifyBaseDisposition is global-only.
-- ============================================================

-- Maximum values reached at rep cap
local HH_DISP_MAX  = 100
local HH_MERC_MAX  = -30
local hhHasGuile   = false

local function hhScaledValues()
    -- Returns disposition bonus and mercantile debuff scaled by
    -- faction reputation. Uses shared honourScale for consistent
    -- pre/post-cap behaviour across all Honour The Great House effects.
    local scale = utils.honourScale('hlaalu')
    return math.floor(HH_DISP_MAX * scale),
           math.floor(HH_MERC_MAX * scale)
end

local HH_TALK_MODES = {
    Barter         = true,
    Dialogue       = true,
    Training       = true,
    SpellBuying    = true,
    MerchantRepair = true,
    Enchanting     = true,
    Companion      = true,
}

-- Merchant buff tracking
local hhCurrentNpc  = nil
local hhCurrentDisp = 0
local hhCurrentMerc = 0

local function isMerchant(actor)
    if not types.NPC.objectIsInstance(actor) then return false end
    local rec = types.NPC.record(actor)
    return rec and rec.baseGold > 0
end

local hhMerchantMsgShown = false   -- show "You Honour House Hlaalu." once per conversation

local function hhApplyMerchant(npc)
    if not hhHasGuile then return end
    local d, m = hhScaledValues()
    if d == 0 and m == 0 then return end
    core.sendGlobalEvent("FPerks_HH_ApplyMerchant", { npc = npc, disp = d, merc = m })
    hhCurrentNpc  = npc
    hhCurrentDisp = d
    hhCurrentMerc = m
    if not hhMerchantMsgShown then
        ui.showMessage("You Honour House Hlaalu.")
        hhMerchantMsgShown = true
    end
end

-- Remove merchant buff from the current NPC
local function hhRemoveMerchant()
    if not hhCurrentNpc then return end
    core.sendGlobalEvent("FPerks_HH_RemoveMerchant", {
        npc  = hhCurrentNpc,
        disp = hhCurrentDisp,
        merc = hhCurrentMerc,
    })
    hhCurrentNpc  = nil
    hhCurrentDisp = 0
    hhCurrentMerc = 0
end

local function hhOnUiModeChanged(data)
    if not hhHasGuile then return end

    if not data.newMode then
        -- Dialogue closed - remove merchant buff and reset msg flag
        hhRemoveMerchant()
        hhMerchantMsgShown = false
        return
    end

    if HH_TALK_MODES[data.newMode] and data.arg then
        local npc = data.arg
        if npc ~= hhCurrentNpc then
            hhRemoveMerchant()
            if isMerchant(npc) then
                hhApplyMerchant(npc)
            end
        end
    end
end

local function hhClearEffects()
    -- Strips active dialogue effects on respec or expulsion.
    hhRemoveMerchant()
    hhHasGuile         = false
    hhMerchantMsgShown = false
end

-- ============================================================
--  HOUSE HLAALU
--  Primary attribute: Personality
--  Scaling: Speechcraft, Illusion, Mercantile
--  Honour The Great House (P1+): Guile of the Hlaalu -
--           merchant Disposition/Mercantile scales with faction
--           reputation via honourScale.
-- ============================================================

local hh1_id = ns .. "_hh_courtesies"
interfaces.ErnPerkFramework.registerPerk({
    id = hh1_id,
    localizedName = "Hlaalu Courtesies",
    --hidden = true,
    localizedDescription = "The formal pleasantries of Great House Hlaalu open many doors. "
        .. "Merchants warm to you and find their resolve to haggle weakened.\n "
        .. "(+5 Personality, +10 Speechcraft)\n\n "
        .. "Honour the Guile of the Great House Hlaalu: Scaling disposition with Merchants, and improving bartering with Hlaalu Reputation",
    art = "textures\\levelup\\healer", cost = 1,
    requirements = {
        R().minimumFactionRank('hlaalu', 0),
        R().minimumLevel(1)
    },
    onAdd = function()
        setRank(1)
        hhHasGuile = true
    end,
    onRemove = function()
        setRank(nil)
        hhClearEffects()
    end,
})

local hh2_id = ns .. "_hh_silver_tongue"
interfaces.ErnPerkFramework.registerPerk({
    id = hh2_id,
    localizedName = "Silver Tongue",
    --hidden = true,
    localizedDescription = "Your words carry weight. Merchants sense your confidence "
        .. "and their prices soften further.\n "
        .. "Requires Hlaalu Courtesies. "
        .. "(+15 Personality, +25 Speechcraft, +25 Illusion",
    art = "textures\\levelup\\healer", cost = 2,
    requirements = {
        R().hasPerk(hh1_id),
        R().minimumFactionRank('hlaalu', 3),
        R().minimumAttributeLevel('personality', 40),
        R().minimumLevel(5),
    },
    onAdd    = function() setRank(2) end,
    onRemove = function() setRank(nil) end,
})

local hh3_id = ns .. "_hh_trade_acumen"
interfaces.ErnPerkFramework.registerPerk({
    id = hh3_id,
    localizedName = "Trade Acumen",
    --hidden = true,
    localizedDescription = "Merchants treat you as one of their own, dropping their guard further.\n "
        .. "Requires Silver Tongue. "
        .. "(+25 Personality, +50 Mercantile",
    art = "textures\\levelup\\healer", cost = 3,
    requirements = {
        R().hasPerk(hh2_id),
        R().minimumFactionRank('hlaalu', 6),
        R().minimumAttributeLevel('personality', 50),
        R().minimumLevel(10),
    },
    onAdd    = function() setRank(3) end,
    onRemove = function() setRank(nil) end,
})

local hh4_id = ns .. "_hh_councillors_ear"
interfaces.ErnPerkFramework.registerPerk({
    id = hh4_id,
    localizedName = "Councillor's Ear",
    --hidden = true,
    localizedDescription = "A Councillor of House Hlaalu considers you a trusted confidant. "
        .. "Merchants can barely bring themselves to refuse you anything.\n "
        .. "Requires Trade Acumen. "
        .. "(+25 Luck, +75 Speechcraft)",
    art = "textures\\levelup\\healer", cost = 4,
    requirements = {
        R().hasPerk(hh3_id),
        R().minimumFactionRank('hlaalu', 9),
        R().minimumAttributeLevel('personality', 75),
        R().minimumLevel(15),
    },
    onAdd    = function() setRank(4) end,
    onRemove = function() setRank(nil) end,
})

-- ============================================================
--  ENGINE CALLBACKS
-- ============================================================
return {
    eventHandlers = {
        UiModeChanged = hhOnUiModeChanged,
    },
}
