--[[
TG:
        FPerks_TG1_Passive               = Ability, +5 Agility, +10 Sneak, +10 Security
        FPerks_TG2_Passive               = Ability, +15 Agility, +25 Sneak, +25 Acrobatics
        FPerks_TG3_Passive               = Ability, +25 Agility, +50 Sneak, +50 Mercantile
        FPerks_TG4_Passive               = Ability, +25 Luck, +75 Security
        FPerks_TG3_Cham                  - Ability, 25 Chameleon
        FPerks_TG4_Cham                  - Ability, 50 Chameleon
]]

local ns         = require("scripts.FactionPerks.namespace")
local interfaces = require("openmw.interfaces")
local types      = require('openmw.types')
local self       = require('openmw.self')
local storage    = require('openmw.storage')
local core       = require('openmw.core')
local ui        = require('openmw.ui')


-- ============================================================
--  STORAGE
-- ============================================================
local perkStore = storage.playerSection("FactionPerks")

-- ============================================================
--  CORE HELPERS
-- ============================================================

-- Shorthand requirement builders
local R      = interfaces.ErnPerkFramework.requirements
local utils  = require("scripts.FactionPerks.utils")
local notExpelled = utils.notExpelled

local hasChameleon25 = false
local hasChameleon50 = false

-- Create a table with all the Faction spell effects in it
local perkTable = {
    [1] = { passive = {"FPerks_TG1_Passive"} },
    [2] = { passive = {"FPerks_TG2_Passive"} },
    [3] = {
            passive = {"FPerks_TG3_Passive"},
            flags   = { hasChameleon25 = true },
           },
    [4] = {
            passive = {"FPerks_TG4_Passive"},
            flags   = { hasChameleon50 = true },
           },
}

-- Flag Handler - allows us to control the state of the chameleon flags from multiple locations
local flagHandlers = {
    hasChameleon25 = function(v) hasChameleon25 = v end,
    hasChameleon50 = function(v) hasChameleon50 = v end,
}

local setRank = utils.makeSetRank(perkTable, flagHandlers)

-- ============================================================
--  CHAMELEON (Thieves Guild P3 / P4)
-- ============================================================
local chameleonActive = false

local function chameleonMag()
    local m = 0
    if hasChameleon25 then m = m + 25 end
    if hasChameleon50 then m = m + 50 end
    return m
end
local function applyChameleon()
    if not chameleonActive then
        local m = chameleonMag()
        if m >= 25 then 
            types.Actor.spells(self):add("FPerks_TG3_Cham") 
            chameleonActive = true

            if m == 50 then 
                types.Actor.spells(self):add("FPerks_TG4_Cham") 
            end
        end
    end
end
local function removeChameleon()
    if chameleonActive then
        types.Actor.spells(self):remove("FPerks_TG3_Cham")
        types.Actor.spells(self):remove("FPerks_TG4_Cham")
        chameleonActive = false
    end
end

-- ============================================================
--  onUpdate
-- ============================================================

local function onUpdate()
    -- Chameleon sneak tracking
    if hasChameleon25 or hasChameleon50 then
        if self.controls.sneak == true and not chameleonActive then
            applyChameleon()
        elseif not self.controls.sneak == true and chameleonActive then
            removeChameleon()
            end
    elseif chameleonActive then
        removeChameleon()
    end
end

-- ============================================================
--  THIEVES GUILD
--  Primary attribute: Agility
--  Scaling: Sneak, Security, Acrobatics, Mercantile
--  Special: passive Chameleon 25% (Fence Network) - 50% total
--           (Master Thief) while sneaking
-- ============================================================

local tg1_id = ns .. "_tg_light_fingers"
interfaces.ErnPerkFramework.registerPerk({
    id = tg1_id,
    localizedName = "Light Fingers",
    hidden = false,
    localizedDescription = "Years of petty theft have given you an instinct for opportunity. "
        .. "Your hands are quick and your presence quiet.\n "
        .. "(+5 Agility, +10 Sneak, +10 Security)",
    art = "textures\\levelup\\acrobat", cost = 1,
    requirements = {
        R().minimumFactionRank('thieves guild', 0),
        R().minimumLevel(1)
    },
    onAdd = function()
        setRank(1)
    end,
    onRemove = function()
        setRank(nil)
    end,
})

local tg2_id = ns .. "_tg_shadow_step"
interfaces.ErnPerkFramework.registerPerk({
    id = tg2_id,
    localizedName = "Shadow Step",
    --hidden = true,
    localizedDescription = "You have learned to move between pools of darkness with uncanny ease. "
        .. "Guards look straight through you.\n "
        .. "(+15 Agility, +25 Sneak, +25 Acrobatics)",
    art = "textures\\levelup\\acrobat", cost = 2,
    requirements = {
        R().hasPerk(tg1_id),
        R().minimumFactionRank('thieves guild', 3),
        R().minimumAttributeLevel('agility', 40),
        R().minimumLevel(5),
    },
    onAdd = function()
        setRank(2)
    end,
    onRemove = function()
        setRank(nil)
    end,
})

local tg3_id = ns .. "_tg_fence_network"
interfaces.ErnPerkFramework.registerPerk({
    id = tg3_id,
    localizedName = "Fence Network",
    --hidden = true,
    localizedDescription = "You have cultivated contacts willing to move stolen goods with no "
        .. "questions asked. When you crouch, shadow swallows you whole.\n "
        .. "Requires Shadow Step. "
        .. "(+20 Agility, +50 Sneak, +50 Mercantile, 25% Chameleon while sneaking)",
    art = "textures\\levelup\\acrobat", cost = 3,
    requirements = {
        R().hasPerk(tg2_id),
        R().minimumFactionRank('thieves guild', 6),
        R().minimumAttributeLevel('agility', 50),
        R().minimumLevel(10),
    },
    onAdd = function()
        setRank(3)
    end,
    onRemove = function()
        setRank(nil)
    end,
})

local tg4_id = ns .. "_tg_master_thief"
interfaces.ErnPerkFramework.registerPerk({
    id = tg4_id,
    localizedName = "Master Thief",
    --hidden = true,
    localizedDescription = "There is no lock you cannot pick, no pocket you cannot cut. "
        .. "Crouch, and you vanish almost entirely from sight.\n "
        .. "Requires Fence Network. "
        .. "(+25 Luck, +75 Security, 50% Chameleon while sneaking)",
    art = "textures\\levelup\\acrobat", cost = 4,
    requirements = {
        R().hasPerk(tg3_id),
        R().minimumFactionRank('thieves guild', 9),
        R().minimumAttributeLevel('agility', 75),
        R().minimumLevel(15),
    },
   onAdd = function()
        setRank(4)
    end,
    onRemove = function()
        setRank(nil)
    end,
})

-- ============================================================
--  ENGINE CALLBACKS
-- ============================================================
return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}