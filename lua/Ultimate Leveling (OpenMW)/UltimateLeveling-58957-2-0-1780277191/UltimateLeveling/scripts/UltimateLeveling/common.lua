local core = require('openmw.core')
local async = require('openmw.async')
local self = require('openmw.self')
local ui = require('openmw.ui')
local Actor = require('openmw.types').Actor
local NPC = require('openmw.types').NPC
local I = require('openmw.interfaces')

local ulLog = require('scripts.UltimateLeveling.log')
local ulDef = require('scripts.UltimateLeveling.definition')
local ulCfg = require('scripts.UltimateLeveling.configuration')
local ulSet = require('scripts.UltimateLeveling.settings')
local ulHpr = require('scripts.UltimateLeveling.helpers')

local L = core.l10n(ulDef.MOD_NAME)

local module = {}

local currentSerializedStatsAbiMod
local modStatMessageStack = {}

local function showMessage(state, ...)
    local arg = { ... }
    ui.showMessage(table.concat(arg, "\n"), { showInDialogue = false })
    for _, message in ipairs(arg) do
        ulLog(message)
        table.insert(state.messagesLog, 1, { message = message, time = os.date("%H:%M:%S") })
        if #state.messagesLog > 12 then
            table.remove(state.messagesLog)
        end
    end
end
module.showMessage = showMessage

local function totalGameTimeInHours()
    return core.getGameTime() / (60 * 60)
end
module.totalGameTimeInHours = totalGameTimeInHours

local function getStatsAbiMod()
    local statsAbiMod = { attributes = {}, skills = {} }
    for _, spell in pairs(Actor.activeSpells(self)) do
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
                    statsAbiMod[kind][statId] = (statsAbiMod[kind][statId] or 0) + effect.magnitudeThisFrame
                end
            end
        end
    end
    if next(statsAbiMod.attributes) or next(statsAbiMod.skills) then
        local serializedStatsAbiMod = ulHpr.tableOfTablesToString(statsAbiMod)
        if serializedStatsAbiMod ~= currentSerializedStatsAbiMod then
            currentSerializedStatsAbiMod = serializedStatsAbiMod
            ulLog(string.format("Detected base statistics modifiers: %s", serializedStatsAbiMod))
        end
    end
    return statsAbiMod
end
module.getStatsAbiMod = getStatsAbiMod

local function getCustomSkillRaceMod(skillId)
    local base = I.SkillFramework.getSkillStat(skillId).base
    I.SkillFramework.getSkillStat(skillId).base = nil
    local skillStat = I.SkillFramework.getSkillStat(skillId)
    local skillRecord = I.SkillFramework.getSkillRecord(skillId)
    local raceMod = skillStat.base - skillRecord.startLevel
    skillStat.base = base
    return raceMod
end
module.getCustomSkillRaceMod = getCustomSkillRaceMod

local function setSkillImpacts(state)
    local skillMaxValue = ulSet.uncapperStorage:get("skillMaxValueUncapper")
    local perSkillMaxValue = ulSet.getPerSkillMaxValue()

    local exponentAttribute = ulSet.attributesStorage:get("exponentSkillValueAttributeImpactFactor")
    local SAIF = "SkillAttributeImpactFactor"
    local specializationFactor = ulSet.attributesStorage:get("specializationSkillAttributeImpactFactor") --or 1 --or 1.2

    local exponentLevel = ulSet.levelStorage:get("exponentSkillValueLevelImpactFactor")
    local SLIF = "SkillLevelImpactFactor"
    local typeLevelImpactFactorSum = ulSet.getTypeSkillLevelImpactFactorSum()

    state.skills.impact.attributes = {}
    state.skills.impact.level = {}
    for skillId, base in pairs(state.skills.base) do
        base = math.max(0, base)
        local maxValueBase = (perSkillMaxValue[skillId] or skillMaxValue)
        local type = state.skills.major[skillId] and "major" or (state.skills.minor[skillId] and "minor" or "misc")

        state.skills.impact.attributes[skillId] = base
                * (base / maxValueBase) ^ exponentAttribute
                * ulSet.attributesStorage:get(type .. SAIF)
                * specializationFactor

        local growth = math.max(0, math.min(maxValueBase - state.skills.start[skillId], state.skills.growth[skillId]))
        local room = state.skills.major[skillId] and state.skills.roomMajor or (state.skills.minor[skillId] and state.skills.roomMinor or state.skills.roomMisc)

        state.skills.impact.level[skillId] = growth
                * (base / maxValueBase) ^ exponentLevel
                * ulSet.levelStorage:get(type .. SLIF) / typeLevelImpactFactorSum
                * 1 / room
    end
