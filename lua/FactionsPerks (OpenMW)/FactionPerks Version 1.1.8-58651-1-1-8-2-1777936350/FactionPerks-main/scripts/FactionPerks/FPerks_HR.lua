--[[
    HR:
        FPerks_HR1_Passive          - +3 Strength, +3 Endurance,
                                      +10 Fortify Health, +5 Medium Armour, +5 Athletics
        FPerks_HR2_Passive          - +5 Strength, +5 Endurance,
                                      +20 Fortify Health, +10 Medium Armour, +10 Athletics
        FPerks_HR3_Passive          - +10 Strength, +10 Endurance,
                                      +35 Fortify Health, +18 Medium Armour, +18 Athletics
        FPerks_HR4_Passive          - +15 Strength, +15 Endurance,
                                      +50 Fortify Health, +25 Medium Armour, +25 Athletics

    NOTE: Fortify Health is applied via stat.modifier so the maximum is raised correctly.
    appliedHealthMod is persisted via onSave/onLoad so the delta calculation is correct
    on reload and bonuses never stack. 

    Honour The Great House (P1+): Strength of the Redoran
        Incoming weapon hits below the damage threshold are negated.
        Threshold scales with faction reputation via honourScale:
            At rep cap: 20 damage threshold
            Post-cap:   continues growing at 30% of pre-cap rate
        Doubled threshold vs Sixth House enemies, Corprus creatures,
        Ash creatures, and Dreugh.
]]

local ns          = require("scripts.FactionPerks.namespace")
local utils       = require("scripts.FactionPerks.utils")
local perkHidden  = utils.perkHidden
local GUILD        = utils.FACTION_GROUPS.redoran
local interfaces  = require("openmw.interfaces")
local types       = require('openmw.types')
local self        = require('openmw.self')
local ui          = require('openmw.ui')
local ambient     = require('openmw.ambient')

local R = interfaces.ErnPerkFramework.requirements

local perkTable = {
    [1] = { passive = {"FPerks_HR1_Passive"} },
    [2] = { passive = {"FPerks_HR2_Passive"} },
    [3] = { passive = {"FPerks_HR3_Passive"} },
    [4] = { passive = {"FPerks_HR4_Passive"} },
}

local hr1_id = ns .. "_hr_redoran_pledge"
local hr2_id = ns .. "_hr_burden_of_duty"
local hr3_id = ns .. "_hr_unbroken_line"
local hr4_id = ns .. "_hr_guardian_of_the_house"

local setRank = utils.makeSetRank(perkTable, nil)

-- ============================================================
--  FORTIFY HEALTH - stat.modifier with onSave/onLoad
-- ============================================================

local appliedHealthMod = 0

local function applyHealthMod(value)
    local s = types.Actor.stats.dynamic.health(self)
    local delta = value - appliedHealthMod
    s.modifier = s.modifier + delta
    if delta > 0 then
        s.maximum = s.maximum + delta
    end
    appliedHealthMod = value
end

-- ============================================================
--  STRENGTH OF THE REDORAN - Honour The Great House
-- ============================================================

local hasStrengthOfRedoran = false

local SIXTH_HOUSE_CREATURES = {
    ["ash ghoul"]       = true,
    ["ash slave"]       = true,
    ["ash zombie"]      = true,
    ["ash vampire"]     = true,
    ["lame corprus"]    = true,
    ["corprus stalker"] = true,
}

local function isSixthHouseOrDreugh(actor)
    if types.NPC.objectIsInstance(actor) then
        for _, factionId in pairs(types.NPC.getFactions(actor)) do
            if factionId == "sixth house" then return true end
        end
    end
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
    FPerks_DoStrengthOfRedoran(attack)
end)

function FPerks_DoStrengthOfRedoran(attack)
    if not hasStrengthOfRedoran then return false end
    local dmg = attack.damage and attack.damage.health or 0
    if dmg <= 0 then return false end

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
--  HOUSE REDORAN PERKS
-- ============================================================

interfaces.ErnPerkFramework.registerPerk({
    id = hr1_id,
    localizedName = "Redoran Pledge",
    localizedDescription = "You have pledged yourself to House Redoran's code of duty and honour.\
 "
        .. "(+3 Strength, +3 Endurance, +10 Fortify Health, +5 Medium Armour, +5 Athletics)\
\
"
        .. "Honour the Strength of the Great House Redoran: Scaling damage negation "
        .. "threshold with Redoran Reputation. Doubled against Sixth House and Dreugh foes.",
    hidden = perkHidden(GUILD, 0, 1),
    art = "textures\\levelup\\knight", cost = 1,
    requirements = {
        R().minimumFactionRank('redoran', 0),
        R().minimumLevel(1),
    },
    onAdd = function()
        setRank(1)
        hasStrengthOfRedoran = true
        applyHealthMod(10)
    end,
    onRemove = function()
        setRank(nil)
        hasStrengthOfRedoran = false
        applyHealthMod(0)
    end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = hr2_id,
    localizedName = "Burden of Duty",
    localizedDescription = "Redoran warriors do not complain - they endure. "
        .. "The weight of armour and obligation have become one and the same to you.\
 "
        .. "Requires Redoran Pledge. "
        .. "(+5 Strength, +5 Endurance, +20 Fortify Health, +10 Medium Armour, +10 Athletics)",
    hidden = perkHidden(GUILD, 3, 5),
    art = "textures\\levelup\\knight", cost = 2,
    requirements = {
        R().hasPerk(hr1_id),
        R().minimumFactionRank('redoran', 3),
        R().minimumAttributeLevel('endurance', 40),
        R().minimumLevel(5),
    },
    onAdd    = function() setRank(2); applyHealthMod(20) end,
    onRemove = function() setRank(nil); applyHealthMod(0) end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = hr3_id,
    localizedName = "Unbroken Line",
    localizedDescription = "House Redoran does not retreat. You have internalised this truth "
        .. "until it became something closer to armour than principle.\
 "
        .. "Requires Burden of Duty. "
        .. "(+10 Strength, +10 Endurance, +35 Fortify Health, +18 Medium Armour, +18 Athletics)",
    hidden = perkHidden(GUILD, 6, 10),
    art = "textures\\levelup\\knight", cost = 3,
    requirements = {
        R().hasPerk(hr2_id),
        R().minimumFactionRank('redoran', 6),
        R().minimumAttributeLevel('endurance', 50),
        R().minimumLevel(10),
    },
    onAdd    = function() setRank(3); applyHealthMod(35) end,
    onRemove = function() setRank(nil); applyHealthMod(0) end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = hr4_id,
    localizedName = "Guardian of the House",
    localizedDescription = "You are House Redoran's shield made flesh. Your honour is "
        .. "unimpeachable, your resolve unyielding.\
 "
        .. "Requires Unbroken Line. "
        .. "(+15 Strength, +15 Endurance, +50 Fortify Health, +25 Medium Armour, +25 Athletics)",
    hidden = perkHidden(GUILD, 9, 15),
    art = "textures\\levelup\\knight", cost = 4,
    requirements = {
        R().hasPerk(hr3_id),
        R().minimumFactionRank('redoran', 9),
        R().minimumAttributeLevel('endurance', 75),
        R().minimumLevel(15),
    },
    onAdd    = function() setRank(4); applyHealthMod(50) end,
    onRemove = function() setRank(nil); applyHealthMod(0) end,
})

-- ============================================================
--  SAVE / LOAD
-- ============================================================

local function onSave()
    return {
        appliedHealthMod = appliedHealthMod,
    }
end

local function onLoad(data)
    data = data or {}
    appliedHealthMod = data.appliedHealthMod or 0
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    }
}
