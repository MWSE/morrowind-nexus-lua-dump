--[[
    IL:
        FPerks_IL1_Passive          - +3 Endurance, +3 Strength, +5 Heavy Armour,
                                      +5 Block, +10 Fortify Fatigue
        FPerks_IL2_Passive          - +5 Endurance, +5 Strength, +10 Heavy Armour,
                                      +10 Block, +20 Fortify Fatigue
        FPerks_IL3_Passive          - +10 Endurance, +10 Strength, +18 Heavy Armour,
                                      +18 Block, +35 Fortify Fatigue
        FPerks_IL4_Passive          - +15 Endurance, +15 Strength, +25 Heavy Armour,
                                      +25 Block, +50 Fortify Fatigue

    NOTE: Fortify Fatigue is applied via stat.modifier so the maximum is raised correctly.
    appliedFatigueMod is persisted via onSave/onLoad so the delta calculation is correct
    on reload and bonuses never stack. 

    Non-table spells (granted once, not removed on rank-up):
        FPerks_IL3_Prowess          - Power (granted at P3, removed on full respec only)

    Legionary's Resolve (P2+):
        On successful block:
            - Reflects damage to the attacker based on Block skill
              (Block skill x 0.25, so 10 at skill 40, 25 at skill 100)
            - Restores a portion of the fatigue spent blocking:
                P2: 30% of fatigue cost restored
                P3: 50% of fatigue cost restored
                P4: 75% of fatigue cost restored
]]

local ns          = require("scripts.FactionPerks.namespace")
local utils       = require("scripts.FactionPerks.utils")
local perkHidden  = utils.perkHidden
local safeAddSpell  = utils.safeAddSpell
local safeRemoveSpell = utils.safeRemoveSpell
local GUILD        = utils.FACTION_GROUPS.imperialLegion
local interfaces  = require("openmw.interfaces")
local types       = require('openmw.types')
local self        = require('openmw.self')
local core        = require('openmw.core')
local ambient     = require('openmw.ambient')

local R = interfaces.ErnPerkFramework.requirements

local perkTable = {
    [1] = { passive = {"FPerks_IL1_Passive"} },
    [2] = { passive = {"FPerks_IL2_Passive"} },
    [3] = { passive = {"FPerks_IL3_Passive"} },
    [4] = { passive = {"FPerks_IL4_Passive"} },
}

local il1_id = ns .. "_il_legion_recruit"
local il2_id = ns .. "_il_shield_wall"
local il3_id = ns .. "_il_forced_march"
local il4_id = ns .. "_il_legate"

local setRank = utils.makeSetRank(perkTable, nil)

-- ============================================================
--  FORTIFY FATIGUE - stat.modifier with onSave/onLoad
-- ============================================================

local appliedFatigueMod = 0

local function applyFatigueMod(value)
    local s = types.Actor.stats.dynamic.fatigue(self)
    local delta = value - appliedFatigueMod
    s.modifier = s.modifier + delta
    if delta > 0 then
        s.maximum = s.maximum + delta
    end
    appliedFatigueMod = value
end

-- ============================================================
--  LEGIONARY'S RESOLVE - Shield Wall (P2+)
-- ============================================================

local ilLastAttacker     = nil
local ilFatigueBeforeHit = 0

local IL_FATIGUE_RESTORE = {
    [2] = 0.30,
    [3] = 0.50,
    [4] = 0.75,
}

local IL_FATIGUE_PROXY_SCALAR = 0.5

local function getILRank()
    if R().hasPerk(il4_id).check() then return 4 end
    if R().hasPerk(il3_id).check() then return 3 end
    if R().hasPerk(il2_id).check() then return 2 end
    return nil
end

interfaces.Combat.addOnHitHandler(function(attack)
    ilLastAttacker     = nil
    ilFatigueBeforeHit = 0

    local rank = getILRank()
    if not rank then return end
    if not attack.attacker or not attack.attacker:isValid() then return end

    ilLastAttacker     = attack.attacker
    ilFatigueBeforeHit = types.Actor.stats.dynamic.fatigue(self).current
end)

interfaces.SkillProgression.addSkillUsedHandler(function(skillId, params)
    if skillId ~= "block" then return end

    local rank = getILRank()
    if not rank then return end
    if not ilLastAttacker or not ilLastAttacker:isValid() then return end

    local blockSkill = types.NPC.stats.skills.block(self).modified
    local reflectDmg = math.floor(blockSkill * 0.25)

    ilLastAttacker:sendEvent("FPerks_TakeDamage", { amount = reflectDmg })

    local fatigueNow  = types.Actor.stats.dynamic.fatigue(self).current
    local fatigueCost = math.max(0, ilFatigueBeforeHit - fatigueNow)

    if fatigueCost <= 0 then
        fatigueCost = reflectDmg * IL_FATIGUE_PROXY_SCALAR
        print("IL Resolve: fatigue delta was 0, using proxy: " .. fatigueCost)
    else
        print("IL Resolve: fatigue delta precise: " .. fatigueCost)
    end

    local restorePercent = IL_FATIGUE_RESTORE[rank]
    local fatigueRestore = math.floor(fatigueCost * restorePercent)

    if fatigueRestore > 0 then
        local fatigue    = types.Actor.stats.dynamic.fatigue(self)
        local maxFatigue = fatigue.base + fatigue.modifier
        fatigue.current  = math.min(fatigue.current + fatigueRestore, maxFatigue)
    end

    ambient.playSound("conjuration hit")

    print("IL Resolve: reflected=" .. reflectDmg
        .. " fatigue restored=" .. fatigueRestore
        .. " (" .. (restorePercent * 100) .. "% of " .. fatigueCost .. ")")

    ilLastAttacker     = nil
    ilFatigueBeforeHit = 0
end)