end
module.setSkillImpacts = setSkillImpacts

local function setAttrsGrowth(state)
    local growthBase = ulSet.attributesStorage:get("attributeGrowthBase") --or 0.2
    local luckGrowthBase = ulSet.attributesStorage:get("luckReputationGrowthBase") -- or 0.5
    local favoredFactor = ulSet.attributesStorage:get("favoredAttributeGrowthFactor") --or 1 --or 1.5
    local exponentRacialAffinity = ulSet.attributesStorage:get("exponentRacialAffinityAttributeGrowthFactor") --or 0.5
    state.attrs.growth = ulHpr.initNewTable(0, Actor.stats.attributes)

    local function growth(attrId, impact, impactFactor)
        state.attrs.growth[attrId] = state.attrs.growth[attrId]
                + (attrId == "luck" and luckGrowthBase or growthBase)
                * (state.attrs.favored[attrId] and favoredFactor or 1)
                * (state.attrs.race[attrId] / 40 ) ^ exponentRacialAffinity
                * impact
                * impactFactor
    end

    growth("luck", state.attrs.reputation, 1)

    for skillId, impact in pairs(state.skills.impact.attributes) do
        if impact ~= 0 then
            if ulCfg.skillAttributeImpactFactors[skillId] then
                local impactFactorSum = ulCfg.getSkillAttributeImpactFactorSum(skillId)
                for attrId, impactFactor in pairs(ulCfg.skillAttributeImpactFactors[skillId]) do
                    if impactFactor ~= 0 then
                        impactFactor = impactFactor / impactFactorSum
                        growth(attrId, impact, impactFactor)
                    end
                end
            else
                local attrId = state.skills.custom[skillId] and I.SkillFramework.getSkillRecord(skillId).attribute or core.stats.Skill.records[skillId].attribute
                growth(attrId, impact, 1)
            end
        end
    end
end
module.setAttrsGrowth = setAttrsGrowth

local function getLevelTotal(state)
    local levelMaxValue = ulSet.uncapperStorage:get("levelMaxValueUncapper") - 1
    local levelTotal = 1
    for _, impact in pairs(state.skills.impact.level) do
        levelTotal = levelTotal
                + impact
                * levelMaxValue
    end
    levelTotal = math.min(levelMaxValue, math.max(1, levelTotal))
    return levelTotal
end
module.getLevelTotal = getLevelTotal

local function setRemainingTraining(state)
    local perLevelTrainingSessions = ulSet.levelStorage:get("trainingLevelCapperValue") --or 7
    state.level.training.remaining = math.max(0, perLevelTrainingSessions * Actor.stats.level(self).current - state.level.training.used)
end
module.setRemainingTraining = setRemainingTraining

local function getHealthAddend(state)
    local healthMultiplier = ulSet.healthStorage:get("healthMultiplier") --or 1
    local impactFactorSum = ulCfg.getAttributeHealthImpactFactorSum()

    local healthAddend = 0
    for attrId, impactFactor in pairs(ulCfg.attributeHealthImpactFactors) do
        healthAddend = healthAddend
                + healthMultiplier
                * state.attrs.health.current[attrId]
                * impactFactor / impactFactorSum
    end
    return healthAddend
end
module.getHealthAddend = getHealthAddend

local function getRetroactiveHealthAddend(state)
    local currentLevel = Actor.stats.level(self).current
    local retroactiveHealthMultiplier = ulSet.healthStorage:get("retroactiveHealthMultiplier") --or 0.05
    local impactFactorSum = ulCfg.getAttributeRetroactiveHealthImpactFactorSum()

    local retroactiveHealthAddend = 0
    for attrId, impactFactor in pairs(ulCfg.attributeRetroactiveHealthImpactFactors) do
        retroactiveHealthAddend = retroactiveHealthAddend
                + retroactiveHealthMultiplier
                * (state.attrs.health.start[attrId] + state.attrs.health.base[attrId])
                * (currentLevel - 1)
                * impactFactor / impactFactorSum
    end
    return retroactiveHealthAddend
