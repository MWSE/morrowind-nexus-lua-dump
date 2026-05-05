--[[
    HT:
        FPerks_HT1_Passive          - +3 Intelligence, +3 Willpower,
                                      +5 Enchant, +5 Conjuration
        FPerks_HT2_Passive          - +5 Intelligence, +5 Willpower,
                                      +10 Enchant, +10 Conjuration
        FPerks_HT3_Passive          - +10 Intelligence, +10 Willpower,
                                      +18 Enchant, +18 Conjuration,
                                      Fortify Maximum Magicka 0.5x Intelligence (magnitude 5),
                                      Restore Magicka 1pt/s
        FPerks_HT4_Passive          - +15 Intelligence, +15 Willpower,
                                      +25 Enchant, +25 Conjuration,
                                      Fortify Maximum Magicka 1.0x Intelligence (magnitude 10),
                                      Restore Magicka 2pt/s

    Non-table spells (granted once, not removed on rank-up):
        "bound helm"                Vanilla spell (P1)
        "bound cuirass"             Vanilla spell (P1)
        "tranasa's spelltrap"       Vanilla spell (P2)

    Honour The Great House (P1+): Wit of the Telvanni

        CAST ON USE:
        Self-range non-harmful effects are augmented immediately.
        Cleanup uses activeSpells polling (durationLeft) rather than
        async timers so bonuses survive saves and loads correctly.
        The tracking table is persisted via onSave/onLoad.
        On load, the table is restored but bonuses are NOT re-applied
        (they are already in stat.modifier from the save file).

        CONSTANT EFFECT:
        Non-harmful effects on equipped CE items are augmented via
        stat.modifier (Fortify Health/Magicka/Fatigue and Fortify
        Attribute/Skill) or activeEffects:modify (everything else).
        Harmful effects are skipped entirely.
        The CE boost table is persisted via onSave/onLoad to prevent
        load stacking.

        All character-specific data is in onSave/onLoad.
        
]]

local ns          = require("scripts.FactionPerks.namespace")
local utils       = require("scripts.FactionPerks.utils")
local perkHidden  = utils.perkHidden
local safeAddSpell  = utils.safeAddSpell
local safeRemoveSpell = utils.safeRemoveSpell
local GUILD        = utils.FACTION_GROUPS.telvanni
local interfaces  = require("openmw.interfaces")
local types       = require('openmw.types')
local self        = require('openmw.self')
local ui          = require('openmw.ui')
local core        = require('openmw.core')

local R = interfaces.ErnPerkFramework.requirements

local perkTable = {
    [1] = { passive = {"FPerks_HT1_Passive"} },
    [2] = { passive = {"FPerks_HT2_Passive"} },
    [3] = { passive = {"FPerks_HT3_Passive"} },
    [4] = { passive = {"FPerks_HT4_Passive"} },
}

local setRank = utils.makeSetRank(perkTable, nil)

-- ============================================================
--  WIT OF THE TELVANNI - shared state
-- ============================================================

local hasWitOfTelvanni   = false
local currentEnchantedItem = nil

-- ============================================================
--  CHARACTER-SPECIFIC STATE (persisted via onSave/onLoad)
--
--  activeCastOnUseBonuses: keyed by item.recordId
--    Each entry: { bonuses = { {id, extraParam, bonus, path, dynKey} } }
--    Restored on load for expiry tracking only - bonuses are NOT
--    re-applied as they are already in stat.modifier from the save.
--
--  activeConstantBoosts: keyed by equipment slot number
--    Each entry: { itemId, bonuses = { {id, extraParam, bonus, path, dynKey} } }
--    Restored on load for slot-change detection only - same reasoning.
-- ============================================================

local activeCastOnUseBonuses = {}
local activeConstantBoosts   = {}
local castOnUsePollTimer     = 0
local CAST_ON_USE_POLL_INTERVAL = 0.5
local equipmentCheckTimer    = 0
local EQUIPMENT_CHECK_INTERVAL = 2.0
local lastHTCellId           = nil

-- ============================================================
--  EFFECT CLASSIFICATION TABLES
-- ============================================================

local FORTIFY_ATTR  = { ["fortifyattribute"] = true }
local FORTIFY_SKILL = { ["fortifyskill"]     = true }
local FORTIFY_DYN   = {
    ["fortifyhealth"]  = "health",
    ["fortifymagicka"] = "magicka",
    ["fortifyfatigue"] = "fatigue",
}
local RESTORE_DYN   = {
    ["restorehealth"]  = "health",
    ["restoremagicka"] = "magicka",
    ["restorefatigue"] = "fatigue",
}

