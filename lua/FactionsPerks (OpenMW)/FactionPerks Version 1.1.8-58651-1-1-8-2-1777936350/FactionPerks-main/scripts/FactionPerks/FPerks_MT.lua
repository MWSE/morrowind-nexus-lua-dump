--[[
 MT:
        FPerks_MT1_Passive               - +3 Speed, +3 Agility, +5 Sneak, +5 Acrobatics
        FPerks_MT2_Passive               - +5 Speed, +5 Agility, +10 Sneak, +10 Acrobatics
        FPerks_MT3_Passive               - +10 Speed, +10 Agility, +18 Sneak, +18 Acrobatics
        FPerks_MT4_Passive               - +15 Speed, +15 Agility, +25 Sneak, +25 Acrobatics
        FPerks_MT2_Frenzy                - Spell, Frenzy, free, unlimited
        FPerks_MT4_Invisibility          - Spell, Invisibility, free, unlimited
        FPerks_MT4_Lifesteal             - Spell Effect, Absorb Life 25pts 5s
]]

local ns         = require("scripts.FactionPerks.namespace")
local interfaces = require("openmw.interfaces")
local ui         = require('openmw.ui')
local types      = require('openmw.types')
local self       = require('openmw.self')
local core       = require('openmw.core')
local nearby     = require('openmw.nearby')
local storage    = require('openmw.storage')
local async      = require('openmw.async')
local input      = require('openmw.input')

require('scripts.FactionPerks.shared')


local perkStore = storage.playerSection("FactionPerks")
local utils  = require("scripts.FactionPerks.utils")
local perkHidden  = utils.perkHidden
local safeAddSpell  = utils.safeAddSpell
local safeRemoveSpell = utils.safeRemoveSpell
local GUILD        = utils.FACTION_GROUPS.moragTong
local HasMT4 = false

-- ============================================================
--  CORE HELPERS
-- ============================================================

-- Shorthand requirement builders
local R = interfaces.ErnPerkFramework.requirements

-- Create a table with all the Faction spell effects in it
local perkTable = {
    [1] = { passive = {"FPerks_MT1_Passive"} },
    [2] = { passive = {"FPerks_MT2_Passive"} },
    [3] = { passive = {"FPerks_MT3_Passive"} },
    [4] = {
            passive = {"FPerks_MT4_Passive"},
            flags   = { HasMT4 = true }
           },
}

-- Flag Handler - allows us to control the state of the HasMT4 flag from multiple locations
local flagHandlers = {
    HasMT4 = function(v) HasMT4 = v end,
}

-- Perk id prep
local mt1_id = ns .. "_mt_writ_bearer"
local mt2_id = ns .. "_mt_blade_discipline"
local mt3_id = ns .. "_mt_calm_before"
local mt4_id = ns .. "_mt_honoured_executioner"

local setRank = utils.makeSetRank(perkTable, flagHandlers)


-- Morag Tong Life Steal sneak attacks

input.registerActionHandler(input.actions.Sneak.key, async:callback(function() --Whenever you're crouched
    if HasMT4 == true then --If the player has MT perk 4
        for _, actor in pairs(nearby.actors) do -- For each nearby actor
        actor:sendEvent("playerSneaking", self.controls.sneak) --Send them an event handler saying that the player is sneaking -- IGNORE THE LLS THIS WORKS
        end
    end
end))

-- ============================================================
--  MORAG TONG
--  Primary attributes: Speed, Agility
--  Scaling: Sneak, Acrobatics
--  Special: Frenzy power (Blade Discipline),
--           Invisibility power (Honoured Executioner),
--           Lifesteal on sneak attack (Honoured Executioner)
-- ============================================================

interfaces.ErnPerkFramework.registerPerk({
    id = mt1_id,
    localizedName = "Writ Bearer",
    localizedDescription = "You carry the legal sanction of the Morag Tong. "
        .. "Your kills are honoured executions, not murders.\
 "
        .. "(+3 Speed, +3 Agility, +5 Sneak, +5 Acrobatics)",
    hidden = perkHidden(GUILD, 0, 1),
    art = "textures\\levelup\\knight", cost = 1,
    requirements = {
        R().minimumFactionRank('morag tong', 0),
        R().minimumLevel(1)
    },
    onAdd = function()
        setRank(1)
    end,
    onRemove = function()
        setRank(nil)
    end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = mt2_id,
    localizedName = "Blade Discipline",
    localizedDescription = "The Tong teaches economy of motion. Your strikes are precise "
        .. "and swift. You have learned to channel pure battle-fury at will.\
 "
        .. "Requires Writ Bearer. "
        .. "(+5 Speed, +5 Agility, +10 Sneak, +10 Acrobatics, grants Frenzy power)",
    hidden = perkHidden(GUILD, 3, 5),
    art = "textures\\levelup\\knight", cost = 2,
    requirements = {
        R().hasPerk(mt1_id),
        R().minimumFactionRank('morag tong', 3),
        R().minimumAttributeLevel('speed', 40),
        R().minimumLevel(5),
    },
    onAdd = function()
        setRank(2)
        safeAddSpell("FPerks_MT2_Frenzy");
    end,
    onRemove = function()
        setRank(nil)
        safeRemoveSpell("FPerks_MT2_Frenzy");
    end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = mt3_id,
    localizedName = "Calm Before",
    localizedDescription = "You have learned the art of stillness. "
        .. "A Tong assassin who cannot wait cannot succeed.\
 "
        .. "Requires Blade Discipline. "
        .. "(+10 Speed, +10 Agility, +18 Sneak, +18 Acrobatics)",
    hidden = perkHidden(GUILD, 6, 10),
    art = "textures\\levelup\\knight", cost = 3,
    requirements = {
        R().hasPerk(mt2_id),
        R().minimumFactionRank('morag tong', 6),
        R().minimumAttributeLevel('speed', 50),
        R().minimumLevel(10),
    },
    onAdd = function()
        setRank(3)
    end,
    onRemove = function()
        setRank(nil)
    end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = mt4_id,
    localizedName = "Honoured Executioner",
    localizedDescription = "The Grand Master himself has commended your work. "
        .. "The shadows open for you whenever you call upon them.\
 "
        .. "Requires Calm Before. "
        .. "(+15 Speed, +15 Agility, +25 Sneak, +25 Acrobatics, grants Invisibility power)\
\
 "
        .. "Weapon attacks whilst Sneaking inflict a lifesteal effect.",
    hidden = perkHidden(GUILD, 9, 15),
    art = "textures\\levelup\\knight", cost = 4,
    requirements = {
        R().hasPerk(mt3_id),
        R().minimumFactionRank('morag tong', 9),
        R().minimumAttributeLevel('speed', 75),
        R().minimumLevel(15),
    },
    onAdd = function()
        setRank(4)
        safeAddSpell("FPerks_MT4_Invisibility");
    end,
    onRemove = function()
        setRank(nil)
        safeRemoveSpell("FPerks_MT4_Invisibility");
    end,
})