end
module.getRetroactiveHealthAddend = getRetroactiveHealthAddend

local function getMaxHealthModifier()
    local healthMod = 0
    for _, spell in pairs(Actor.activeSpells(self)) do
        if spell.affectsBaseValues then
            for _, effect in pairs(spell.effects) do
                if effect.id == core.magic.EFFECT_TYPE.FortifyHealth then
                    healthMod = healthMod + effect.magnitudeThisFrame
                end
            end
        end
    end
    if healthMod ~= 0 then
        ulLog(string.format("Detected max health modifier: %d", healthMod))
    end
    return healthMod
end
module.getMaxHealthModifier = getMaxHealthModifier

local function getStat(kind, statId)
    local stat
    if kind == "attributes" then
        stat = Actor.stats.attributes[statId](self)
    elseif kind == "skills" then
        local getter = NPC.stats.skills[statId]
        if getter then
            stat = getter(self)
        else
            stat = I.SkillFramework.getSkillStat(statId)
        end
    end
    return stat.base
end
module.getStat = getStat

local function getStatName(kind, statId)
    local record
    if kind == "attributes" then
        record = core.stats.Attribute.records[statId]
    elseif kind == "skills" then
        local getter = core.stats.Skill.records[statId]
        if getter then
            record = getter
        else
            record = I.SkillFramework.getSkillRecord(statId)
        end
    end
    return record.name
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
        --[[async:newUnsavableSimulationTimer(2, async:registerTimerCallback(
            "clearMessage",
            function()
                ui.showMessage("", { showInDialogue = false })
                ui.showMessage("", { showInDialogue = false })
                ui.showMessage("", { showInDialogue = false })
            end
        ))--]]
    end
end
module.showModStatMessages = showModStatMessages

local function addModStatMessage(kind, statId, prevValue, options)
    options = options or {}
    local current
    if kind == "attributes" then
        current = Actor.stats.attributes[statId](self).base
    elseif kind == "skills" then
        local getter = NPC.stats.skills[statId]
        if getter then
            current = getter(self).base
        else
            current = I.SkillFramework.getSkillStat(statId).base
        end
    end
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

local function setStat(kind, statId, value, options)
    options = options or {}
    value = math.floor(value)
    local stat
    if kind == "attributes" then
        stat = Actor.stats.attributes[statId](self)
    elseif kind == "skills" then
        local getter = NPC.stats.skills[statId]
        if getter then
            stat = getter(self)
        else
            stat = I.SkillFramework.getSkillStat(statId)
        end
    end
    local current = stat.base
    if current == value then
        return false
    end
    stat.base = value
    addModStatMessage(kind, statId, current, options)
    return true
end
module.setStat = setStat

local function modStat(kind, statId, value, options)
    local stat
    if kind == "attributes" then
        stat = Actor.stats.attributes[statId](self)
    elseif kind == "skills" then
        local getter = NPC.stats.skills[statId]
        if getter then
            stat = getter(self)
        else
            stat = I.SkillFramework.getSkillStat(statId)
        end
    end
    return setStat(kind, statId, stat.base + value, options)
end
module.modStat = modStat

