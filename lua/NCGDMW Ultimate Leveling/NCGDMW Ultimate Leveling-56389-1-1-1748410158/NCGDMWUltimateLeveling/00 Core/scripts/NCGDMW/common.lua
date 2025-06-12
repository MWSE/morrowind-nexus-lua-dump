local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')
local types = require('openmw.types')
local Player = require('openmw.types').Player
local dynamic = types.Actor.stats.dynamic

local log = require('scripts.NCGDMW.log')
local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mSettings = require('scripts.NCGDMW.settings')
local mHelpers = require('scripts.NCGDMW.helpers')

local L = core.l10n(mDef.MOD_NAME)
local iLevelupTotal = core.getGMST("iLevelupTotal")

local module = {}

local currentSerializedBaseStatsMods
local modStatMessageStack = {}

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
    local maxLevel = (mSettings.levelStorage:get("uncapperMaxValue") or 100) - 1
    local totalLevel = 1
    for _, value in pairs(state.skills.calculate.level) do
        totalLevel = totalLevel + value * maxLevel
    end
    return totalLevel
end
module.getTotalPlayerLevel = getTotalPlayerLevel

local function getBaseStatsModifiers()
    local baseStatsMods = { attributes = {}, skills = {} }
    for _, spell in pairs(Player.activeSpells(self)) do
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
        local serializedBaseStatsMods = mHelpers.tableOfTablesToString(baseStatsMods)
        if serializedBaseStatsMods ~= currentSerializedBaseStatsMods then
            currentSerializedBaseStatsMods = serializedBaseStatsMods
            log(string.format("Detected base statistics modifiers: %s", serializedBaseStatsMods))
        end
    end
    return baseStatsMods
end
module.getBaseStatsModifiers = getBaseStatsModifiers

local function getHealthFactor(state)
    local attrFactor = 0
    for attrId, value in pairs(mCfg.healthAttributeFactors) do
        attrFactor = attrFactor + state.attrs.health.current[attrId] * value
    end
    return attrFactor
end
module.getHealthFactor = getHealthFactor

local function getRetroactiveHealthFactor(state)
    local attrFactor = 0
    local initialAttrFactor = 0
    for attrId, value in pairs(mCfg.retroactiveHealthAttributeFactors) do
        attrFactor = attrFactor + state.attrs.health.retroactive[attrId] * value
        initialAttrFactor = initialAttrFactor + state.attrs.health.start[attrId] * value
    end
    return attrFactor + initialAttrFactor
end
module.getRetroactiveHealthFactor = getRetroactiveHealthFactor

local function getMaxHealthModifier()
    local healthMod = 0
    for _, spell in pairs(Player.activeSpells(self)) do
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

local function getAttributeGrowth(state, attrId, attributeGrowthBase)
    state.attrs.growth[attrId] = 0
    for skillId, attributes in pairs(mCfg.skillsImpactOnAttributes) do
        local impactFactor = attributes[attrId]
        if impactFactor then
            local growthFactorFromFavoredAttribute = state.attrs.favored[attrId] and mSettings.attributesStorage:get("growthFactorFromFavoredAttribute") or 1
            local exponentRacialAffinity = mSettings.attributesStorage:get("exponentRacialAffinity") or 0
            state.attrs.growth[attrId] = state.attrs.growth[attrId]
                    + attributeGrowthBase
                    * state.skills.calculate.attributes[skillId]
                    * impactFactor / mCfg.skillsImpactSums[skillId]
                    * growthFactorFromFavoredAttribute
                    * (state.attrs.race[attrId] / 40 ) ^ exponentRacialAffinity
        end
    end
    return state.attrs.growth[attrId]
end
module.getAttributeGrowth = getAttributeGrowth

local function getAttributeDiff(state, attrId, baseStatsMods)
    -- Try to see if something else has modified an attribute and preserve that difference.
    local diff = state.attrs.diffs[attrId]
            + Player.stats.attributes[attrId](self).base
            - (baseStatsMods.attributes[attrId] or 0)
            - state.attrs.base[attrId]
    if diff ~= state.attrs.diffs[attrId] then
        log(string.format("Detected external change %d for \"%s\", base is %d, stored base is %d",
                diff, attrId, Player.stats.attributes[attrId](self).base, state.attrs.base[attrId]))
    end
    state.attrs.diffs[attrId] = diff
    return diff
end
module.getAttributeDiff = getAttributeDiff
local function getStat(kind, statId)
    return Player.stats[kind][statId](self).base
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
    local current = Player.stats[kind][statId](self).base
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
    local current = Player.stats[kind][statId](self).base
    if current == value then
        return false
    end

    Player.stats[kind][statId](self).base = value
    addModStatMessage(kind, statId, current, options)
    return true
end
module.setStat = setStat

local function modStat(state, kind, stat, value, options)
    return setStat(state, kind, stat, Player.stats[kind][stat](self).base + value, options)
end
module.modStat = modStat

local function modMagicka(amount)
    dynamic.magicka(self).current = dynamic.magicka(self).current + amount
end
module.modMagicka = modMagicka

local function convertOldSettingValues()
    if mSettings.skillsStorage:get("uncapperMaxValue") > 200 then
        mSettings.skillsStorage:set("uncapperMaxValue", 100)
    end
    if mSettings.attributesStorage:get("growthFactorFromMajorSkills") > 10 then
        mSettings.attributesStorage:set("growthFactorFromMajorSkills", 1.4)
    end
    if mSettings.attributesStorage:get("growthFactorFromMinorSkills") > 10 then
        mSettings.attributesStorage:set("growthFactorFromMinorSkills", 1.2)
    end
    if mSettings.attributesStorage:get("growthFactorFromMiscSkills") > 10 then
        mSettings.attributesStorage:set("growthFactorFromMiscSkills", 1.0)
    end
end
module.convertOldSettingValues = convertOldSettingValues

local function upgradeOldState(newState, oldState)
    if oldState.savedGameVersion < 4.0 then
        newState.lvlProg = oldState.lvlProg
        newState.attrs.diffs = oldState.attributeDiffs
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
        newState.skills.decay = oldState.decay.skills
        oldState.decay.skills = nil
    end

    if oldState.savedGameVersion < 100.1 then
        newState.skills.trainingSessions = oldState.skills.training.sessions
        newState.skills.trainingUsed = oldState.skills.training.used
        newState.booksRead = oldState.skills.books.read
        newState.skills.growth.level = nil
        newState.skills.growth.attributes = nil
    end
end
module.upgradeOldState = upgradeOldState

local function migrateOldSettings(oldVersion)
    if oldVersion < 4.11 then
        local convert = { none = "skillDecayNone", slow = "skillDecaySlow", standard = "skillDecayStandard", fast = "skillDecayFast" }
        local newValue = convert[mSettings.skillsStorage:get("decayRate")]
        if newValue then
            mSettings.skillsStorage:set("skillDecayRate", newValue)
        end
    end

    if oldVersion < 4.14 then
        local constFactor = mSettings.skillsStorage:get("skillIncreaseConstantFactor")
        local expFactor = mSettings.skillsStorage:get("skillIncreaseSquaredLevelFactor")
        if constFactor and expFactor then
            local convert = { vanilla = 1, half = 1 / 2, quarter = 1 / 4, disabled = 1, downToHalf = 1 / 2, downToAQuarter = 1 / 4, downToAEighth = 1 / 8 }
            mSettings.skillsStorage:set("skillGainFactorRange", { convert[constFactor] * 100, convert[constFactor] * convert[expFactor] * 100 })
        end
    end

    return true
end
module.migrateOldSettings = migrateOldSettings

return module
