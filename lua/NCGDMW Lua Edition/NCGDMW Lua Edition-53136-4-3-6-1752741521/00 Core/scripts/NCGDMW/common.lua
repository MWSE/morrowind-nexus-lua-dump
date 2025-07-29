local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')
local T = require('openmw.types')
local storage = require('openmw.storage')

local log = require('scripts.NCGDMW.log')
local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mS = require('scripts.NCGDMW.settings')
local mH = require('scripts.NCGDMW.helpers')

local L = core.l10n(mDef.MOD_NAME)

local module = {
    trace = false
}

local currentSerializedBaseStatsMods
local modStatMessageStack = {}

module.self = {
    health = T.Actor.stats.dynamic.health(self),
    magicka = T.Actor.stats.dynamic.magicka(self),
    fatigue = T.Actor.stats.dynamic.fatigue(self),
    level = T.Actor.stats.level(self),
}

module.agilityTerm = function(skillId, actor)
    actor = actor or self
    return (skillId and T.NPC.stats.skills[skillId](actor).base or 0)
            + 0.2 * T.Actor.stats.attributes.agility(actor).base
            + 0.1 * T.Actor.stats.attributes.luck(actor).base
end

local GMSTs = {
    iLevelupTotal = core.getGMST("iLevelupTotal"),
    fFatigueBase = core.getGMST("fFatigueBase"),
    fFatigueMult = core.getGMST("fFatigueMult"),
    fPickLockMult = core.getGMST("fPickLockMult"),
    fTrapCostMult = core.getGMST("fTrapCostMult"),
    fAutoPCSpellChance = core.getGMST("fAutoPCSpellChance"),
    fEffectCostMult = core.getGMST("fEffectCostMult"),
    iAutoSpellAttSkillMin = core.getGMST("iAutoSpellAttSkillMin"),
    iAutoPCSpellMax = core.getGMST("iAutoPCSpellMax"),
    fPCbaseMagickaMult = core.getGMST("fPCbaseMagickaMult"),
    fJumpEncumbranceBase = core.getGMST("fJumpEncumbranceBase"),
    fJumpEncumbranceMultiplier = core.getGMST("fJumpEncumbranceMultiplier"),
    fJumpAcrobaticsBase = core.getGMST("fJumpAcrobaticsBase"),
    fJumpAcroMultiplier = core.getGMST("fJumpAcroMultiplier"),
    fJumpRunMultiplier = core.getGMST("fJumpRunMultiplier"),
    fFallAcroBase = core.getGMST("fFallAcroBase"),
    fFallAcroMult = core.getGMST("fFallAcroMult"),
    fFallDamageDistanceMin = core.getGMST("fFallDamageDistanceMin"),
    fFallDistanceBase = core.getGMST("fFallDistanceBase"),
    fFallDistanceMult = core.getGMST("fFallDistanceMult"),
    fJumpMoveBase = core.getGMST("fJumpMoveBase"),
    fJumpMoveMult = core.getGMST("fJumpMoveMult"),
    fSwimRunAthleticsMult = core.getGMST("fSwimRunAthleticsMult"),
    fSwimRunBase = core.getGMST("fSwimRunBase"),
}
module.GMSTs = GMSTs

module.skillIdToSchool = {}
for type, skills in pairs(mDef.skillsBySchool) do
    for _, skillId in ipairs(skills) do
        module.skillIdToSchool[skillId] = type
    end
end

local function showMessage(state, ...)
    local arg = { ... }
    ui.showMessage(table.concat(arg, "\n"), { showInDialogue = false })
    for _, message in ipairs(arg) do
        log(message)
        table.insert(state.messagesLog, 1, { message = message, time = os.date("%H:%M:%S") })
        if #state.messagesLog > 12 then
            table.remove(state.messagesLog)
        end
    end
end
module.showMessage = showMessage

local function isStarwindMode()
    return core.contentFiles.has('Starwind.omwaddon') or core.contentFiles.has('StarwindRemasteredPatch.esm')