local function getSkillUsedHandlerUncapper(state)
    return function(skillId, params)
        local maxValueBase = ulSet.getSkillMaxValue(skillId)
        local skillStat = NPC.stats.skills[skillId](self)

        if state.skills.base[skillId] >= maxValueBase then
            skillStat.progress = 0
            params.skillGain = 0
            ulLog(string.format("Preventing skill \"%s\" progress from skill use due to Skill Max Value Base %d", skillId, maxValueBase))
            return
            --return false
        end

        if not I.SkillEvolution then
            if params.skillGain ~= 0 then
                local skillAbiMod = getStatsAbiMod().skills[skillId] or 0
                local skillRequirement = I.SkillProgression.getSkillProgressRequirement(skillId)
                local newSkillRequirement = skillRequirement - skillAbiMod * (state.skills.major[skillId] and 0.75 or (state.skills.minor[skillId] and 1 or 1.25)) * (state.skills.specialization and 0.8 or 1)
                local progress = skillStat.progress
                skillStat.progress = progress + params.skillGain / newSkillRequirement
                ulLog(string.format("Skill \"%s\" progress is now %.3f, previously %.3f", skillId, skillStat.progress, progress))
            end
            if skillStat.progress >= 1 and skillStat.base >= 100 then
                skillStat.progress = 0
                params.skillGain = 0
                I.SkillProgression.skillLevelUp(skillId, I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
                ulLog(string.format("Skill \"%s\" progress has reached threshold and skill value is over 100; manually triggering skill levelup", skillId))
            end
        end
    end
end

local function getSkillLevelUpHandler(state)
    return function(skillId, source, params)
        local maxValueBase = ulSet.getSkillMaxValue(skillId)
        local isCustomSkill = state.skills.custom[skillId]
        local skillStat = isCustomSkill and I.SkillFramework.getSkillStat(skillId) or NPC.stats.skills[skillId](self)

        if state.skills.base[skillId] >= maxValueBase and params.skillIncreaseValue > 0 then
            local skillAbiMod = getStatsAbiMod().skills[skillId] or 0
            local maxValue = maxValueBase + skillAbiMod
            setStat("skills", skillId, maxValue)
            skillStat.progress = 0
            params.skillIncreaseValue = 0
            ulLog(string.format("Preventing skill \"%s\" level up due to Skill Max Value %d", skillId, maxValue))
            showModStatMessages(state)
            return
            --return false
        end

        if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Trainer or I.SkillFramework and source == I.SkillFramework.SkillIncreaseSource.Trainer then
            if ulSet.levelStorage:get("trainingLevelCapper") and state.level.training.remaining == 0 then
                params.skillIncreaseValue = 0
                ulLog(string.format("Preventing skill \"%s\" level up from training", skillId))
                return
                --return false
            end
            state.level.training.used = state.level.training.used + 1
        end

        if not isCustomSkill and skillStat.base >= 100 and params.skillIncreaseValue > 0 then
            params.override = true
            if not I.SkillEvolution then
                modStat("skills", skillId, params.skillIncreaseValue)
            end
        end

        self:sendEvent(ulDef.events.updateSkillGrowth, { skillId = skillId, skillLevel = skillStat.base, params = params })
    end
end

local function statsBaseUpdateHandler(state)
    local statsAbiMod = getStatsAbiMod()
    local statsDiff = { attributes = {}, skills = {} }

    for skillId, storedBase in pairs(state.skills.base) do
        local skillStat = state.skills.custom[skillId] and I.SkillFramework.getSkillStat(skillId) or NPC.stats.skills[skillId](self)
        local base = skillStat.base - (statsAbiMod.skills[skillId] or 0)
        local diff = base - storedBase
        if diff ~= 0 then
            statsDiff.skills[skillId] = diff
        end
    end

    for attrId, storedBase in pairs(state.attrs.base) do
        local base = Actor.stats.attributes[attrId](self).base - (statsAbiMod.attributes[attrId] or 0)
        local diff = base - storedBase
        if diff ~= 0 then
            statsDiff.attributes[attrId] = diff
        end
    end

    if next(statsDiff.skills) or next(statsDiff.attributes) then
        local serializedStatsDiff = ulHpr.tableOfTablesToString(statsDiff)
        ulLog(string.format("Confirming external change: %s", serializedStatsDiff))
        self:sendEvent(ulDef.events.updateStatsExtMod, statsDiff)
    end
end
module.statsBaseUpdateHandler = statsBaseUpdateHandler

local function addHandlers(state)
    if I.SkillEvolution and I.SkillEvolution.addSkillUsedHandler then
        I.SkillEvolution.addSkillUsedHandler(getSkillUsedHandlerUncapper(state))
    else
        I.SkillProgression.addSkillUsedHandler(getSkillUsedHandlerUncapper(state))
    end

    I.SkillProgression.addSkillLevelUpHandler(getSkillLevelUpHandler(state))
    if I.SkillFramework and I.SkillFramework.addSkillLevelUpHandler then
        I.SkillFramework.addSkillLevelUpHandler(getSkillLevelUpHandler(state))
    end
end
module.addHandlers = addHandlers

return module
