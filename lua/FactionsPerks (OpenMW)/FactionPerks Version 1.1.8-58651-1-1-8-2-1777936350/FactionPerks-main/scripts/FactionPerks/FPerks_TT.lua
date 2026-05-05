--[[
    TT:
        FPerks_TT1_Passive          - +3 Intelligence, +3 Willpower,
                                      +5 Restoration, +5 Mysticism
        FPerks_TT2_Passive          - +5 Intelligence, +5 Willpower,
                                      +10 Restoration, +10 Mysticism
        FPerks_TT3_Passive          - +10 Intelligence, +10 Willpower,
                                      +18 Restoration, +18 Mysticism
        FPerks_TT4_Passive          - +15 Intelligence, +15 Willpower,
                                      +25 Restoration, +25 Mysticism

    Non-table spells (granted once, not removed on rank-up):
        "almsivi intervention"      Vanilla spell (P1)
        FPerks_TT2_Cure_All         Power (P2)
        FPerks_TT4_Summon_Army      Power (P4)

    Honoured Ancestors (P3+):
        Ancestor Ghosts, Bonelords, and Bonewalkers will not
        attack the player. Non-summoned instances are calmed
        when they become active in the player's cell.
        Handled via creature.lua ping + player response pattern.
        Reversed cleanly if the perk is lost.
]]

local ns          = require("scripts.FactionPerks.namespace")
local utils       = require("scripts.FactionPerks.utils")
local perkHidden  = utils.perkHidden
local safeAddSpell  = utils.safeAddSpell
local safeRemoveSpell = utils.safeRemoveSpell
local GUILD        = utils.FACTION_GROUPS.temple
local interfaces  = require("openmw.interfaces")
local types       = require('openmw.types')
local self        = require('openmw.self')
local core        = require('openmw.core')
local nearby      = require('openmw.nearby')

local R = interfaces.ErnPerkFramework.requirements

local perkTable = {
    [1] = { passive = {"FPerks_TT1_Passive"} },
    [2] = { passive = {"FPerks_TT2_Passive"} },
    [3] = { passive = {"FPerks_TT3_Passive"} },
    [4] = { passive = {"FPerks_TT4_Passive"} },
}

local setRank = utils.makeSetRank(perkTable, nil)

-- ============================================================
--  HONOURED ANCESTORS - Voice of Reclamation (P3+)
-- ============================================================

local hasTTHonouredAncestors = false

local HONOURED_ANCESTOR_IDS = {
    ["ancestor ghost"] = true,
    ["bonelord"]       = true,
    ["bonewalker"]     = true,
}

local function isHonouredAncestorActor(actor)
    if not types.Creature.objectIsInstance(actor) then return false end
    local id = (types.Creature.record(actor).id or ""):lower()
    for name, _ in pairs(HONOURED_ANCESTOR_IDS) do
        if id:find(name, 1, true) then return true end
    end
    return false
end

local function restoreNearbyAncestors()
    for _, actor in pairs(nearby.actors) do
        if isHonouredAncestorActor(actor) then
            actor:sendEvent(ns .. "_TT_RestoreAncestor", {})
        end
    end
end

local function ancestorSpawned(data)
    if not hasTTHonouredAncestors then return end
    if not data.creature or not data.creature:isValid() then return end
    data.creature:sendEvent(ns .. "_TT_CalmAncestor", {})
end

-- ============================================================
--  TRIBUNAL TEMPLE PERKS
--  Primary attributes: Intelligence, Willpower
--  Scaling: Restoration, Mysticism
--  Special: Almsivi Intervention (P1), Cure All power (P2),
--           Honoured Ancestors (P3+), Summon Army power (P4)
-- ============================================================

local tt1_id = ns .. "_tt_ordinate_aspirant"
interfaces.ErnPerkFramework.registerPerk({
    id = tt1_id,
    localizedName = "Ordinate Aspirant",
    localizedDescription = "You have taken up the Temple's creed and begun study of its mysteries. "
        .. "ALMSIVI turns aside blows and afflictions that threaten their faithful.\
 "
        .. "(+3 Intelligence, +3 Willpower, +5 Restoration, +5 Mysticism, "
        .. "grants Almsivi Intervention)",
    hidden = perkHidden(GUILD, 0, 1),
    art = "textures\\levelup\\healer", cost = 1,
    requirements = {
        R().minimumFactionRank('temple', 0),
        R().minimumLevel(1)
    },
    onAdd = function()
        setRank(1)
        safeAddSpell("almsivi intervention")
    end,
    onRemove = function()
        setRank(nil)
        safeRemoveSpell("almsivi intervention")
    end,
})

