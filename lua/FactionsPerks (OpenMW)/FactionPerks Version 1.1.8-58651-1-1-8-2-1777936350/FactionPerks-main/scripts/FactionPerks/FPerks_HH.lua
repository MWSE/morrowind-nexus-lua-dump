--[[
    HH:
        FPerks_HH1_Passive          - +3 Personality, +3 Agility, +5 Mercantile, +5 Speechcraft
        FPerks_HH2_Passive          - +5 Personality, +5 Agility, +10 Mercantile, +10 Speechcraft
        FPerks_HH3_Passive          - +10 Personality, +10 Agility, +18 Mercantile, +18 Speechcraft
        FPerks_HH4_Passive          - +15 Personality, +15 Agility, +25 Mercantile, +25 Speechcraft

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
local perkHidden  = utils.perkHidden
local GUILD        = utils.FACTION_GROUPS.hlaalu
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

-- Perk id prep
local hh1_id = ns .. "_hh_courtesies"
local hh2_id = ns .. "_hh_silver_tongue"
local hh3_id = ns .. "_hh_trade_acumen"
local hh4_id = ns .. "_hh_councillors_ear"

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
--     At rep cap:  +100 Disposition / -30 Mercantile
--     Formula scales linearly from 0 to cap, then trickles.
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

-- Original TRADE_SERVICES table - checks servicesOffered fields so that
-- trainers, enchanters, etc. who have baseGold but don't barter goods
-- are correctly excluded from the Hlaalu merchant buff.
local TRADE_SERVICES = {
    Barter      = true, Weapon      = true, Armor       = true,
    Clothing    = true, Books       = true, Ingredients = true,
    Picks       = true, Probes      = true, Lights      = true,
    Apparatus   = true, RepairItems = true, Misc        = true,
    Potions     = true, MagicItems  = true,
}

local function isMerchant(actor)
    if not types.NPC.objectIsInstance(actor) then return false end
    local services = types.NPC.record(actor).servicesOffered
    if not services then return false end
    for service, _ in pairs(TRADE_SERVICES) do
        if services[service] then return true end
    end
    return false
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
--  Primary attributes: Personality, Agility
--  Scaling: Mercantile, Speechcraft
--  Honour The Great House (P1+): Guile of the Hlaalu -
--           merchant Disposition/Mercantile scales with faction
--           reputation via honourScale.
-- ============================================================

interfaces.ErnPerkFramework.registerPerk({
    id = hh1_id,
    localizedName = "Hlaalu Courtesies",
    localizedDescription = "The formal pleasantries of Great House Hlaalu open many doors. "
        .. "Merchants warm to you and find their resolve to haggle weakened.\
 "
        .. "(+3 Personality, +3 Agility, +5 Mercantile, +5 Speechcraft)\
\
 "
        .. "Honour the Guile of the Great House Hlaalu: Scaling disposition with Merchants, "
        .. "and improving bartering with Hlaalu Reputation",
    hidden = perkHidden(GUILD, 0, 1),
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

interfaces.ErnPerkFramework.registerPerk({
    id = hh2_id,
    localizedName = "Silver Tongue",
    localizedDescription = "Your words carry weight. Merchants sense your confidence "
        .. "and their prices soften further.\
 "
        .. "Requires Hlaalu Courtesies. "
        .. "(+5 Personality, +5 Agility, +10 Mercantile, +10 Speechcraft)",
    hidden = perkHidden(GUILD, 3, 5),
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

interfaces.ErnPerkFramework.registerPerk({
    id = hh3_id,
    localizedName = "Trade Acumen",
    localizedDescription = "Merchants treat you as one of their own, dropping their guard further.\
 "
        .. "Requires Silver Tongue. "
        .. "(+10 Personality, +10 Agility, +18 Mercantile, +18 Speechcraft)",
    hidden = perkHidden(GUILD, 6, 10),
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

interfaces.ErnPerkFramework.registerPerk({
    id = hh4_id,
    localizedName = "Councillor's Ear",
    localizedDescription = "A Councillor of House Hlaalu considers you a trusted confidant. "
        .. "Merchants can barely bring themselves to refuse you anything.\
 "
        .. "Requires Trade Acumen. "
        .. "(+15 Personality, +15 Agility, +25 Mercantile, +25 Speechcraft)",
    hidden = perkHidden(GUILD, 9, 15),
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