end
module.isStarwindMode = isStarwindMode

local function totalGameTimeInHours()
    return core.getGameTime() / (60 * 60)
end
module.totalGameTimeInHours = totalGameTimeInHours

local function getTotalPlayerLevel(state)
    local levelGain = 1 / module.GMSTs.iLevelupTotal
    local totalLevel = 1
    for _, value in pairs(state.skills.growth.level) do
        totalLevel = totalLevel + value * levelGain
    end
    return totalLevel
end
module.getTotalPlayerLevel = getTotalPlayerLevel

local function getBaseStatsModifiers()
    local baseStatsMods = { attributes = {}, skills = {} }
    for _, spell in pairs(T.Player.activeSpells(self)) do
        if spell.affectsBaseValues then
            for _, effect in pairs(spell.effects) do
                local kind, statId
                if effect.affectedAttribute ~= nil and effect.id == core.magic.EFFECT_TYPE.FortifyAttribute then
                    kind = "attributes"
                    statId = effect.affectedAttribute
                elseif effect.affectedSkill ~= nil and effect.id == core.magic.EFFECT_TYPE.FortifySkill then
                    kind = "skills"
                    statId = effect.affectedSkill
                end
                if kind ~= nil then
                    baseStatsMods[kind][statId] = (baseStatsMods[kind][statId] or 0) + effect.magnitudeThisFrame
                end
            end
        end
    end
    if next(baseStatsMods.attributes) or next(baseStatsMods.skills) then
        local serializedBaseStatsMods = mH.tableOfTablesToString(baseStatsMods)
        if serializedBaseStatsMods ~= currentSerializedBaseStatsMods then
            currentSerializedBaseStatsMods = serializedBaseStatsMods
            log(string.format("Detected base statistics modifiers: %s", serializedBaseStatsMods))
        end
    end
    return baseStatsMods
end
module.getBaseStatsModifiers = getBaseStatsModifiers

local function getHealthFactor(state)
    local baseHPRatio = mS.healthStorage:get("baseHPRatio")
    local factor = baseHPRatio ~= "full" and mS.getBaseHPRatioFactor(baseHPRatio) or 1
    local attrFactor = 0
    for attrId, value in pairs(mCfg.healthAttributeFactors) do
        attrFactor = attrFactor + state.healthAttrs[attrId] * value
    end
    return factor * attrFactor
end
module.getHealthFactor = getHealthFactor

local function getMaxHealthModifier()
    local healthMod = 0
    for _, spell in pairs(T.Player.activeSpells(self)) do
        if spell.affectsBaseValues then
            for _, effect in pairs(spell.effects) do
                if effect.id == core.magic.EFFECT_TYPE.FortifyHealth then
                    healthMod = healthMod + effect.magnitudeThisFrame
                end
            end
        end
    end
    if healthMod ~= 0 then
        log(string.format("Detected max health modifier: %d", healthMod))
    end
    return healthMod
end
module.getMaxHealthModifier = getMaxHealthModifier

local function getAttributeGrowth(state, attrId, growthRateNum)
    local value = 0
    for skillId, attributes in pairs(mCfg.skillsImpactOnAttributes) do
        local impactFactor = attributes[attrId]
        if impactFactor then
            value = value
                    + (mCfg.attributeGrowthFactor * (1 + growthRateNum * mCfg.attributeGrowthFactorIncrease))
                    * state.skills.growth.attributes[skillId]
                    * impactFactor / mCfg.skillsImpactSums[skillId]
        end
    end
    return value
end
module.getAttributeGrowth = getAttributeGrowth

local function getAttributeDiff(state, attrId, baseStatsMods)
    -- Try to see if something else has modified an attribute and preserve that difference.
    local diff = state.attrs.diffs[attrId]
            + T.Actor.stats.attributes[attrId](self).base
            - (baseStatsMods.attributes[attrId] or 0)
            - state.attrs.base[attrId]
    if diff ~= state.attrs.diffs[attrId] then
        log(string.format("Detected external change %d for \"%s\", base is %d, stored base is %d",
                diff, attrId, T.Actor.stats.attributes[attrId](self).base, state.attrs.base[attrId]))
    end
    state.attrs.diffs[attrId] = diff
    return diff