-- ============================================================
--  STAT HELPER FUNCTIONS
-- ============================================================

local function applyFortifyAttr(attrId, bonus)
    local stat = types.Actor.stats.attributes[attrId]
    if stat then stat(self).modifier = stat(self).modifier + bonus end
end

local function applyFortifySkill(skillId, bonus)
    local stat = types.NPC.stats.skills[skillId]
    if stat then stat(self).modifier = stat(self).modifier + bonus end
end

local function applyFortifyDyn(dynKey, bonus)
    local dyn = types.Actor.stats.dynamic[dynKey]
    if dyn then
        local s = dyn(self)
        s.modifier = s.modifier + bonus
        if bonus > 0 then
            s.current = s.current + bonus
        end
    end
end

local function applyRestoreDyn(dynKey, bonus, duration)
    local total = bonus * duration
    if total <= 0 then return end
    local dyn = types.Actor.stats.dynamic[dynKey]
    if dyn then
        local s = dyn(self)
        s.current = math.min(s.current + total, s.base + s.modifier)
    end
end

-- ============================================================
--  SHARED ENCHANTMENT RECORD READER
-- ============================================================

local ENCHANTABLE_TYPES = {
    types.Weapon, types.Armor, types.Clothing,
    types.Miscellaneous, types.Book,
}

local function getEnchantmentRecord(item)
    if not item or not item:isValid() then return nil end
    for _, t in ipairs(ENCHANTABLE_TYPES) do
        if t.objectIsInstance(item) then
            local r = t.record(item)
            if r and r.enchant and r.enchant ~= "" then
                return core.magic.enchantments.records[r.enchant]
            end
            break
        end
    end
    return nil
end

local function isHarmful(effectId)
    local rec = core.magic.effects.records[effectId]
    return rec and rec.harmful == true
end

-- ============================================================
--  CAST ON USE - bonus application
-- ============================================================

local function reverseCastOnUseEntry(itemRecordId, entry)
    local activeEffects = types.Actor.activeEffects(self)
    for _, b in ipairs(entry.bonuses) do
        if b.path == "fortifyAttr" then
            applyFortifyAttr(b.extraParam, -b.bonus)
        elseif b.path == "fortifySkill" then
            applyFortifySkill(b.extraParam, -b.bonus)
        elseif b.path == "fortifyDyn" then
            applyFortifyDyn(b.dynKey, -b.bonus)
        else
            if b.extraParam then
                activeEffects:modify(-b.bonus, b.id, b.extraParam)
            else
                activeEffects:modify(-b.bonus, b.id)
            end
        end
    end
    activeCastOnUseBonuses[itemRecordId] = nil
    print("HT Wit: Reversed CastOnUse bonus for " .. tostring(itemRecordId))
end

local function isCastOnUseStillActive(itemRecordId)
    for _, spell in pairs(types.Actor.activeSpells(self)) do
        if spell.id == itemRecordId then
            for _, effect in pairs(spell.effects) do
                if effect.durationLeft and effect.durationLeft > 0 then
                    return true
                end
            end
        end
    end
    return false
end

local function pollCastOnUseBonuses()
    for itemRecordId, entry in pairs(activeCastOnUseBonuses) do
        if not isCastOnUseStillActive(itemRecordId) then
            reverseCastOnUseEntry(itemRecordId, entry)
        end
    end
end



