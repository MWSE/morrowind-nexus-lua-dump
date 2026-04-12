--[[
    TT:
        FPerks_TT1_Passive          - +5 Intelligence, +10 Reflect, +10 Resist Paralysis,
                                      +10 Resist Blight Disease
        FPerks_TT2_Passive          - +15 Intelligence, +25 Reflect, +25 Resist Paralysis,
                                      +25 Resist Blight Disease
        FPerks_TT3_Passive          - +25 Intelligence, +50 Reflect, +50 Resist Paralysis,
                                      +50 Resist Blight Disease
        FPerks_TT4_Passive          - +25 Personality, +75 Reflect, +75 Resist Paralysis,
                                      +75 Resist Blight Disease

    Non-table spells (granted once, not removed on rank-up):
        "almsivi intervention"      Vanilla spell (P1)
        FPerks_TT2_Cure_All         Power (P2)
        FPerks_TT4_Summon_Army      Power (P4)
]]

local ns         = require("scripts.FactionPerks.namespace")
local utils      = require("scripts.FactionPerks.utils")
local notExpelled = utils.notExpelled
local interfaces = require("openmw.interfaces")
local types      = require('openmw.types')
local self       = require('openmw.self')
local core       = require('openmw.core')

local R = interfaces.ErnPerkFramework.requirements

local perkTable = {
    [1] = { passive = {"FPerks_TT1_Passive"} },
    [2] = { passive = {"FPerks_TT2_Passive"} },
    [3] = { passive = {"FPerks_TT3_Passive"} },
    [4] = { passive = {"FPerks_TT4_Passive"} },
}

local setRank = utils.makeSetRank(perkTable, nil)

-- ============================================================
--  TRIBUNAL TEMPLE
--  Primary attribute: Intelligence (P1-P3), Personality (P4)
--  Scaling: Reflect, Resist Paralysis, Resist Blight Disease
--  Special: Almsivi Intervention (P1), Cure All power (P2),
--           Summon Army power (P4)
-- ============================================================

local tt1_id = ns .. "_tt_ordinate_aspirant"
interfaces.ErnPerkFramework.registerPerk({
    id = tt1_id,
    localizedName = "Ordinate Aspirant",
    --hidden = true,
    localizedDescription = "You have taken up the Temple's creed and begun study of its mysteries. "
        .. "ALMSIVI turns aside blows and afflictions that threaten their faithful.\n "
        .. "(+5 Intelligence, +10 Reflect, +10 Resist Paralysis, "
        .. "+10 Resist Blight Disease, grants Almsivi Intervention)",
    art = "textures\\levelup\\healer", cost = 1,
    requirements = {
        R().minimumFactionRank('temple', 0),
        R().minimumLevel(1)
    },
    onAdd = function()
        setRank(1)
        types.Actor.spells(self):add("almsivi intervention")
    end,
    onRemove = function()
        setRank(nil)
        types.Actor.spells(self):remove("almsivi intervention")
    end,
})

local tt2_id = ns .. "_tt_pilgrim_soul"
interfaces.ErnPerkFramework.registerPerk({
    id = tt2_id,
    localizedName = "Pilgrim Soul",
    --hidden = true,
    localizedDescription = "You have walked the Pilgrimages of the Seven Graces. "
        .. "Once each day you may call upon ALMSIVI to cleanse disease, poison, and blight.\n "
        .. "Requires Ordinate Aspirant. "
        .. "(+15 Intelligence, +25 Reflect, +25 Resist Paralysis, +25 Resist Blight Disease, "
        .. "1/day Cure Disease + Cure Poison + Cure Blight on Touch)",
    art = "textures\\levelup\\healer", cost = 2,
    requirements = {
        R().hasPerk(tt1_id),
        R().minimumFactionRank('temple', 3),
        R().minimumAttributeLevel('willpower', 40),
        R().minimumLevel(5),
    },
    onAdd = function()
        setRank(2)
        types.Actor.spells(self):add("FPerks_TT2_Cure_All")
    end,
    onRemove = function()
        setRank(nil)
        types.Actor.spells(self):remove("FPerks_TT2_Cure_All")
    end,
})

local tt3_id = ns .. "_tt_voice_of_reclamation"
interfaces.ErnPerkFramework.registerPerk({
    id = tt3_id,
    localizedName = "Voice of Reclamation",
    --hidden = true,
    localizedDescription = "The Temple's holy authority now speaks through you.\n "
        .. "Requires Pilgrim Soul. "
        .. "(+25 Intelligence, +50 Reflect, +50 Resist Paralysis, +50 Resist Blight Disease)",
    art = "textures\\levelup\\healer", cost = 3,
    requirements = {
        R().hasPerk(tt2_id),
        R().minimumFactionRank('temple', 6),
        R().minimumAttributeLevel('willpower', 50),
        R().minimumLevel(10),
    },
    onAdd    = function() setRank(3) end,
    onRemove = function() setRank(nil) end,
})

local tt4_id = ns .. "_tt_hand_of_almsivi"
interfaces.ErnPerkFramework.registerPerk({
    id = tt4_id,
    localizedName = "Hand of ALMSIVI",
    --hidden = true,
    localizedDescription = "You are an instrument of Vivec, Almalexia, and Sotha Sil. "
        .. "Once each day you may call upon honoured ancestors to fight at your side.\n "
        .. "Requires Voice of Reclamation. "
        .. "(+25 Personality, +75 Reflect, +75 Resist Paralysis, +75 Resist Blight Disease, "
        .. "1/day Summon 2 Greater Bonewalkers + 2 Bonelords for 60s)",
    art = "textures\\levelup\\healer", cost = 4,
    requirements = {
        R().hasPerk(tt3_id),
        R().minimumFactionRank('temple', 9),
        R().minimumAttributeLevel('willpower', 75),
        R().minimumLevel(15),
    },
    onAdd = function()
        setRank(4)
        types.Actor.spells(self):add("FPerks_TT4_Summon_Army")
    end,
    onRemove = function()
        setRank(nil)
        types.Actor.spells(self):remove("FPerks_TT4_Summon_Army")
    end,
})
