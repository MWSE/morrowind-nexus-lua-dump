--[[

FG:
        FPerks_FG1_Passive          - +3 Strength, +3 Endurance, +10 Fortify Health,
                                      +5 Long Blade, +5 Blunt Weapon, +5 Axe
        FPerks_FG2_Passive          - +5 Strength, +5 Endurance, +20 Fortify Health,
                                      +10 Long Blade, +10 Blunt Weapon, +10 Axe
        FPerks_FG3_Passive          - +10 Strength, +10 Endurance, +35 Fortify Health,
                                      +18 Long Blade, +18 Blunt Weapon, +18 Axe
        FPerks_FG4_Passive          - +15 Strength, +15 Endurance, +50 Fortify Health,
                                      +25 Long Blade, +25 Blunt Weapon, +25 Axe
        FPerks_FG3_Enrage           - Power, Fortify Health 50pts, Fortify Fatigue 200pts,
                                      Fortify Attack 100pts, 30s duration.

    NOTE: Fortify Health is applied via stat.modifier so the maximum is raised correctly.
    appliedHealthMod is persisted via onSave/onLoad so the delta calculation is correct
    on reload and bonuses never stack. 
]]

local ns         = require("scripts.FactionPerks.namespace")
local utils      = require("scripts.FactionPerks.utils")
local perkHidden  = utils.perkHidden
local safeAddSpell  = utils.safeAddSpell
local safeRemoveSpell = utils.safeRemoveSpell
local GUILD        = utils.FACTION_GROUPS.fightersGuild
local interfaces = require("openmw.interfaces")
local types      = require('openmw.types')
local self       = require('openmw.self')
local core       = require('openmw.core')
local ambient    = require('openmw.ambient')

local R = interfaces.ErnPerkFramework.requirements

local perkTable = {
    [1] = { passive = {"FPerks_FG1_Passive"} },
    [2] = { passive = {"FPerks_FG2_Passive"} },
    [3] = { passive = {"FPerks_FG3_Passive"} },
    [4] = { passive = {"FPerks_FG4_Passive"} }
}

local fg1_id = ns .. "_fg_dues_paid"
local fg2_id = ns .. "_fg_iron_discipline"
local fg3_id = ns .. "_fg_battle_tested"
local fg4_id = ns .. "_fg_champion_of_the_guild"

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
--  FIGHTERS GUILD COUNTER ATTACK - Iron Discipline (P2+)
-- ============================================================

local lastFGCounterTime = 0

local function getArmorHitSound(actor)
    local cuirass = types.Actor.getEquipment(actor, types.Actor.EQUIPMENT_SLOT.Cuirass)
    if cuirass and types.Armor.objectIsInstance(cuirass) then
        local weight = types.Armor.record(cuirass).weight
        if weight < 10 then
            return "light armor hit"
        elseif weight < 25 then
            return "medium armor hit"
        else
            return "heavy armor hit"
        end
    end
    return "light armor hit"
end

local function getCounterDamage(weapon, attacker)
    local rec = types.Weapon.record(weapon)
    local chop   = (rec.chopMinDamage   + rec.chopMaxDamage)   / 2
    local slash  = (rec.slashMinDamage  + rec.slashMaxDamage)  / 2
    local thrust = (rec.thrustMinDamage + rec.thrustMaxDamage) / 2
    local best   = math.max(chop, slash, thrust)
    local base   = best * (0.75 + math.random() * 0.5)
    local str       = types.Actor.stats.attributes.strength(attacker).modified
    local strFactor = 0.5 + 0.5 * (str / 100)
    local fatigue   = types.Actor.stats.dynamic.fatigue(attacker)
    local maxFat    = math.max(fatigue.base + fatigue.modifier, 1)
    local fatFactor = 0.75 + 0.25 * (fatigue.current / maxFat)
    return math.floor(base * strFactor * fatFactor)
end

