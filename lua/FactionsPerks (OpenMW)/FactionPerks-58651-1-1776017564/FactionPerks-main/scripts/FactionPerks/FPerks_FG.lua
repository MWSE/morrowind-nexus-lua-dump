--[[

    FG:

        FPerks_FG1_Passive              - +5 Strength, +10 Fortify Health
        FPerks_FG2_Passive              - +15 Strength, +25 Fortify Health
        FPerks_FG3_Passive              - +25 Strength, +50 Fortify Health
        FPerks_FG4_Passive              - +25 Endurance, +75 Fortify Health, Restore Health 1pt/s, Restore Fatigue 1pt/s
        FPerks_FG3_Enrage               - Power, Fortify Health 50pts, Fortify Fatigue 200pts, Fortify Attack 100pts, 30s duration.


]]

local ns         = require("scripts.FactionPerks.namespace")
local utils      = require("scripts.FactionPerks.utils")
local notExpelled = utils.notExpelled
local interfaces = require("openmw.interfaces")
local types      = require('openmw.types')
local self       = require('openmw.self')
local core       = require('openmw.core')

-- ============================================================
--  CORE HELPERS
-- ============================================================

-- Shorthand requirement builders
local R = interfaces.ErnPerkFramework.requirements


-- Create a table with all the Faction spell effects in it, each object is the perk of that rank
local perkTable = {
    [1] = { passive = {"FPerks_FG1_Passive"} },
    [2] = { passive = {"FPerks_FG2_Passive"} },
    [3] = { passive = {"FPerks_FG3_Passive"} },
    [4] = { passive = {"FPerks_FG4_Passive"} }
}

local setRank = utils.makeSetRank(perkTable, nil)

--- ============================================================
--  FIGHTERS GUILD
--  Primary attribute: Strength
--  Scaling: Fortify Attack (magic effect)
--  Special: Enrage power (Battle Tested),
--           Restore Health + Fatigue ability (Champion of the Guild)
-- ============================================================

local fg1_id = ns .. "_fg_dues_paid"
interfaces.ErnPerkFramework.registerPerk({
    id = fg1_id,
    localizedName = "Dues Paid",
    --hidden = true,
    localizedDescription = "The basic drills are already sharpening your edge.\n "
        .. "(+5 Strength, +10 Fortify Health)",
    art = "textures\\levelup\\knight", cost = 1,
    requirements = {
        R().minimumFactionRank('fighters guild', 0),
        R().minimumLevel(1)
    },
    onAdd = function()
        setRank(1)
    end,
    onRemove = function()
        setRank(nil)
    end
})

local fg2_id = ns .. "_fg_iron_discipline"
interfaces.ErnPerkFramework.registerPerk({
    id = fg2_id,
    localizedName = "Iron Discipline",
    --hidden = true,
    localizedDescription = "The Guild's contracts have hardened you. "
        .. "You wade into battle with the confidence of experience.\n "
        .. "Requires Dues Paid. "
        .. "(+15 Strength, +25 Fortify Health)",
    art = "textures\\levelup\\knight", cost = 2,
    requirements = {
        R().hasPerk(fg1_id),
        R().minimumFactionRank('fighters guild', 3),
        R().minimumAttributeLevel('strength', 40),
        R().minimumLevel(5),
    },
    onAdd = function()
        setRank(2)
    end,
    onRemove = function()
        setRank(nil)
    end
})

local fg3_id = ns .. "_fg_battle_tested"
interfaces.ErnPerkFramework.registerPerk({
    id = fg3_id,
    localizedName = "Battle Tested",
    --hidden = true,
    localizedDescription = "Daedra, bandits, necromancers - you have killed them all on contract. "
        .. "When the moment demands it, you can call upon a terrifying fury.\n "
        .. "Requires Iron Discipline. "
        .. "(+25 Strength, +50 Fortify Health, grants Martial Rage power)",
    art = "textures\\levelup\\knight", cost = 3,
    requirements = {
        R().hasPerk(fg2_id),
        R().minimumFactionRank('fighters guild', 6),
        R().minimumAttributeLevel('strength', 50),
        R().minimumLevel(10),
    },
    onAdd = function()
        setRank(3)
        types.Actor.spells(self):add("FPerks_FG3_Enrage");
    end,
    onRemove = function()
        setRank(nil)
        types.Actor.spells(self):remove("FPerks_FG3_Enrage");
    end
})

local fg4_id = ns .. "_fg_champion_of_the_guild"
interfaces.ErnPerkFramework.registerPerk({
    id = fg4_id,
    localizedName = "Champion of the Guild",
    --hidden = true,
    localizedDescription = "The Fighters Guild holds you as one of its finest. "
        .. "Your body recovers on its own - health and fatigue knit themselves back "
        .. "even in the heat of battle.\n "
        .. "Requires Battle Tested. "
        .. "(+25 Endurance, +75 Fortify Health, Restore Health 1pt/s, Restore Fatigue 1pt/s)",
    art = "textures\\levelup\\knight", cost = 4,
    requirements = {
        R().hasPerk(fg3_id),
        R().minimumFactionRank('fighters guild', 9),
        R().minimumAttributeLevel('strength', 75),
        R().minimumLevel(15),
    },
    onAdd = function()
        setRank(4)
    end,
    onRemove = function()
        setRank(nil)
    end
})