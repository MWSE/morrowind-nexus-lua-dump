--[[
    IC:
        FPerks_IC1_Passive          - +5 Willpower, +10 Resist Disease, +10 Resist Poison,
                                      +10 Resist Normal Weapons
        FPerks_IC2_Passive          - +15 Willpower, +25 Resist Disease, +25 Resist Poison,
                                      +25 Resist Normal Weapons
        FPerks_IC3_Passive          - +25 Willpower, +50 Resist Disease, +50 Resist Poison,
                                      +50 Resist Normal Weapons
        FPerks_IC4_Passive          - +25 Personality, +75 Resist Disease, +75 Resist Poison,
                                      +75 Resist Normal Weapons

    Non-table spells (granted once, not removed on rank-up):
        "divine intervention"       Vanilla spell (P1)
        FPerks_IC4_AllAttributes    Power (P4)
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
    [1] = { passive = {"FPerks_IC1_Passive"} },
    [2] = { passive = {"FPerks_IC2_Passive"} },
    [3] = { passive = {"FPerks_IC3_Passive"} },
    [4] = { passive = {"FPerks_IC4_Passive"} },
}

local setRank = utils.makeSetRank(perkTable, nil)

local ic1_id = ns .. "_ic_lay_worshipper"
interfaces.ErnPerkFramework.registerPerk({
    id = ic1_id,
    localizedName = "Lay Worshipper",
    localizedDescription = "You have joined the Cult and attend its rites faithfully. "
        .. "The Nine Divines offer you modest but real protection.\n "
        .. "(+5 Willpower, +10 Resist Disease, +10 Resist Poison, "
        .. "+10 Resist Normal Weapons, grants Divine Intervention)",
    art = "textures\\levelup\\healer", cost = 1,
    requirements = {
        R().minimumFactionRank('imperial cult', 0),
        R().minimumLevel(1)
    },
    onAdd = function()
        setRank(1)
        types.Actor.spells(self):add("divine intervention")
    end,
    onRemove = function()
        setRank(nil)
        types.Actor.spells(self):remove("divine intervention")
    end,
})

local ic2_id = ns .. "_ic_charitable_hand"
interfaces.ErnPerkFramework.registerPerk({
    id = ic2_id,
    localizedName = "Charitable Hand",
    localizedDescription = "You have distributed alms and tended to the sick in the name of the Divines. "
        .. "Your faith has strengthened your body as well as your spirit.\n "
        .. "Requires Lay Worshipper. "
        .. "(+15 Willpower, +25 Resist Disease, +25 Resist Poison, +25 Resist Normal Weapons)",
    art = "textures\\levelup\\healer", cost = 2,
    requirements = {
        R().hasPerk(ic1_id),
        R().minimumFactionRank('imperial cult', 3),
        R().minimumAttributeLevel('willpower', 40),
        R().minimumLevel(5),
    },
    onAdd    = function() setRank(2) end,
    onRemove = function() setRank(nil) end,
})

local ic3_id = ns .. "_ic_divine_favour"
interfaces.ErnPerkFramework.registerPerk({
    id = ic3_id,
    localizedName = "Divine Favour",
    localizedDescription = "The Divines have marked you as a servant of true worth.\n "
        .. "Requires Charitable Hand. "
        .. "(+25 Willpower, +50 Resist Disease, +50 Resist Poison, +50 Resist Normal Weapons)",
    art = "textures\\levelup\\healer", cost = 3,
    requirements = {
        R().hasPerk(ic2_id),
        R().minimumFactionRank('imperial cult', 6),
        R().minimumAttributeLevel('willpower', 50),
        R().minimumLevel(10),
    },
    onAdd    = function() setRank(3) end,
    onRemove = function() setRank(nil) end,
})

local ic4_id = ns .. "_ic_blessed_of_the_nine"
interfaces.ErnPerkFramework.registerPerk({
    id = ic4_id,
    localizedName = "Blessed of the Nine",
    localizedDescription = "The Nine Divines have extended their grace to you directly. "
        .. "Once each day you may call upon their full blessing.\n "
        .. "Requires Divine Favour. "
        .. "(+25 Personality, +75 Resist Disease, +75 Resist Poison, +75 Resist Normal Weapons, "
        .. "1/day Fortify All Attributes +50 for 30s)",
    art = "textures\\levelup\\healer", cost = 4,
    requirements = {
        R().hasPerk(ic3_id),
        R().minimumFactionRank('imperial cult', 9),
        R().minimumAttributeLevel('willpower', 75),
        R().minimumLevel(15),
    },
    onAdd = function()
        setRank(4)
        types.Actor.spells(self):add("FPerks_IC4_AllAttributes")
    end,
    onRemove = function()
        setRank(nil)
        types.Actor.spells(self):remove("FPerks_IC4_AllAttributes")
    end,
})
