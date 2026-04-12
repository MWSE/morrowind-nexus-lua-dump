--[[
    HT:
        FPerks_HT1_Passive          - +5 Intelligence, +10 Enchant, +10 Alchemy,
                                      +10 Spell Absorption
        FPerks_HT2_Passive          - +15 Intelligence, +25 Enchant, +25 Alchemy,
                                      +25 Spell Absorption
        FPerks_HT3_Passive          - +25 Intelligence, +50 Enchant, +50 Alchemy,
                                      +50 Spell Absorption,
                                      Fortify Maximum Magicka 0.5x Intelligence (magnitude 5)
        FPerks_HT4_Passive          - +25 Willpower, +75 Enchant, +75 Alchemy,
                                      +75 Spell Absorption,
                                      Fortify Maximum Magicka 1.0x Intelligence (magnitude 10)

    Non-table spells (granted once, not removed on rank-up):
        "strong levitate"             Vanilla spell (P1)
        "mark"                        Vanilla spell (P2)
        "recall"                      Vanilla spell (P2)

    Honour The Great House (P1+): Wit of the Telvanni
        When the player drinks a potion, a scaled bonus is applied
        to each of its effects via activeEffects:modify + cleanup timer.
        Application is delayed 0.1s via async so the engine has time
        to process the potion before we augment its effects.
        Cleanup fires at duration + 0.1s to reverse each bonus.
        At rep cap:  +150% of base magnitude (total 250% effect)
        Post-cap:    continues growing at 30% of pre-cap rate.
        Shows "You Honour House Telvanni." on first potion
        consumed per session while the perk is held.
]]

local ns         = require("scripts.FactionPerks.namespace")
local utils      = require("scripts.FactionPerks.utils")
local notExpelled = utils.notExpelled
local interfaces = require("openmw.interfaces")
local types      = require('openmw.types')
local self       = require('openmw.self')
local ui         = require('openmw.ui')

local async      = require('openmw.async')

local R = interfaces.ErnPerkFramework.requirements

local perkTable = {
    [1] = { passive = {"FPerks_HT1_Passive"} },
    [2] = { passive = {"FPerks_HT2_Passive"} },
    [3] = { passive = {"FPerks_HT3_Passive"} },
    [4] = { passive = {"FPerks_HT4_Passive"} },
}

local setRank = utils.makeSetRank(perkTable, nil)