interfaces.Combat.addOnHitHandler(function(attack)
    if attack.successful             then return end
    if not attack.weapon             then return end
    if not (attack.attacker and attack.attacker:isValid()) then return end
    if not R().hasPerk(fg2_id).check() then return end

    local cooldown = 10
    if     R().hasPerk(fg4_id).check() then cooldown = 1.5
    elseif R().hasPerk(fg3_id).check() then cooldown = 6
    end

    local now = core.getSimulationTime()
    if (now - lastFGCounterTime) < cooldown then return end

    local playerWeapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if not playerWeapon                               then return end
    if not types.Weapon.objectIsInstance(playerWeapon) then return end

    local dmg = getCounterDamage(playerWeapon, self)
    attack.attacker:sendEvent("FPerks_TakeDamage", { amount = dmg })

    local fatigue = types.Actor.stats.dynamic.fatigue(self)
    fatigue.current = math.max(0, fatigue.current - 8)
    ambient.playSound(getArmorHitSound(attack.attacker))

    lastFGCounterTime = now
    print("FG Counter Attack! Damage: " .. tostring(dmg))
end)

-- ============================================================
--  FIGHTERS GUILD PERKS
-- ============================================================

interfaces.ErnPerkFramework.registerPerk({
    id = fg1_id,
    localizedName = "Dues Paid",
    localizedDescription = "The basic drills are already sharpening your edge.\
 "
        .. "(+3 Strength, +3 Endurance, +10 Fortify Health, "
        .. "+5 Long Blade, +5 Blunt Weapon, +5 Axe)",
    hidden = perkHidden(GUILD, 0, 1),
    art = "textures\\levelup\\knight", cost = 1,
    requirements = {
        R().minimumFactionRank('fighters guild', 0),
        R().minimumLevel(1)
    },
    onAdd    = function() setRank(1); applyHealthMod(10) end,
    onRemove = function() setRank(nil); applyHealthMod(0) end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = fg2_id,
    localizedName = "Iron Discipline",
    localizedDescription = "The Guild's contracts have hardened you. "
        .. "You wade into battle with the confidence of experience. "
        .. "When an enemy swings and misses, you punish the opening immediately.\
 "
        .. "Requires Dues Paid. "
        .. "(+5 Strength, +5 Endurance, +20 Fortify Health, "
        .. "+10 Long Blade, +10 Blunt Weapon, +10 Axe)\
\
"
        .. "Counter Attack: When an enemy misses you with a weapon, "
        .. "you immediately strike back. 10s cooldown.",
    hidden = perkHidden(GUILD, 3, 5),
    art = "textures\\levelup\\knight", cost = 2,
    requirements = {
        R().hasPerk(fg1_id),
        R().minimumFactionRank('fighters guild', 3),
        R().minimumAttributeLevel('strength', 40),
        R().minimumLevel(5),
    },
    onAdd    = function() setRank(2); applyHealthMod(20) end,
    onRemove = function() setRank(nil); applyHealthMod(0) end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = fg3_id,
    localizedName = "Battle Tested",
    localizedDescription = "Daedra, bandits, necromancers - you have killed them all on contract. "
        .. "When the moment demands it, you can call upon a terrifying fury. "
        .. "Your counter attack cooldown is reduced.\
 "
        .. "Requires Iron Discipline. "
        .. "(+10 Strength, +10 Endurance, +35 Fortify Health, "
        .. "+18 Long Blade, +18 Blunt Weapon, +18 Axe, grants Martial Rage power)\
\
"
        .. "Counter Attack cooldown reduced to 6s.",
    hidden = perkHidden(GUILD, 6, 10),
    art = "textures\\levelup\\knight", cost = 3,
    requirements = {
        R().hasPerk(fg2_id),
        R().minimumFactionRank('fighters guild', 6),
        R().minimumAttributeLevel('strength', 50),
        R().minimumLevel(10),
    },
    onAdd = function()
        setRank(3); applyHealthMod(35)
        safeAddSpell("FPerks_FG3_Enrage")
    end,
    onRemove = function()
        setRank(nil); applyHealthMod(0)
        safeRemoveSpell("FPerks_FG3_Enrage")
    end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = fg4_id,
    localizedName = "Champion of the Guild",
    localizedDescription = "The Fighters Guild holds you as one of its finest. "
        .. "Your counter attack is now almost instantaneous.\
 "
        .. "Requires Battle Tested. "
        .. "(+15 Strength, +15 Endurance, +50 Fortify Health, "
        .. "+25 Long Blade, +25 Blunt Weapon, +25 Axe)\
\
"
        .. "Counter Attack cooldown reduced to 1.5s.",
    hidden = perkHidden(GUILD, 9, 15),
    art = "textures\\levelup\\knight", cost = 4,
    requirements = {
        R().hasPerk(fg3_id),
        R().minimumFactionRank('fighters guild', 9),
        R().minimumAttributeLevel('strength', 75),
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