local function TelvanniWitEnchant(item)
    if not hasWitOfTelvanni then return end
    if not item or not item:isValid() then return end

    local enchRecord = getEnchantmentRecord(item)
    if not enchRecord then return end
    if enchRecord.type ~= core.magic.ENCHANTMENT_TYPE.CastOnUse then return end
    if not enchRecord.effects then return end

    local scale = utils.honourScale('telvanni') * 1.5
    if scale <= 0 then return end

    if activeCastOnUseBonuses[item.recordId] then
        reverseCastOnUseEntry(item.recordId, activeCastOnUseBonuses[item.recordId])
    end


    local bonuses       = {}
    local activeEffects = types.Actor.activeEffects(self)

    for _, effectParams in ipairs(enchRecord.effects) do
        if not isHarmful(effectParams.id) then
            if effectParams.range == core.magic.RANGE.Self then
                local baseMag = (effectParams.magnitudeMin + effectParams.magnitudeMax) / 2
                local bonus   = math.floor(baseMag * scale)
                if bonus > 0 then
                    local dynKey   = FORTIFY_DYN[effectParams.id]
                    local restKey  = RESTORE_DYN[effectParams.id]
                    local extraParam = effectParams.affectedAttribute
                                    or effectParams.affectedSkill
                                    or nil

                    if FORTIFY_ATTR[effectParams.id] and extraParam then
                        applyFortifyAttr(extraParam, bonus)
                        bonuses[#bonuses + 1] = {
                            id = effectParams.id, extraParam = extraParam,
                            bonus = bonus, path = "fortifyAttr",
                        }
                    elseif FORTIFY_SKILL[effectParams.id] and extraParam then
                        applyFortifySkill(extraParam, bonus)
                        bonuses[#bonuses + 1] = {
                            id = effectParams.id, extraParam = extraParam,
                            bonus = bonus, path = "fortifySkill",
                        }
                    elseif dynKey then
                        applyFortifyDyn(dynKey, bonus)
                        bonuses[#bonuses + 1] = {
                            id = effectParams.id, dynKey = dynKey,
                            bonus = bonus, path = "fortifyDyn",
                        }
                    elseif restKey then
                        applyRestoreDyn(restKey, bonus, effectParams.duration)
                        -- Instant lump sum - not tracked, no cleanup needed
                    else
                        if extraParam then
                            activeEffects:modify(bonus, effectParams.id, extraParam)
                        else
                            activeEffects:modify(bonus, effectParams.id)
                        end
                        bonuses[#bonuses + 1] = {
                            id = effectParams.id, extraParam = extraParam,
                            bonus = bonus, path = "modify",
                        }
                    end
                end
            end
        end
    end

    if #bonuses == 0 then return end

    activeCastOnUseBonuses[item.recordId] = { bonuses = bonuses }
    ui.showMessage("You Honour the Wit of House Telvanni.")
    print("HT Wit: Applied CastOnUse bonus for " .. tostring(item.recordId))
end

-- ============================================================
--  ENCHANT SKILL HANDLER
-- ============================================================

interfaces.SkillProgression.addSkillUsedHandler(function(skillId, params)
    if skillId ~= "enchant"  then return end
    if not hasWitOfTelvanni  then return end
    local item = types.Actor.getSelectedEnchantedItem(self)
    if not item then return end
    TelvanniWitEnchant(item)
end)

-- ============================================================
--  CONSTANT EFFECT
-- ============================================================

local EQUIPMENT_SLOTS = {
    types.Actor.EQUIPMENT_SLOT.Helmet,
    types.Actor.EQUIPMENT_SLOT.Cuirass,
    types.Actor.EQUIPMENT_SLOT.Greaves,
    types.Actor.EQUIPMENT_SLOT.LeftPauldron,
    types.Actor.EQUIPMENT_SLOT.RightPauldron,
    types.Actor.EQUIPMENT_SLOT.LeftGauntlet,
    types.Actor.EQUIPMENT_SLOT.RightGauntlet,
    types.Actor.EQUIPMENT_SLOT.Boots,
    types.Actor.EQUIPMENT_SLOT.Shirt,
    types.Actor.EQUIPMENT_SLOT.Pants,
    types.Actor.EQUIPMENT_SLOT.Skirt,
    types.Actor.EQUIPMENT_SLOT.Robe,
    types.Actor.EQUIPMENT_SLOT.LeftRing,
    types.Actor.EQUIPMENT_SLOT.RightRing,
    types.Actor.EQUIPMENT_SLOT.Amulet,
    types.Actor.EQUIPMENT_SLOT.Belt,
    types.Actor.EQUIPMENT_SLOT.CarriedRight,
    types.Actor.EQUIPMENT_SLOT.CarriedLeft,
}

local function reverseConstantBoost(boost)
    local activeEffects = types.Actor.activeEffects(self)
    for _, b in ipairs(boost.bonuses) do
        if b.path == "fortifyAttr" then
            applyFortifyAttr(b.extraParam, -b.bonus)
        elseif b.path == "fortifySkill" then
            applyFortifySkill(b.extraParam, -b.bonus)
        elseif b.path == "fortifyDyn" then
            applyFortifyDyn(b.dynKey, -b.bonus)
        else
            if b.extraParam then
                activeEffects:modify(-b.bonus, b.id, b.extraParam)
            else
                activeEffects:modify(-b.bonus, b.id)
            end
        end
    end
    print("HT Wit: Reversed CE boost for item " .. tostring(boost.itemId))
end

