--[[
    HR:
        FPerks_HR1_Passive          - +5 Endurance, +10 Spear, +10 Athletics
        FPerks_HR2_Passive          - +15 Endurance, +25 Heavy Armor, +25 Block
        FPerks_HR3_Passive          - +25 Endurance, +50 Spear, +50 Block
        FPerks_HR4_Passive          - +25 Strength, +75 Spear, +75 Heavy Armor

    Honour The Great House (P1+): Strength of the Redoran
        Incoming weapon hits below the damage threshold are negated.
        Threshold scales with faction reputation via honourScale:
            At rep cap: 30 damage threshold
            Post-cap:   continues growing at 30% of pre-cap rate
        Doubled threshold vs Sixth House enemies, Corprus creatures,
        Ash creatures, and Dreugh.
        Shows "You Honour House Redoran." when a hit is negated.
        Implemented via DoStrengthOfRedoran in shared context -
        called from npc.lua's hit handler.
]]

local ns          = require("scripts.FactionPerks.namespace")
local utils       = require("scripts.FactionPerks.utils")
local notExpelled = utils.notExpelled
local interfaces  = require("openmw.interfaces")
local types       = require('openmw.types')
local self        = require('openmw.self')
local ui          = require('openmw.ui')
local ambient     = require('openmw.ambient')

local R = interfaces.ErnPerkFramework.requirements

-- Create a table with all the Faction spell effects in it, each object is the perk of that rank
local perkTable = {
    [1] = { passive = {"FPerks_HR1_Passive"} },
    [2] = { passive = {"FPerks_HR2_Passive"} },
    [3] = { passive = {"FPerks_HR3_Passive"} },
    [4] = { passive = {"FPerks_HR4_Passive"} },
}

local setRank = utils.makeSetRank(perkTable, nil)

-- ============================================================
--  STRENGTH OF THE REDORAN - Honour The Great House
--
--  Active from P1. When an incoming weapon hit deals less than
--  the current threshold, it is negated entirely (set to 0).
--
--  Threshold = 20 * honourScale('redoran')
--  At rep 0:   0  (not yet active)
--  At rep cap: 20 (full threshold)
--  Post-cap:   continues growing at 30% of pre-cap rate
--
--  Sixth House enemies (by faction), Corprus creatures, Ash
--  creatures, and Dreugh trigger double the threshold.
--
--  DoStrengthOfRedoran is a global function called from npc.lua.
-- ============================================================

local hasStrengthOfRedoran = false

-- Enemies that receive doubled negation threshold.
-- Named Dagoths and Sixth House NPCs are caught by faction check.
-- Corprus and Ash creatures are not in the sixth house faction
-- record, so are listed explicitly by record ID substring.
local SIXTH_HOUSE_CREATURES = {
    ["ash ghoul"]       = true,
    ["ash slave"]       = true,
    ["ash zombie"]      = true,
    ["ash vampire"]     = true,
    ["lame corprus"]    = true,
    ["corprus stalker"] = true,
}

local function isSixthHouseOrDreugh(actor)
    -- Check sixth house faction membership (named Dagoths etc.)
    if types.NPC.objectIsInstance(actor) then
        for _, factionId in pairs(types.NPC.getFactions(actor)) do
            if factionId == "sixth house" then return true end
        end
    end
    -- Check record ID for explicit creature list and Dreugh
    local rec = nil
    if types.NPC.objectIsInstance(actor) then
        rec = types.NPC.record(actor)
    elseif types.Creature.objectIsInstance(actor) then
        rec = types.Creature.record(actor)
    end
    if rec then
        local id = (rec.id or ""):lower()
        for name, _ in pairs(SIXTH_HOUSE_CREATURES) do
            if id:find(name, 1, true) then return true end
        end
        if id:find("dreugh", 1, true) then return true end
    end
    return false
end

local function redoranThreshold()
    return 20 * utils.honourScale('redoran')
end

interfaces.Combat.addOnHitHandler(function(attack)
    DoStrengthOfRedoran(attack)
end)

