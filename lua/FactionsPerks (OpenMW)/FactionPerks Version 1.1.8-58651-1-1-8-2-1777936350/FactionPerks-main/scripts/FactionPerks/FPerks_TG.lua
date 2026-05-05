--[[
TG:
        FPerks_TG1_Passive               = Ability, +3 Agility, +3 Speed, +5 Sneak, +5 Security
        FPerks_TG2_Passive               = Ability, +5 Agility, +5 Speed, +10 Sneak, +10 Security
        FPerks_TG3_Passive               = Ability, +10 Agility, +10 Speed, +18 Sneak, +18 Security
        FPerks_TG4_Passive               = Ability, +15 Agility, +15 Speed, +25 Sneak, +25 Security
        FPerks_TG3_Cham                  - Ability, 25 Chameleon
        FPerks_TG4_Cham                  - Ability, 50 Chameleon
]]

local ns         = require("scripts.FactionPerks.namespace")
local interfaces = require("openmw.interfaces")
local types      = require('openmw.types')
local self       = require('openmw.self')
local storage    = require('openmw.storage')
local core       = require('openmw.core')
local ui         = require('openmw.ui')


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
local perkHidden  = utils.perkHidden
local safeAddSpell  = utils.safeAddSpell
local safeRemoveSpell = utils.safeRemoveSpell
local GUILD        = utils.FACTION_GROUPS.thievesGuild

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

-- Perk id prep
local tg1_id = ns .. "_tg_light_fingers"
local tg2_id = ns .. "_tg_shadow_step"
local tg3_id = ns .. "_tg_fence_network"
local tg4_id = ns .. "_tg_master_thief"

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
            safeAddSpell("FPerks_TG3_Cham") 
            chameleonActive = true

            if m == 50 then 
                safeAddSpell("FPerks_TG4_Cham") 
            end
        end
    end
end
local function removeChameleon()
    if chameleonActive then
        safeRemoveSpell("FPerks_TG3_Cham")
        safeRemoveSpell("FPerks_TG4_Cham")
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
        elseif self.controls.sneak ~= true and chameleonActive then
            -- Fixed: was `not self.controls.sneak == true` which parses as
            -- `(not self.controls.sneak) == true` - accidentally correct but
            -- misleading. Rewritten as `self.controls.sneak ~= true` for clarity.
            removeChameleon()
        end
    elseif chameleonActive then
        removeChameleon()
    end
end

-- ============================================================
--  THIEVES GUILD
--  Primary attributes: Agility, Speed
--  Scaling: Sneak, Security
--  Special: passive Chameleon 25% (Fence Network) - 50% total
--           (Master Thief) while sneaking
-- ============================================================

interfaces.ErnPerkFramework.registerPerk({
    id = tg1_id,
    localizedName = "Light Fingers",
    localizedDescription = "Years of petty theft have given you an instinct for opportunity. "
        .. "Your hands are quick and your presence quiet.\
 "
        .. "(+3 Agility, +3 Speed, +5 Sneak, +5 Security)",
    hidden = perkHidden(GUILD, 0, 1),
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

interfaces.ErnPerkFramework.registerPerk({
    id = tg2_id,
    localizedName = "Shadow Step",
    localizedDescription = "You have learned to move between pools of darkness with uncanny ease. "
        .. "Guards look straight through you.\
 "
        .. "Requires Light Fingers. "
        .. "(+5 Agility, +5 Speed, +10 Sneak, +10 Security)",
    hidden = perkHidden(GUILD, 3, 5),
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

interfaces.ErnPerkFramework.registerPerk({
    id = tg3_id,
    localizedName = "Fence Network",
    localizedDescription = "You have cultivated contacts willing to move stolen goods with no "
        .. "questions asked. When you crouch, shadow swallows you whole.\
 "
        .. "Requires Shadow Step. "
        .. "(+10 Agility, +10 Speed, +18 Sneak, +18 Security, 25%% Chameleon while sneaking)",
    hidden = perkHidden(GUILD, 6, 10),
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

interfaces.ErnPerkFramework.registerPerk({
    id = tg4_id,
    localizedName = "Master Thief",
    localizedDescription = "There is no lock you cannot pick, no pocket you cannot cut. "
        .. "Crouch, and you vanish almost entirely from sight.\
 "
        .. "Requires Fence Network. "
        .. "(+15 Agility, +15 Speed, +25 Sneak, +25 Security, 50%% Chameleon while sneaking)",
    hidden = perkHidden(GUILD, 9, 15),
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