local function applyConstantBoost(slot, item, enchRecord)
    local scale = math.min(utils.honourScale('telvanni'), 1.0)
    if scale <= 0 then return end

    local bonuses       = {}
    local activeEffects = types.Actor.activeEffects(self)

    for _, effectParams in ipairs(enchRecord.effects) do
        if not isHarmful(effectParams.id) then
            local baseMag    = (effectParams.magnitudeMin + effectParams.magnitudeMax) / 2
            local bonus      = math.floor(baseMag * scale)
            if bonus > 0 then
                local extraParam = effectParams.affectedAttribute
                               or effectParams.affectedSkill
                               or nil
                local dynKey = FORTIFY_DYN[effectParams.id]

                if FORTIFY_ATTR[effectParams.id] and extraParam then
                    applyFortifyAttr(extraParam, bonus)
                    bonuses[#bonuses + 1] = {
                        id = effectParams.id, extraParam = extraParam,
                        bonus = bonus, path = "fortifyAttr",
                    }
                elseif FORTIFY_SKILL[effectParams.id] and extraParam then
                    applyFortifySkill(extraParam, bonus)
                    bonuses[#bonuses + 1] = {
                        id = effectParams.id, extraParam = extraParam,
                        bonus = bonus, path = "fortifySkill",
                    }
                elseif dynKey then
                    applyFortifyDyn(dynKey, bonus)
                    bonuses[#bonuses + 1] = {
                        id = effectParams.id, dynKey = dynKey,
                        bonus = bonus, path = "fortifyDyn",
                    }
                else
                    if extraParam then
                        activeEffects:modify(bonus, effectParams.id, extraParam)
                    else
                        activeEffects:modify(bonus, effectParams.id)
                    end
                    bonuses[#bonuses + 1] = {
                        id = effectParams.id, extraParam = extraParam,
                        bonus = bonus, path = "modify",
                    }
                end
            end
        end
    end

    if #bonuses > 0 then
        activeConstantBoosts[slot] = { itemId = item.id, bonuses = bonuses }
        print("HT Wit: Applied CE boost for slot " .. tostring(slot))
    end
end

local function removeAllConstantBoosts()
    for slot, boost in pairs(activeConstantBoosts) do
        reverseConstantBoost(boost)
    end
    activeConstantBoosts = {}
end

local function updateConstantEffects()
    if not hasWitOfTelvanni then return end

    for _, slot in ipairs(EQUIPMENT_SLOTS) do
        local item    = types.Actor.getEquipment(self, slot)
        local current = activeConstantBoosts[slot]

        local currentItemId = (item and item:isValid()) and item.id or nil
        local boostedItemId = current and current.itemId or nil

        if currentItemId ~= boostedItemId then
            if current then
                reverseConstantBoost(current)
                activeConstantBoosts[slot] = nil
            end
            if item and item:isValid() then
                local enchRecord = getEnchantmentRecord(item)
                if enchRecord and
                   enchRecord.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
                    applyConstantBoost(slot, item, enchRecord)
                end
            end
        end
    end
end

-- ============================================================
--  HOUSE TELVANNI PERKS
-- ============================================================

local ht1_id = ns .. "_ht_uninvited_student"
interfaces.ErnPerkFramework.registerPerk({
    id = ht1_id,
    localizedName = "Uninvited Student",
    localizedDescription = "House Telvanni does not recruit - it tolerates those strong "
        .. "enough to push their way in. You have done so. For now, that is enough.\
 "
        .. "(+3 Intelligence, +3 Willpower, +5 Enchant, +5 Conjuration, "
        .. "grants Bound Helm and Bound Cuirass)\
\
"
        .. "Honour the Wit of the Great House Telvanni: Cast on Use enchantments "
        .. "that target yourself are augmented based on your Telvanni reputation. "
        .. "At reputation cap: effects are 250%% of their base magnitude.\
"
        .. "Constant Effect enchantments on equipped items are permanently "
        .. "augmented. Harmful effects are never boosted. "
        .. "At reputation cap: effects are 200%% of their base magnitude.",
    hidden = perkHidden(GUILD, 0, 1),
    art = "textures\\levelup\\mage", cost = 1,
    requirements = {
        R().minimumFactionRank('telvanni', 0),
        R().minimumLevel(1),
    },
    onAdd = function()
        setRank(1)
        safeAddSpell("bound helm")
        safeAddSpell("bound cuirass")
        hasWitOfTelvanni = true
        -- Tables restored from save by onLoad - just run CE detection
        updateConstantEffects()
    end,
    onRemove = function()
        setRank(nil)
        safeRemoveSpell("bound helm")
        safeRemoveSpell("bound cuirass")
        hasWitOfTelvanni     = false
        currentEnchantedItem = nil
        lastHTCellId         = nil
        for itemRecordId, entry in pairs(activeCastOnUseBonuses) do
            reverseCastOnUseEntry(itemRecordId, entry)
        end
        removeAllConstantBoosts()
    end,
})