function DoStrengthOfRedoran(attack)
    -- Called from npc.lua. Returns true if the hit was negated.
    print(hasStrengthOfRedoran)
    print( attack.damage)
    if not hasStrengthOfRedoran then return false end
    local dmg = attack.damage and attack.damage.health or 0
    if dmg <= 0 then 
        print('No damage to negate')
        return false
    end

    local threshold = redoranThreshold()
    if threshold <= 0 then return false end

    if isSixthHouseOrDreugh(attack.attacker) then
        threshold = threshold * 2
    end

    if dmg < threshold then
        attack.damage.health = 0
        ui.showMessage("You Honour House Redoran.")
        print('damage negated')
        ambient.playSound('light armor hit')
        return true
    end
    
end

-- ============================================================
--  HOUSE REDORAN
--  Primary attribute: Endurance (P1-P3), Strength (P4)
--  Scaling: Spear, Athletics, Heavy Armor, Block
--  Honour The Great House (P1+): Strength of the Redoran
-- ============================================================

local hr1_id = ns .. "_hr_redoran_pledge"
interfaces.ErnPerkFramework.registerPerk({
    id = hr1_id,
    localizedName = "Redoran Pledge",
    --hidden = true,
    localizedDescription = "You have pledged yourself to House Redoran's code of duty and honour.\n "
        .. "(+5 Endurance, +10 Spear, +10 Athletics)\n\n"
        .. "Honour the Strength of the Great House Redoran: Scaling damage negation threshold with Redoran Reputation\n"
        .. "Doubled against Sixth House and Dreugh foes",
    art = "textures\\levelup\\knight", cost = 1,
    requirements = {
        R().minimumFactionRank('redoran', 0),
        R().minimumLevel(1),
    },
    onAdd = function()
        setRank(1)
        hasStrengthOfRedoran = true
    end,
    onRemove = function()
        setRank(nil)
        hasStrengthOfRedoran = false
    end,
})

local hr2_id = ns .. "_hr_burden_of_duty"
interfaces.ErnPerkFramework.registerPerk({
    id = hr2_id,
    localizedName = "Burden of Duty",
    --hidden = true,
    localizedDescription = "Redoran warriors do not complain - they endure. "
        .. "The weight of armour and obligation have become one and the same to you.\n "
        .. "Requires Redoran Pledge. "
        .. "(+15 Endurance, +25 Heavy Armor, +25 Block)",
    art = "textures\\levelup\\knight", cost = 2,
    requirements = {
        R().hasPerk(hr1_id),
        R().minimumFactionRank('redoran', 3),
        R().minimumAttributeLevel('endurance', 40),
        R().minimumLevel(5),
    },
    onAdd    = function() setRank(2) end,
    onRemove = function() setRank(nil) end,
})

local hr3_id = ns .. "_hr_unbroken_line"
interfaces.ErnPerkFramework.registerPerk({
    id = hr3_id,
    localizedName = "Unbroken Line",
    --hidden = true,
    localizedDescription = "House Redoran does not retreat. You have internalised this truth "
        .. "until it became something closer to armour than principle.\n "
        .. "Requires Burden of Duty. "
        .. "(+25 Endurance, +50 Spear, +50 Block)",
    art = "textures\\levelup\\knight", cost = 3,
    requirements = {
        R().hasPerk(hr2_id),
        R().minimumFactionRank('redoran', 6),
        R().minimumAttributeLevel('endurance', 50),
        R().minimumLevel(10),
    },
    onAdd    = function() setRank(3) end,
    onRemove = function() setRank(nil) end,
})

local hr4_id = ns .. "_hr_guardian_of_the_house"
interfaces.ErnPerkFramework.registerPerk({
    id = hr4_id,
    localizedName = "Guardian of the House",
    --hidden = true,
    localizedDescription = "You are House Redoran's shield made flesh. Your honour is "
        .. "unimpeachable, your resolve unyielding.\n "
        .. "Requires Unbroken Line. "
        .. "(+25 Strength, +75 Spear, +75 Heavy Armor)",
    art = "textures\\levelup\\knight", cost = 4,
    requirements = {
        R().hasPerk(hr3_id),
        R().minimumFactionRank('redoran', 9),
        R().minimumAttributeLevel('endurance', 75),
        R().minimumLevel(15),
    },
    onAdd    = function() setRank(4) end,
    onRemove = function() setRank(nil) end,
})