local tt2_id = ns .. "_tt_pilgrim_soul"
interfaces.ErnPerkFramework.registerPerk({
    id = tt2_id,
    localizedName = "Pilgrim Soul",
    localizedDescription = "You have walked the Pilgrimages of the Seven Graces. "
        .. "Once each day you may call upon ALMSIVI to cleanse disease, poison, and blight.\
 "
        .. "Requires Ordinate Aspirant. "
        .. "(+5 Intelligence, +5 Willpower, +10 Restoration, +10 Mysticism, "
        .. "1/day Cure Disease + Cure Poison + Cure Blight on Touch)",
    hidden = perkHidden(GUILD, 3, 5),
    art = "textures\\levelup\\healer", cost = 2,
    requirements = {
        R().hasPerk(tt1_id),
        R().minimumFactionRank('temple', 3),
        R().minimumAttributeLevel('willpower', 40),
        R().minimumLevel(5),
    },
    onAdd = function()
        setRank(2)
        safeAddSpell("FPerks_TT2_Cure_All")
    end,
    onRemove = function()
        setRank(nil)
        safeRemoveSpell("FPerks_TT2_Cure_All")
    end,
})

local tt3_id = ns .. "_tt_voice_of_reclamation"
interfaces.ErnPerkFramework.registerPerk({
    id = tt3_id,
    localizedName = "Voice of Reclamation",
    localizedDescription = "The Temple's holy authority now speaks through you. "
        .. "Ancestor Ghosts, Bonelords, and Bonewalkers recognise you as a servant "
        .. "of ALMSIVI and will not raise their hand against you.\
 "
        .. "Requires Pilgrim Soul. "
        .. "(+10 Intelligence, +10 Willpower, +18 Restoration, +18 Mysticism)",
    hidden = perkHidden(GUILD, 6, 10),
    art = "textures\\levelup\\healer", cost = 3,
    requirements = {
        R().hasPerk(tt2_id),
        R().minimumFactionRank('temple', 6),
        R().minimumAttributeLevel('willpower', 50),
        R().minimumLevel(10),
    },
    onAdd = function()
        setRank(3)
        hasTTHonouredAncestors = true
    end,
    onRemove = function()
        setRank(nil)
        hasTTHonouredAncestors = false
        restoreNearbyAncestors()
    end,
})

local tt4_id = ns .. "_tt_hand_of_almsivi"
interfaces.ErnPerkFramework.registerPerk({
    id = tt4_id,
    localizedName = "Hand of ALMSIVI",
    localizedDescription = "You are an instrument of Vivec, Almalexia, and Sotha Sil. "
        .. "Once each day you may call upon honoured ancestors to fight at your side.\
 "
        .. "Requires Voice of Reclamation. "
        .. "(+15 Intelligence, +15 Willpower, +25 Restoration, +25 Mysticism, "
        .. "1/day Summon 2 Greater Bonewalkers + 2 Bonelords for 60s)",
    hidden = perkHidden(GUILD, 9, 15),
    art = "textures\\levelup\\healer", cost = 4,
    requirements = {
        R().hasPerk(tt3_id),
        R().minimumFactionRank('temple', 9),
        R().minimumAttributeLevel('willpower', 75),
        R().minimumLevel(15),
    },
    onAdd = function()
        setRank(4)
        safeAddSpell("FPerks_TT4_Summon_Army")
    end,
    onRemove = function()
        setRank(nil)
        safeRemoveSpell("FPerks_TT4_Summon_Army")
    end,
})

-- ============================================================
--  ENGINE CALLBACKS
-- ============================================================
return {
    eventHandlers = {
        [ns .. "_TT_AncestorSpawned"] = ancestorSpawned,
    },
}