end
module.getAttributeDiff = getAttributeDiff

local function setChargenStats(state)
    local playerRecord = T.Player.record(self)
    local playerClass = T.Player.classes.record(playerRecord.class)
    local playerRace = T.Player.races.record(playerRecord.race)
    local specAttributes = {}
    for _, attrId in ipairs(playerClass.attributes) do
        specAttributes[attrId] = true
    end
    local attributes = {}
    for attrId, value in pairs(playerRace.attributes) do
        if state.isCRELMode then
            attributes[attrId] = T.Actor.stats.attributes[attrId](self).base
        else
            attributes[attrId] = (playerRecord.isMale and value.male or value.female) + (specAttributes[attrId] and 10 or 0)
        end
    end
    state.attrs.chargen = attributes

    local skills = {}
    for _, skill in ipairs(core.stats.Skill.records) do
        skills[skill.id] = 5
        if skill.specialization == playerClass.specialization then
            skills[skill.id] = skills[skill.id] + 5
        end
    end
    for skillId, value in pairs(playerRace.skills) do
        skills[skillId] = skills[skillId] + value
    end
    state.skills.major = {}
    state.skills.majorOrder = {}
    for _, skillId in ipairs(playerClass.majorSkills) do
        state.skills.major[skillId] = true
        table.insert(state.skills.majorOrder, skillId)
        skills[skillId] = skills[skillId] + 25
    end
    state.skills.minor = {}
    state.skills.minorOrder = {}
    for _, skillId in ipairs(playerClass.minorSkills) do
        state.skills.minor[skillId] = true
        table.insert(state.skills.minorOrder, skillId)
        skills[skillId] = skills[skillId] + 10
    end
    state.skills.misc = {}
    state.skills.miscOrder = {}
    for _, skill in ipairs(core.stats.Skill.records) do
        if not state.skills.major[skill.id] and not state.skills.minor[skill.id] then
            state.skills.misc[skill.id] = true
            table.insert(state.skills.miscOrder, skill.id)
        end
        if state.isCRELMode then
            skills[skill.id] = T.NPC.stats.skills[skill.id](self).base
        end
    end
    state.skills.start = skills
end
module.setChargenStats = setChargenStats

local function getStat(kind, statId)
    return T.Player.stats[kind][statId](self).base
end
module.getStat = getStat

local function getStatName(kind, statId)
    if kind == "attributes" then
        return core.stats.Attribute.records[statId].name
    else
        return core.stats.Skill.records[statId].name
    end
end
module.getStatName = getStatName

local function showModStatMessages(state)
    local messages = {}
    for _, data in ipairs(modStatMessageStack) do
        table.insert(messages, data.message)
    end
    if #messages > 0 then
        showMessage(state, table.unpack(messages))
        modStatMessageStack = {}
    end
end
module.showModStatMessages = showModStatMessages

local function addModStatMessage(kind, statId, prevValue, options)
    options = options or {}
    local current = T.Player.stats[kind][statId](self).base
    if prevValue == current then return false end
    local toShow
    if kind == "attributes" then
        toShow = current > prevValue and "attrUp" or "attrDown"
    elseif kind == "skills" then
        toShow = current > prevValue and "skillUp" or "skillDown"
    end
    local message = L(toShow, { stat = getStatName(kind, statId), value = current })
    if options.details then
        message = message .. options.details
    end
    local entry = { statId = statId, message = message }
    for i, data in ipairs(modStatMessageStack) do
        -- override previous message if same stat id
        if data.statId == statId then
            modStatMessageStack[i] = entry
            return
        end
    end
    table.insert(modStatMessageStack, entry)
end