-- ============================================================
--  HOUSE TELVANNI
--  Primary attribute: Intelligence (P1-P3), Willpower (P4)
--  Scaling: Enchant, Alchemy, Spell Absorption,
--           Fortify Maximum Magicka
--  Honour The Great House (P1+): Wit of the Telvanni —
--           potion effects are augmented based on faction rep.
--           At rep cap: full additional magnitude (effectively
--           double the potion's effects). Beyond cap: trickles.
--  Special: Strong Levitate (P1), Mark + Recall (P2),
--           Restore Magicka abilities (P3 + P4 stacking).
-- ============================================================

-- ============================================================
--  WIT OF THE TELVANNI — Honour The Great House
--
--  When the player drinks a potion, we augment each of its
--  effects via activeEffects:modify, scaled by honourScale.
--
--  The core problem with applying immediately in onActivate is
--  timing: onActivate fires BEFORE the engine processes the
--  potion, so the effects are not yet active. We solve this
--  by scheduling the bonus application 0.1 simulation seconds
--  later via async:newUnsavableSimulationTimer, by which point
--  the engine has consumed the potion and the effects are live.
--
--  Because activeEffects:modify is permanent until reversed,
--  we also schedule a cleanup callback at duration - 0.1s to
--  remove the bonus once the potion naturally expires.
--
--  The timers are unsaveable — if the player saves and loads
--  mid-potion the bonus disappears, which is an acceptable
--  edge case given the complexity of tracking this across saves.
--
--  At rep cap:  +150% extra magnitude (total 250% of base)
--  Post-cap:    continues at 30% of pre-cap rate (honourScale)
-- ============================================================

local hasWitOfTelvanni = false
local telvMsgShown     = false

-- ============================================================
--  Effect classification tables.
--  Fortify Attribute/Skill: engine writes the stat once at
--    application time and ignores the active effect magnitude
--    thereafter. We must write directly to the stat modifier
--    and reverse it ourselves on cleanup.
--  Restore Health/Magicka/Fatigue: restoration rate is cached
--    at application time. We apply the total bonus (bonus *
--    duration) as an instant lump-sum to the dynamic stat
--    current value. No cleanup needed — it's a one-time add.
--  Everything else (Night-Eye, Chameleon, etc.): engine reads
--    the active effect magnitude every frame, so
--    activeEffects:modify works correctly here.
-- ============================================================

local FORTIFY_ATTR = { ["fortifyattribute"] = true }
local FORTIFY_SKILL = { ["fortifyskill"] = true }
local RESTORE_DYN = {
    ["restorehealth"]  = "health",
    ["restoremagicka"] = "magicka",
    ["restorefatigue"] = "fatigue",
}

local function applyFortifyAttr(attrId, bonus)
    local stat = types.Actor.stats.attributes[attrId]
    if stat then stat(self).modifier = stat(self).modifier + bonus end
end

local function applyFortifySkill(skillId, bonus)
    local stat = types.NPC.stats.skills[skillId]
    if stat then stat(self).modifier = stat(self).modifier + bonus end
end

local function applyRestoreDyn(dynKey, bonus, duration)
    -- Apply total bonus as instant lump sum: bonus magnitude * duration
    local total = bonus * duration
    if total <= 0 then return end
    local dyn = types.Actor.stats.dynamic[dynKey]
    if dyn then
        local s = dyn(self)
        s.current = math.min(s.current + total, s.base + s.modifier)
    end
end

local function TelvanniWit(object)
    if not hasWitOfTelvanni then return end
    local isPotion     = types.Potion.objectIsInstance(object)
    local isIngredient = types.Ingredient.objectIsInstance(object)
    if not isPotion and not isIngredient then return end

    local scale = utils.honourScale('telvanni') * 1.5
    if scale <= 0 then return end

    local record = (isPotion and types.Potion.record(object))
               or  (isIngredient and types.Ingredient.record(object))
    if not record or not record.effects then return end

    -- Build bonus list before timer fires — record may be gone by then
    local bonuses = {}
    for _, effectParams in ipairs(record.effects) do
        local baseMag = (effectParams.magnitudeMin + effectParams.magnitudeMax) / 2
        local bonus   = math.floor(baseMag * scale)
        if bonus > 0 then
            bonuses[#bonuses + 1] = {
                id         = effectParams.id,
                extraParam = effectParams.affectedAttribute
                          or effectParams.affectedSkill
                          or nil,
                bonus      = bonus,
                duration   = effectParams.duration,
            }
        end
    end

    if #bonuses == 0 then return end
    local timer = 0.1

    -- Apply after engine has processed the potion (0.1s delay)
    async:newUnsavableSimulationTimer(timer, function()
        local activeEffects = types.Actor.activeEffects(self)

        for _, b in ipairs(bonuses) do
            local dynKey = RESTORE_DYN[b.id]

            if FORTIFY_ATTR[b.id] and b.extraParam then
                -- Write directly to attribute modifier; cleanup reverses it
                applyFortifyAttr(b.extraParam, b.bonus)
                async:newUnsavableSimulationTimer(b.duration - timer, function()
                    applyFortifyAttr(b.extraParam, -b.bonus)
                end)

            elseif FORTIFY_SKILL[b.id] and b.extraParam then
                -- Write directly to skill modifier; cleanup reverses it
                applyFortifySkill(b.extraParam, b.bonus)
                async:newUnsavableSimulationTimer(b.duration - timer, function()
                    applyFortifySkill(b.extraParam, -b.bonus)
                end)

            elseif dynKey then
                -- Restoration: apply total bonus as instant lump sum
                applyRestoreDyn(dynKey, b.bonus, b.duration)

            else
                -- Night-Eye, Chameleon, etc.: activeEffects:modify works
                if b.extraParam then
                    activeEffects:modify(b.bonus, b.id, b.extraParam)
                else
                    activeEffects:modify(b.bonus, b.id)
                end
                async:newUnsavableSimulationTimer(b.duration - timer, function()
                    if b.extraParam then
                        activeEffects:modify(-b.bonus, b.id, b.extraParam)
                    else
                        activeEffects:modify(-b.bonus, b.id)
                    end
                end)
            end
        end
    ui.showMessage("You Honour the Wit of House Telvanni.")
    end)
end

local ht1_id = ns .. "_ht_uninvited_student"
interfaces.ErnPerkFramework.registerPerk({
    id = ht1_id,
    localizedName = "Uninvited Student",
    localizedDescription = "House Telvanni does not recruit - it tolerates those strong enough "
        .. "to push their way in. You have done so. For now, that is enough.\n "
        .. "(+5 Intelligence, +10 Enchant, +10 Alchemy, +10 Spell Absorption, "
        .. "grants Strong Levitate)\n\n"
        .. "Honour the Wit of the Great House Telvanni: Scaling alchemical magnitude with Telvanni Reputation\n"
        .. "Scaled Restoration effects are applied instantly",
    art = "textures\\levelup\\mage", cost = 1,
    requirements = {
        R().minimumFactionRank('telvanni', 0),
        R().minimumLevel(1),
    },
    onAdd = function()
        setRank(1)
        types.Actor.spells(self):add("strong levitate")
        hasWitOfTelvanni = true
    end,
    onRemove = function()
        setRank(nil)
        types.Actor.spells(self):remove("strong levitate")
        hasWitOfTelvanni = false
    end,
})

local ht2_id = ns .. "_ht_tower_sorcery"
interfaces.ErnPerkFramework.registerPerk({
    id = ht2_id,
    localizedName = "Tower Sorcery",
    localizedDescription = "Telvanni wizards are defined by their mastery of enchantment. "
        .. "You have begun to understand the principles that animate their towers and servants.\n "
        .. "Requires Uninvited Student. "
        .. "(+15 Intelligence, +25 Enchant, +25 Alchemy, +25 Spell Absorption, "
        .. "grants Mark and Recall)",
    art = "textures\\levelup\\mage", cost = 2,
    requirements = {
        R().hasPerk(ht1_id),
        R().minimumFactionRank('telvanni', 3),
        R().minimumAttributeLevel('intelligence', 40),
        R().minimumLevel(5),
    },
    onAdd = function()
        setRank(2)
        types.Actor.spells(self):add("mark")
        types.Actor.spells(self):add("recall")
    end,
    onRemove = function()
        setRank(nil)
        types.Actor.spells(self):remove("mark")
        types.Actor.spells(self):remove("recall")
    end,
})

local ht3_id = ns .. "_ht_self_made_power"
interfaces.ErnPerkFramework.registerPerk({
    id = ht3_id,
    localizedName = "Self-Made Power",
    localizedDescription = "House Telvanni respects only power earned, never granted. "
        .. "You have shaped yourself through relentless study.\n "
        .. "Requires Tower Sorcery. "
        .. "(+25 Intelligence, +50 Enchant, +50 Alchemy, +50 Spell Absorption, "
        .. "Fortify Maximum Magicka 0.5x Intelligence, Restore Magicka 1pt/s)",
    art = "textures\\levelup\\mage", cost = 3,
    requirements = {
        R().hasPerk(ht2_id),
        R().minimumFactionRank('telvanni', 6),
        R().minimumAttributeLevel('intelligence', 50),
        R().minimumLevel(10),
    },
    onAdd = function()
        setRank(3)
        types.Actor.spells(self):add("FPerks_HT3_Restore_Magicka_1")
    end,
    onRemove = function()
        setRank(nil)
        types.Actor.spells(self):remove("FPerks_HT3_Restore_Magicka_1")
    end,
})

local ht4_id = ns .. "_ht_telvanni_lord"
interfaces.ErnPerkFramework.registerPerk({
    id = ht4_id,
    localizedName = "Telvanni Lord",
    localizedDescription = "You are acknowledged by the Telvanni masters - a rare concession "
        .. "from those who acknowledge no one. The heights are yours to claim.\n "
        .. "Requires Self-Made Power. "
        .. "(+25 Willpower, +75 Enchant, +75 Alchemy, +75 Spell Absorption, "
        .. "Fortify Maximum Magicka 1.0x Intelligence, "
        .. "additional Restore Magicka 2pt/s)",
    art = "textures\\levelup\\mage", cost = 4,
    requirements = {
        R().hasPerk(ht3_id),
        R().minimumFactionRank('telvanni', 9),
        R().minimumAttributeLevel('intelligence', 75),
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
        onConsume = TelvanniWit,
    },
}