local ht2_id = ns .. "_ht_tower_sorcery"
interfaces.ErnPerkFramework.registerPerk({
    id = ht2_id,
    localizedName = "Tower Sorcery",
    localizedDescription = "Telvanni wizards are defined by their mastery of enchantment. "
        .. "You have begun to understand the principles that animate their towers "
        .. "and servants.\
 "
        .. "Requires Uninvited Student. "
        .. "(+5 Intelligence, +5 Willpower, +10 Enchant, +10 Conjuration, "
        .. "grants Tranasa's Spelltrap)",
    hidden = perkHidden(GUILD, 3, 5),
    art = "textures\\levelup\\mage", cost = 2,
    requirements = {
        R().hasPerk(ht1_id),
        R().minimumFactionRank('telvanni', 3),
        R().minimumAttributeLevel('intelligence', 40),
        R().minimumLevel(5),
    },
    onAdd = function()
        setRank(2)
        safeAddSpell("tranasa's spelltrap")
    end,
    onRemove = function()
        setRank(nil)
        safeRemoveSpell("tranasa's spelltrap")
    end,
})

local ht3_id = ns .. "_ht_self_made_power"
interfaces.ErnPerkFramework.registerPerk({
    id = ht3_id,
    localizedName = "Self-Made Power",
    localizedDescription = "House Telvanni respects only power earned, never granted. "
        .. "You have shaped yourself through relentless study.\
 "
        .. "Requires Tower Sorcery. "
        .. "(+10 Intelligence, +10 Willpower, +18 Enchant, +18 Conjuration, "
        .. "Fortify Maximum Magicka 0.5x Intelligence, Restore Magicka 1pt/s)",
    hidden = perkHidden(GUILD, 6, 10),
    art = "textures\\levelup\\mage", cost = 3,
    requirements = {
        R().hasPerk(ht2_id),
        R().minimumFactionRank('telvanni', 6),
        R().minimumAttributeLevel('intelligence', 50),
        R().minimumLevel(10),
    },
    onAdd = function()
        setRank(3)
    end,
    onRemove = function()
        setRank(nil)
    end,
})

local ht4_id = ns .. "_ht_telvanni_lord"
interfaces.ErnPerkFramework.registerPerk({
    id = ht4_id,
    localizedName = "Telvanni Lord",
    localizedDescription = "You are acknowledged by the Telvanni masters - a rare "
        .. "concession from those who acknowledge no one. The heights are yours "
        .. "to claim.\
 "
        .. "Requires Self-Made Power. "
        .. "(+15 Intelligence, +15 Willpower, +25 Enchant, +25 Conjuration, "
        .. "Fortify Maximum Magicka 1.0x Intelligence, "
        .. "additional Restore Magicka 2pt/s)",
    hidden = perkHidden(GUILD, 9, 15),
    art = "textures\\levelup\\mage", cost = 4,
    requirements = {
        R().hasPerk(ht3_id),
        R().minimumFactionRank('telvanni', 9),
        R().minimumAttributeLevel('intelligence', 75),
        R().minimumLevel(15),
    },
    onAdd    = function() setRank(4) end,
    onRemove = function() setRank(nil) end,
})

-- ============================================================
--  ENGINE CALLBACKS
-- ============================================================

local function onUpdate(dt)
    if not hasWitOfTelvanni then return end

    -- Poll CastOnUse bonuses for expiry via durationLeft
    castOnUsePollTimer = castOnUsePollTimer - dt
    if castOnUsePollTimer <= 0 then
        castOnUsePollTimer = CAST_ON_USE_POLL_INTERVAL
        pollCastOnUseBonuses()
    end

    -- Cell change: recalculate CE scale
    local cell   = self.cell
    local cellId = cell and cell.id or nil
    if cellId ~= lastHTCellId then
        lastHTCellId = cellId
        removeAllConstantBoosts()
        updateConstantEffects()
    end

    -- Periodic equipment change check
    equipmentCheckTimer = equipmentCheckTimer - dt
    if equipmentCheckTimer <= 0 then
        equipmentCheckTimer = EQUIPMENT_CHECK_INTERVAL
        updateConstantEffects()
    end
end

local function onSave()
    return {
        activeCastOnUseBonuses = activeCastOnUseBonuses,
        activeConstantBoosts   = activeConstantBoosts,
    }
end

local function onLoad(data)
    data = data or {}
    -- Restore tracking tables only - bonuses already baked into
    -- stat.modifier from the save file, so nothing is re-applied.
    activeCastOnUseBonuses = data.activeCastOnUseBonuses or {}
    activeConstantBoosts   = data.activeConstantBoosts   or {}
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave   = onSave,
        onLoad   = onLoad,
    },
}