local function setStat(state, kind, statId, value, options)
    options = options or {}
    value = math.floor(value)
    if kind == "attributes" then
        state.attrs.base[statId] = value - (getBaseStatsModifiers()[kind][statId] or 0)
    end
    local current = T.Player.stats[kind][statId](self).base
    if current == value then
        return false
    end

    T.Player.stats[kind][statId](self).base = value
    addModStatMessage(kind, statId, current, options)
    return true
end
module.setStat = setStat

local function modStat(state, kind, stat, value, options)
    return setStat(state, kind, stat, T.Player.stats[kind][stat](self).base + value, options)
end
module.modStat = modStat

local function modMagicka(amount)
    module.self.magicka.current = module.self.magicka.current + amount
end
module.modMagicka = modMagicka

local function convertOldSettingValues()
    local conversions = {
        {
            storage = mS.attributesStorage,
            key = "attributeGrowthRate",
            values = { slow = "attrGrowthSlow", standard = "attrGrowthStandard", fast = "attrGrowthFast" }
        },
        {
            storage = mS.healthStorage,
            key = "perLevelHPGain",
            values = { high = "hpGrowthHigh", low = "hpGrowthMed" }
        },
    }
    for _, upgrade in ipairs(conversions) do
        local newValue = upgrade.values[upgrade.storage:get(upgrade.key)]
        if newValue then
            upgrade.storage:set(upgrade.key, newValue)
        end
    end
end
module.convertOldSettingValues = convertOldSettingValues

local function upgradeOldState(newState, oldState)
    if oldState.savedGameVersion < 4.0 then
        newState.lvlProg = oldState.lvlProg
        newState.attrs.diffs = oldState.attributeDiffs
        newState.healthAttrs = oldState.healthAttributes
        newState.skills.max = oldState.maxSkills
        newState.skills.progress = oldState.skillProgress
        newState.skills.decay = oldState.decaySkills
        newState.decay.lastDecayTime = oldState.lastDecayTime
        newState.decay.noDecayTime = oldState.noDecayTime
        newState.decay.noDecayTimeStart = oldState.noDecayTimeStart
        newState.messagesLog = oldState.messagesLog
        return false
    end

    if oldState.savedGameVersion < 4.1 then
        oldState.skills.decay = oldState.decay.skills
        oldState.decay.skills = nil
    end

    if oldState.savedGameVersion < 4.3 then
        oldState.skills.scaled = newState.skills.scaled
    end

    return true
end
module.upgradeOldState = upgradeOldState

local function migrateOldSettings(oldVersion)
    if oldVersion < 4.11 then
        local convert = { none = "skillDecayNone", slow = "skillDecaySlow", standard = "skillDecayStandard", fast = "skillDecayFast" }
        local newValue = convert[mS.skillsStorage:get("decayRate")]
        if newValue then
            mS.skillsStorage:set("skillDecayRate", newValue)
        end
    end

    if oldVersion < 4.14 then
        local constFactor = mS.skillsStorage:get("skillIncreaseConstantFactor")
        local expFactor = mS.skillsStorage:get("skillIncreaseSquaredLevelFactor")
        if constFactor and expFactor then
            local convert = { vanilla = 1, half = 1 / 2, quarter = 1 / 4, disabled = 1, downToHalf = 1 / 2, downToAQuarter = 1 / 4, downToAEighth = 1 / 8 }
            mS.skillsStorage:set("skillGainFactorRange", { convert[constFactor] * 100, convert[constFactor] * convert[expFactor] * 100 })
        end
    end

    if oldVersion < 4.3 then
       local mbsp = storage.playerSection("SettingsPlayerMBSPNCGDMW")
        mS.magickaStorage:set("refundEnabled", mbsp:get("refundEnabled"))
        mS.magickaStorage:set("refundMult", mbsp:get("refundMult"))
        mS.magickaStorage:set("refundStart", mbsp:get("refundStart"))
    end
    return true
end
module.migrateOldSettings = migrateOldSettings

return module
