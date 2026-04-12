 --[[
 MT:
        FPerks_MT1_Passive               - +5 Speed, +10 Short Blade, +10 Speechcraft
        FPerks_MT2_Passive               - +15 Speed, +25 Short Blade, +25 Light Armour 
        FPerks_MT3_Passive               - +25 Speed, +50 Sneak, +50 Short Blade
        FPerks_MT4_Passive               - +25 Strength, +75 Short Blade, +75 Sneak
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
local notExpelled = utils.notExpelled
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
--  Primary attribute: Speed
--  Scaling: Short Blade, Unarmored, Sneak
--  Special: Frenzy power (Blade Discipline),
--           Invisibility power (Honoured Executioner)
-- ============================================================

local mt1_id = ns .. "_mt_writ_bearer"
interfaces.ErnPerkFramework.registerPerk({
    id = mt1_id,
    localizedName = "Writ Bearer",
    --hidden = true,
    localizedDescription = "You carry the legal sanction of the Morag Tong. "
        .. "Your kills are honoured executions, not murders.\n "
        .. "(+5 Speed, +10 Short Blade, +10 Speechcraft)",
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

local mt2_id = ns .. "_mt_blade_discipline"
interfaces.ErnPerkFramework.registerPerk({
    id = mt2_id,
    localizedName = "Blade Discipline",
    --hidden = true,
    localizedDescription = "The Tong teaches economy of motion. Your strikes are precise "
        .. "and swift. You have learned to channel pure battle-fury at will.\n "
        .. "Requires Writ Bearer. "
        .. "(+15 Speed, +25 Short Blade, +25 Light Armour, grants Frenzy power)",
    art = "textures\\levelup\\knight", cost = 2,
    requirements = {
        R().hasPerk(mt1_id),
        R().minimumFactionRank('morag tong', 3),
        R().minimumAttributeLevel('speed', 40),
        R().minimumLevel(5),
    },
    onAdd = function()
        setRank(2)
        types.Actor.spells(self):add("FPerks_MT2_Frenzy");
    end,
    onRemove = function()
        setRank(nil)
        types.Actor.spells(self):remove("FPerks_MT2_Frenzy");
    end,
})

local mt3_id = ns .. "_mt_calm_before"
interfaces.ErnPerkFramework.registerPerk({
    id = mt3_id,
    localizedName = "Calm Before",
    --hidden = true,
    localizedDescription = "You have learned the art of stillness. "
        .. "A Tong assassin who cannot wait cannot succeed.\n "
        .. "Requires Blade Discipline. "
        .. "(+25 Speed, +50 Sneak, +50 Short Blade)",
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

local mt4_id = ns .. "_mt_honoured_executioner"
interfaces.ErnPerkFramework.registerPerk({
    id = mt4_id,
    localizedName = "Honoured Executioner",
    --hidden = true,
    localizedDescription = "The Grand Master himself has commended your work. "
        .. "The shadows open for you whenever you call upon them.\n "
        .. "Requires Calm Before. "
        .. "(+25 Strength, +75 Short Blade, grants Invisibility power)\n\n "
        .. "Weapon attacks whilst Sneaking inflict a lifesteal effect. ",
    art = "textures\\levelup\\knight", cost = 4,
    requirements = {
        R().hasPerk(mt3_id),
        R().minimumFactionRank('morag tong', 9),
        R().minimumAttributeLevel('speed', 75),
        R().minimumLevel(15),
    },
    onAdd = function()
        setRank(4)
        types.Actor.spells(self):add("FPerks_MT4_Invisibility");
    end,
    onRemove = function()
        setRank(nil)
        types.Actor.spells(self):remove("FPerks_MT4_Invisibility");
    end,
})