-- ============================================================
--  IMPERIAL LEGION PERKS
-- ============================================================

local function guildRank(rank)
    local reqs = {
        R().minimumFactionRank('imperial legion', rank),
    }
    if core.contentFiles.has("tamriel_data.esm") then
        table.insert(reqs, R().minimumFactionRank('t_cyr_imperiallegion', rank))
        table.insert(reqs, R().minimumFactionRank('t_sky_imperiallegion', rank))
    end
    if #reqs == 1 then return reqs[1] end
    return R().orGroup(table.unpack(reqs))
end

interfaces.ErnPerkFramework.registerPerk({
    id = il1_id,
    localizedName = "Legion Recruit",
    localizedDescription = "You have sworn the oath and donned the cuirass. "
        .. "The Legion's drillmasters have improved your guard.\
 "
        .. "(+3 Endurance, +3 Strength, +5 Heavy Armour, +5 Block, +10 Fortify Fatigue)",
    hidden = perkHidden(GUILD, 0, 1),
    art = "textures\\levelup\\knight", cost = 1,
    requirements = {
        guildRank(0),
        R().minimumLevel(1)
    },
    onAdd    = function() setRank(1); applyFatigueMod(10) end,
    onRemove = function() setRank(nil); applyFatigueMod(0) end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = il2_id,
    localizedName = "Shield Wall",
    localizedDescription = "You have mastered the disciplined defensive formations "
        .. "of the Imperial army. When you block an attack, the force is turned "
        .. "back against your attacker, and the effort of blocking costs you less.\
 "
        .. "Requires Legion Recruit. "
        .. "(+5 Endurance, +5 Strength, +10 Heavy Armour, +10 Block, +20 Fortify Fatigue)\
\
"
        .. "Legionary's Resolve: Blocking reflects damage to your attacker "
        .. "based on your Block skill. Restores 30%% of fatigue spent blocking.",
    hidden = perkHidden(GUILD, 3, 5),
    art = "textures\\levelup\\knight", cost = 2,
    requirements = {
        R().hasPerk(il1_id),
        guildRank(3),
        R().minimumAttributeLevel('endurance', 40),
        R().minimumLevel(5),
    },
    onAdd    = function() setRank(2); applyFatigueMod(20) end,
    onRemove = function() setRank(nil); applyFatigueMod(0) end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = il3_id,
    localizedName = "Forced March",
    localizedDescription = "The Legion demands its soldiers keep pace regardless "
        .. "of terrain. When the situation demands it, you can push far beyond "
        .. "normal limits. Blocking now restores 50%% of fatigue spent.\
 "
        .. "Requires Shield Wall. "
        .. "(+10 Endurance, +10 Strength, +18 Heavy Armour, +18 Block, +35 Fortify Fatigue, "
        .. "grants Legion's Prowess power)",
    hidden = perkHidden(GUILD, 6, 10),
    art = "textures\\levelup\\knight", cost = 3,
    requirements = {
        R().hasPerk(il2_id),
        guildRank(6),
        R().minimumAttributeLevel('endurance', 50),
        R().minimumLevel(10),
    },
    onAdd = function()
        setRank(3); applyFatigueMod(35)
        safeAddSpell("FPerks_IL3_Prowess")
    end,
    onRemove = function()
        setRank(nil); applyFatigueMod(0)
        safeRemoveSpell("FPerks_IL3_Prowess")
    end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = il4_id,
    localizedName = "Legate",
    localizedDescription = "You command the respect of every soldier who serves "
        .. "alongside you. The Emperor's discipline has forged your body into "
        .. "something that endures. Blocking now restores 75%% of fatigue spent.\
 "
        .. "Requires Forced March. "
        .. "(+15 Endurance, +15 Strength, +25 Heavy Armour, +25 Block, +50 Fortify Fatigue)",
    hidden = perkHidden(GUILD, 9, 15),
    art = "textures\\levelup\\knight", cost = 4,
    requirements = {
        R().hasPerk(il3_id),
        guildRank(9),
        R().minimumAttributeLevel('endurance', 75),
        R().minimumLevel(15),
    },
    onAdd    = function() setRank(4); applyFatigueMod(50) end,
    onRemove = function() setRank(nil); applyFatigueMod(0) end,
})

-- ============================================================
--  SAVE / LOAD
-- ============================================================

local function onSave()
    return {
        appliedFatigueMod = appliedFatigueMod,
    }
end

local function onLoad(data)
    data = data or {}
    appliedFatigueMod = data.appliedFatigueMod or 0
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    }
}
