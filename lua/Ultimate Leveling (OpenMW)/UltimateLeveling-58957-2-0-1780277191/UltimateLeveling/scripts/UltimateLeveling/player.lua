local core = require('openmw.core')
local async = require('openmw.async')
local self = require('openmw.self')
local ui = require('openmw.ui')
local Actor = require('openmw.types').Actor
local NPC = require('openmw.types').NPC
local Player = require('openmw.types').Player
local I = require('openmw.interfaces')

local ulSet = require('scripts.UltimateLeveling.settings')
-- Init settings first to init the storage which is used everywhere
ulSet.initSettings()

local ulLog = require('scripts.UltimateLeveling.log')
local ulDef = require('scripts.UltimateLeveling.definition')
local ulCfg = require('scripts.UltimateLeveling.configuration')
local ulCom = require('scripts.UltimateLeveling.common')
local ulHpr = require('scripts.UltimateLeveling.helpers')
--local ulRdr = require('scripts.UltimateLeveling.renderers')
local ulSpl = require('scripts.UltimateLeveling.spells')
local ulUi = require("scripts.UltimateLeveling.ui")

local L = core.l10n(ulDef.MOD_NAME)

local state = {
    initialised = false,
    savedGameVersion = ulDef.savedGameVersion,
    chargen = {
        race = nil,
        birthsign = nil,
        name = nil,
        class = nil,
        specialization = nil,
    },
    skills = {
        major = {}, majorOrder = {}, roomMajor = 0,
        minor = {}, minorOrder = {}, roomMinor = 0,
        misc = {}, miscOrder = {}, roomMisc = 0,
        custom = {}, customOrder = {},
        specialization = {},
        race = {},
        raceMod = {},
        start = {},
        base = {},
        growth = {},
        extMod = {},
        impact = {
            attributes = {},
            level = {},
        },
    },
    attrs = {
        race = {},
        favored = {}, favoredOrder = {},
        start = {},
        base = {},
        growth = {},
        extMod = {},
        progress = {},
        reputation = 0,
        health = {
            current = {},
            base = {},
            start = {},
        },
    },
    level = {
        progress = 0,
        max = 1,
        attributes = {},
        training = {
            remaining = 0,
            used = 0,
        }
    },
    messagesLog = {},
}

local updateStarterSpellsAsked = false
local updateHealthAsked = false
local lastUpdateHealthTime = 0
local prevHealthMod = 0
local sleep = {
    meditate = false,
    start = nil,
    slept = false,
}
local chargenUiModes = { ChargenRace = true, ChargenClassPick = true, ChargenBirth = true }
local registeredCustomSkills = {}
local customSkillsHandled = false

local incompatiblePlugins = {}
for _, plugin in ipairs({"ncg.omwscripts"}) do
    if core.contentFiles.has(plugin) then
        table.insert(incompatiblePlugins, plugin)
    end
end
if #incompatiblePlugins > 0 then
    ui.create(ulUi.missingPluginWarning(L("pluginErrorNotCompatible"), incompatiblePlugins))
    return
end

if not core.contentFiles.has("UltimateLeveling.omwaddon") then
    ui.create(ulUi.missingPluginWarning(L("pluginErrorMissingOneOf"), "UltimateLeveling.omwaddon"))
    return
end

ulLog("OpenMW 0.49.0 detected. Lua API recent enough for all features.")


-- Hook into Skill Framework to track race modifiers when skills register
local function initSkillFrameworkRegistrationHandler()
    if not I.SkillFramework then return end

    I.SkillFramework.addSkillRegisteredHandler(function(skillId)
        registeredCustomSkills[skillId] = true

        --self:sendEvent(ulDef.events.updatePerSkillRenderer, { record = I.SkillFramework.getSkillRecord(skillId) })

        if not state.initialised then
            return
        elseif not state.skills.start[skillId] or not state.skills.raceMod[skillId] then
            self:sendEvent(ulDef.events.updateStartSkills, { baseStart = false, clearAll = false })
            return
        else
            local maxValueBase = ulSet.getSkillMaxValue(skillId)
            I.SkillFramework.modifySkill(skillId, {
                    startLevel = (state.skills.start[skillId] - state.skills.raceMod[skillId]),
                    maxLevel = maxValueBase,
                }
            )
        end
    end)
end
initSkillFrameworkRegistrationHandler()

---- Core Logic ----

local function setChargenStats()
    local playerRecord = NPC.record(self)
    local playerClass = NPC.classes.record(playerRecord.class)
    local playerRace = NPC.races.record(playerRecord.race)
    local playerBirthsign = Player.birthSigns.record(Player.getBirthSign(self))

    state.chargen.race = playerRecord.isMale and "Male "..playerRace.name or "Female "..playerRace.name
    state.chargen.birthsign = playerBirthsign.name
    state.chargen.name = playerRecord.name
    state.chargen.class = playerClass.name
    state.chargen.specialization = (playerClass.specialization == "combat" and "Combat" or (playerClass.specialization == "magic" and "Magic") or "Stealth")
end

local function setStartSkills(baseStart, clearAll)
    local playerRecord = NPC.record(self)
    local playerClass = NPC.classes.record(playerRecord.class)
    local playerRace = NPC.races.record(playerRecord.race)

    local skillValue = baseStart and 5 or ulSet.gameStartStorage:get("skillStartValue")
    local customSkillValueMultiplier = baseStart and 1 or ulSet.gameStartStorage:get("customSkillStartValueMultiplier")
    local specializationSkillBonus = baseStart and 5 or ulSet.gameStartStorage:get("specializationSkillStartBonus")
    local customSkillSpecializationBonusMultiplier = baseStart and 1 or ulSet.gameStartStorage:get("customSkillSpecializationStartBonusMultiplier")
    local raceSkillBonusMultiplier = baseStart and 1 or ulSet.gameStartStorage:get("raceSkillStartBonusMultiplier")
    local majorSkillBonus = baseStart and 25 or ulSet.gameStartStorage:get("majorSkillStartBonus")
    local minorSkillBonus = baseStart and 10 or ulSet.gameStartStorage:get("minorSkillStartBonus")
    local skillMaxValue = ulSet.uncapperStorage:get("skillMaxValueUncapper")
    local perSkillMaxValue = ulSet.getPerSkillMaxValue()
    local skillsAbiMod = ulCom.getStatsAbiMod().skills

    local skills = {}
    state.skills.start = {}

    local function externalModifier(skillId)
        if clearAll or not state.skills.extMod[skillId] then
            state.skills.extMod[skillId] = 0
        elseif state.skills.extMod[skillId] ~= 0 then
            ulLog(string.format("Preserving previous \"%s\" external change of %d", skillId, state.skills.extMod[skillId]))
        end
        return state.skills.extMod[skillId]
    end

    state.skills.specialization = {}
    state.skills.race = {}
    state.skills.raceMod = {}
    for _, skill in ipairs(core.stats.Skill.records) do
        skills[skill.id] = skillValue + externalModifier(skill.id)
        if skill.specialization == playerClass.specialization then
            state.skills.specialization[skill.id] = true
            skills[skill.id] = skills[skill.id] + specializationSkillBonus
        end
        local raceMod = playerRace.skills[skill.id] or 0
        if raceMod ~= 0 then
            state.skills.race[skill.id] = true
            skills[skill.id] = skills[skill.id] + math.floor(raceMod * raceSkillBonusMultiplier)
        end
        state.skills.raceMod[skill.id] = raceMod
    end

    local roomMajor = 0
    state.skills.major = {}
    state.skills.majorOrder = {}
    for _, skillId in ipairs(playerClass.majorSkills) do
        state.skills.major[skillId] = true
        table.insert(state.skills.majorOrder, skillId)
        skills[skillId] = skills[skillId] + majorSkillBonus
        local maxValueBase = (perSkillMaxValue[skillId] or skillMaxValue)
        skills[skillId] = math.min(maxValueBase, skills[skillId])
        --roomMajor = roomMajor + math.max(0, maxValueBase - skills[skillId])
        roomMajor = roomMajor + (maxValueBase - skills[skillId])
    end
    state.skills.roomMajor = roomMajor

    local roomMinor = 0
    state.skills.minor = {}
    state.skills.minorOrder = {}
    for _, skillId in ipairs(playerClass.minorSkills) do
        state.skills.minor[skillId] = true
        table.insert(state.skills.minorOrder, skillId)
        skills[skillId] = skills[skillId] + minorSkillBonus
        local maxValueBase = (perSkillMaxValue[skillId] or skillMaxValue)
        skills[skillId] = math.min(maxValueBase, skills[skillId])
        --roomMinor = roomMinor + math.max(0, maxValueBase - skills[skillId])
        roomMinor = roomMinor + (maxValueBase - skills[skillId])
    end
    state.skills.roomMinor = roomMinor
    local roomMisc = 0
    state.skills.misc = {}
    state.skills.miscOrder = {}
    for _, skill in ipairs(core.stats.Skill.records) do
        if not state.skills.major[skill.id] and not state.skills.minor[skill.id] then
            state.skills.misc[skill.id] = true
            table.insert(state.skills.miscOrder, skill.id)
            local maxValueBase = (perSkillMaxValue[skill.id] or skillMaxValue)
            skills[skill.id] = math.min(maxValueBase, skills[skill.id])
            --roomMisc = roomMisc + math.max(0, maxValueBase - skills[skill.id])
            roomMisc = roomMisc + (maxValueBase - skills[skill.id])
        end
    end
    state.skills.custom = {}
    state.skills.customOrder = {}
    for skillId, skill in pairs(I.SkillFramework and I.SkillFramework.getSkillRecords() or {}) do
        state.skills.custom[skillId] = true
        skills[skillId] = math.floor(skillValue * customSkillValueMultiplier) + externalModifier(skillId)
        if skill.specialization == playerClass.specialization then
            state.skills.specialization[skillId] = true
            skills[skillId] = skills[skillId] + math.floor(specializationSkillBonus * customSkillSpecializationBonusMultiplier)
        end
        if Player.isCharGenFinished(self) then
            local storedRaceMod = state.skills.raceMod[skillId] or 0
            state.skills.raceMod[skillId] = ulCom.getCustomSkillRaceMod(skillId)
            if state.skills.raceMod[skillId] ~= 0 then
                state.skills.race[skillId] = true
                skills[skillId] = skills[skillId] + math.floor(state.skills.raceMod[skillId] * raceSkillBonusMultiplier)
                ulLog(string.format("Stored race modifier %d, previously %d, for custom skill '%s'", state.skills.raceMod[skillId], storedRaceMod, skillId))
            end
        end
        state.skills.misc[skillId] = true
        table.insert(state.skills.customOrder, skillId)
        local maxValueBase = (perSkillMaxValue[skillId] or skillMaxValue)
        skills[skillId] = math.min(maxValueBase, skills[skillId])
        --roomMisc = roomMisc + math.max(0, maxValueBase - skills[skillId])
        roomMisc = roomMisc + (maxValueBase - skills[skillId])
        I.SkillFramework.modifySkill(skillId, {
                startLevel = (skills[skillId] - (state.skills.raceMod[skillId] or 0)),
                maxLevel = maxValueBase,
            }
        )
    end
    state.skills.roomMisc = roomMisc
    state.skills.start = skills

    for skillId, value in pairs(state.skills.start) do
        if baseStart then
            local base = state.skills.custom[skillId] and I.SkillFramework.getSkillStat(skillId).base or NPC.stats.skills[skillId](self).base
            state.skills.growth[skillId] = base - value - (skillsAbiMod[skillId] or 0)
        elseif not state.skills.growth[skillId] then
            state.skills.growth[skillId] = 0
        end
    end
end

local function setStartAttrs(clearAll)
    local playerRecord = NPC.record(self)
    local playerClass = NPC.classes.record(playerRecord.class)
    local playerRace = NPC.races.record(playerRecord.race)

    local raceAttributeMultiplier = ulSet.gameStartStorage:get("raceAttributeStartMultiplier")
    local favoredAttributeBonus = ulSet.gameStartStorage:get("favoredAttributeStartBonus")
    local attributePenalty = ulSet.gameStartStorage:get("attributeStartPenalty")
    local luckPenalty = ulSet.gameStartStorage:get("luckStartPenalty")
    local attributeMaxValue = ulSet.uncapperStorage:get("attributeMaxValueUncapper")
    local perAttributeMaxValue = ulSet.getPerAttributeMaxValue()

    local function externalModifier(attrId)
        if clearAll or not state.attrs.extMod[attrId] then
            state.attrs.extMod[attrId] = 0
        elseif state.attrs.extMod[attrId] ~= 0 then
            ulLog(string.format("Preserving previous \"%s\" external change of %d", attrId, state.attrs.extMod[attrId]))
        end
        return state.attrs.extMod[attrId]
    end

    local attributes = {}
    state.attrs.race = {}
    state.attrs.start = {}
    for attrId, value in pairs(playerRace.attributes) do
        attributes[attrId] = 40 + math.floor((((playerRecord.isMale or ulSet.gameStartStorage:get("genderNeutralAttributeStartValue")) and value.male or value.female) - 40) * raceAttributeMultiplier)
        state.attrs.race[attrId] = attributes[attrId]
        attributes[attrId] = attributes[attrId] + externalModifier(attrId)
    end
    state.attrs.favored = {}
    state.attrs.favoredOrder = {}
    for _, attrId in ipairs(playerClass.attributes) do
        state.attrs.favored[attrId] = true
        table.insert(state.attrs.favoredOrder, attrId)
        attributes[attrId] = attributes[attrId] + favoredAttributeBonus
    end
    for attrId, value in pairs(attributes) do
        if attrId == "luck" then
            attributes[attrId] = value - luckPenalty
        else
            attributes[attrId] = value - attributePenalty
        end
        local maxValueBase = (perAttributeMaxValue[attrId] or attributeMaxValue)
        attributes[attrId] = math.min(maxValueBase, attributes[attrId])
    end
    state.attrs.start = attributes

    state.attrs.health.current = ulHpr.initNewTable(0, ulCfg.attributeHealthImpactFactors)
    state.attrs.health.base = ulHpr.initNewTable(0, ulCfg.attributeRetroactiveHealthImpactFactors)
    state.attrs.health.start = ulHpr.initNewTable(0, ulCfg.attributeRetroactiveHealthImpactFactors)
end

local function init(baseStart, clearAll)
    ulLog("Ultimate Leveling INIT begins!")

    setChargenStats()
    setStartSkills(baseStart, clearAll)
    setStartAttrs(clearAll)

    if baseStart then
        state.level.max = Actor.stats.level(self).current
    end

    updateStarterSpellsAsked = true
    if not state.initialised then
        state.initialised = true
        ulCom.addHandlers(state)
        if ulSet.globalStorage:get("showStartupMessage") then
            async:newSimulationTimer(2, async:registerTimerCallback(
                    "newGameGreeting",
                    function()
                        ulCom.showMessage(state, L("doSettings"))
                        ulLog("Ultimate Leveling INIT has ended!")
                    end
            ))
        end
    end
end

local function updateSkills()
    local skillMaxValue = ulSet.uncapperStorage:get("skillMaxValueUncapper")
    local perSkillMaxValue = ulSet.getPerSkillMaxValue()
    local skillsAbiMod = ulCom.getStatsAbiMod().skills

    state.skills.base = {}
    for skillId, startSkill in pairs(state.skills.start) do
        local maxValueBase = (perSkillMaxValue[skillId] or skillMaxValue)
        local base = startSkill + state.skills.growth[skillId]
        if base >= maxValueBase then
            base = maxValueBase
            local skillStat = state.skills.custom[skillId] and I.SkillFramework.getSkillStat(skillId) or NPC.stats.skills[skillId](self)
            skillStat.progress = 0
        end
        --if not state.skills.custom and base >= maxValueBase then
        --[[if base >= maxValueBase then
            base = maxValueBase
            local skillStat = state.skills.custom[skillId] and I.SkillFramework.getSkillStat(skillId) or NPC.stats.skills[skillId](self)
            skillStat.progress = 0
        end--]]
        state.skills.base[skillId] = base
        --state.skills.base[skillId] = math.min(maxValueBase, base)
        local value = base + (skillsAbiMod[skillId] or 0)
        ulCom.setStat("skills", skillId, value)
    end
    ulCom.showModStatMessages(state)
    ulCom.setSkillImpacts(state)
end

local function updateAttributes()
    local attributeMaxValue = ulSet.uncapperStorage:get("attributeMaxValueUncapper")
    local perAttributeMaxValue = ulSet.getPerAttributeMaxValue()
    local attrsAbiMod = ulCom.getStatsAbiMod().attributes
    ulCom.setAttrsGrowth(state)
    state.attrs.base = {}
    for attrId, startAttr in pairs(state.attrs.start) do
        local maxValueBase = (perAttributeMaxValue[attrId] or attributeMaxValue)
        state.attrs.growth[attrId] = math.min(maxValueBase - startAttr, state.attrs.growth[attrId])
        local base = startAttr + state.attrs.growth[attrId]
        base = math.min(maxValueBase, base)
        state.attrs.progress[attrId] = base % 1
        state.attrs.base[attrId] = math.floor(base)

        local value = base + (attrsAbiMod[attrId] or 0)

        ulCom.setStat("attributes", attrId, value)
    end
    ulCom.showModStatMessages(state)
end

local function updateLevel()
    local levelTotal = ulCom.getLevelTotal(state)
    local newLevel = math.floor(levelTotal)
    local currentLevel = Actor.stats.level(self).current

    if newLevel ~= currentLevel then
        if ulSet.levelStorage:get("sleepLevelUp") and newLevel > state.level.max then
            if not sleep.meditate then
                sleep.meditate = true
                ulCom.showMessage(state, L("meditate"))
            elseif sleep.slept then
                sleep.slept = false
                sleep.meditate = false
                Actor.stats.level(self).current = newLevel
                ulCom.showMessage(state, L("lvlUp", { level = newLevel }))
                --local vanillaLevelupScreen = ui.create(ulUi.getVanillaLevelupScreen(state))
                --ulUi.setVanillaLevelupScreen(vanillaLevelupScreen)
                state.level.max = newLevel
                updateHealthAsked = true
            end
        else
            sleep.meditate = false
            if newLevel > currentLevel then
                Actor.stats.level(self).current = newLevel
                ulCom.showMessage(state, L("lvlUp", { level = newLevel }))
                if newLevel > state.level.max then
                    state.level.max = newLevel
                end
            elseif newLevel < currentLevel then
                Actor.stats.level(self).current = newLevel
                ulCom.showMessage(state, L("lvlDown", { level = newLevel }))
            end
            updateHealthAsked = true
        end
    end
    state.level.progress = (levelTotal % 1) + (newLevel - Actor.stats.level(self).current)
    ulCom.setRemainingTraining(state)
end

local function updateHealth(data)
    lastUpdateHealthTime = lastUpdateHealthTime + (data or 0.5)
    if lastUpdateHealthTime < 0.5 then return end
    lastUpdateHealthTime = 0

    local attrsAbiMod = ulCom.getStatsAbiMod().attributes

    --local recalculate = false
    for attribute, value in pairs(state.attrs.health.current) do
        local current = Actor.stats.attributes[attribute](self).modified
        if current ~= value then
            state.attrs.health.current[attribute] = current
            --recalculate = true
            updateHealthAsked = true
        end
    end
    for attribute, value in pairs(state.attrs.health.base) do
        local current = Actor.stats.attributes[attribute](self).base
        if current ~= value then
            state.attrs.health.base[attribute] = current
            updateHealthAsked = true
        end
    end
    for attribute, value in pairs(state.attrs.health.start) do
        local current = state.attrs.start[attribute] + (attrsAbiMod[attribute] or 0)
        if current ~= value then
            state.attrs.health.start[attribute] = current
            updateHealthAsked = true
        end
    end

    local healthMod = ulCom.getMaxHealthModifier()
    if prevHealthMod ~= healthMod then
        updateHealthAsked = true
    end
    prevHealthMod = healthMod

    --if recalculate or updateHealthAsked then
    if updateHealthAsked then
        updateHealthAsked = false
        local maxHealth = math.floor(ulCom.getHealthAddend(state)
                + ulCom.getRetroactiveHealthAddend(state)
                + healthMod)
        local health = Actor.stats.dynamic.health(self)
        local ratio = health.current / health.base
        health.base = maxHealth
        health.current = ratio * maxHealth
    end
end

local function updateStats()
    updateSkills()
    updateAttributes()
    if updateStarterSpellsAsked then
        updateStarterSpellsAsked = false
        ulSpl.updateStarterSpells()
    end
    updateLevel()
end

local function updateSkillGrowth(skillId, skillLevel, params)
    if params.skillIncreaseValue == 0 then return end
    local base = state.skills.custom[skillId] and I.SkillFramework.getSkillStat(skillId).base or NPC.stats.skills[skillId](self).base
    if not params.override and base == skillLevel then return end
    local storedGrowth = state.skills.growth[skillId]
    state.skills.growth[skillId] = storedGrowth + params.skillIncreaseValue

    --if params.growthDecay then
    --    ulLog(string.format("Growth updated to %d, previously %d, for Skill \"%s\" after Skill Evolution growth-decay", state.skills.growth[skillId], storedGrowth, skillId))
    --else
    ulLog(string.format("Growth updated to %d, previously %d, for Skill \"%s\"", state.skills.growth[skillId], storedGrowth, skillId))
    --end
    updateStats()
end

local function updateStatsExtMod(statsDiff)
    local statsAbiMod = ulCom.getStatsAbiMod()

    local skillMaxValue = ulSet.uncapperStorage:get("skillMaxValueUncapper")
    local perSkillMaxValue = ulSet.getPerSkillMaxValue()
    for skillId, diff in pairs(statsDiff.skills or {}) do
        local maxValueBase = (perSkillMaxValue[skillId] or skillMaxValue)
        local skillStat = state.skills.custom[skillId] and I.SkillFramework.getSkillStat(skillId) or NPC.stats.skills[skillId](self)
        local base = skillStat.base - (statsAbiMod.skills[skillId] or 0)
        local storedBase = state.skills.base[skillId]
        if base ~= storedBase then
            diff = math.min(maxValueBase - storedBase, diff)
            if diff ~= 0 then
                if I.SkillEvolution and (I.SkillEvolution.getState().skills.base[skillId] or 0) < (I.SkillEvolution.getState().skills.max[skillId] or 0) then
                    local storedGrowth = state.skills.growth[skillId]
                    state.skills.growth[skillId] = storedGrowth + diff
                    ulLog(string.format("Growth updated to %d, previously %d, for Skill \"%s\" after Skill Evolution growth-decay", state.skills.growth[skillId], storedGrowth, skillId))
                    --self:sendEvent(ulDef.events.updateStats)
                else
                    local storedDiff = state.skills.extMod[skillId]
                    state.skills.extMod[skillId] = storedDiff + diff
                    ulLog(string.format("Confirmed external change %d, previously %d, for skill \"%s\"; base is %d and stored base is %d",
                        state.skills.extMod[skillId], storedDiff, skillId, base, storedBase))
                    --self:sendEvent(ulDef.events.updateStartSkills, { baseStart = false, clearAll = false })
                end
            --else
                --self:sendEvent(ulDef.events.updateStats)
            end
        else
            statsDiff.skills[skillId] = nil
        end
    end

    local attributeMaxValue = ulSet.uncapperStorage:get("attributeMaxValueUncapper")
    local perAttributeMaxValue = ulSet.getPerAttributeMaxValue()
    for attrId, diff in pairs(statsDiff.attributes or {}) do
        local maxValueBase = (perAttributeMaxValue[attrId] or attributeMaxValue)
        local base = Actor.stats.attributes[attrId](self).base - (statsAbiMod.attributes[attrId] or 0)
        local storedBase = state.attrs.base[attrId]
        if base ~= storedBase then
            diff = math.min(maxValueBase - storedBase, diff)
            if diff ~= 0 then
                local storedDiff = state.attrs.extMod[attrId]
                state.attrs.extMod[attrId] = storedDiff + diff
                ulLog(string.format("Confirmed external change %d, previously %d, for attribute \"%s\"; base is %d and stored base is %d",
                    state.attrs.extMod[attrId], storedDiff, attrId, base, storedBase))
                --self:sendEvent(ulDef.events.updateStartAttrs, { clearAll = false })
            --else
                --self:sendEvent(ulDef.events.updateStats)
            end
        else
            statsDiff.attributes[attrId] = nil
        end
    end

    local isSkillsDiff = next(statsDiff.skills)
    local isAttributesDiff = next(statsDiff.attributes)

    --[[if isSkillsDiff and isAttributesDiff then
        self:sendEvent(ulDef.events.updateStartStats, { baseStart = false, clearAll = false })
    elseif isSkillsDiff then
        self:sendEvent(ulDef.events.updateStartSkills, { baseStart = false, clearAll = false })
    elseif isAttributesDiff then
        self:sendEvent(ulDef.events.updateStartAttrs, { clearAll = false })
    end--]]

    if isSkillsDiff or isAttributesDiff then
        if isSkillsDiff then
            setStartSkills(false, false)
        end
        if isAttributesDiff then
            setStartAttrs(false)
        end
        updateStats()
    end
end

local function sleepLevelup(data)
    if data.newMode == "Rest" and data.arg then
        sleep.start = ulCom.totalGameTimeInHours()
    end
    if not data.newMode and sleep.start then
        if (ulCom.totalGameTimeInHours() - sleep.start) >= 1 then
            sleep.slept = true
            updateLevel()
        end
        sleep.start = nil
    end
end

local function trainingLevelCap()
    local message = L("trainingLevelCap", { remaining = tostring(state.level.training.remaining) })
    ulCom.showMessage(state, message)
end

local function updateState(data)
    if data.savedGameVersion < 1.1 then
        data.attrs.health.retroactive = nil
    end
end

-- Public interface

local interface = {
    version = ulDef.interfaceVersion,
    getState = function() return state end,
    -- Get an attribute value, also set it if value is not nil
    setAttribute = function(attrId, value)
        if not attrId or not Actor.stats.attributes[attrId] then
            error(string.format("Invalid attribute id \"%s\""), attrId)
        end
        local changed = false
        if value then
            local numValue = tonumber(value)
            if not numValue or numValue < 0 then
                error(string.format("Invalid attribute value \"%s\""), value)
            end
            changed = ulCom.setStat("attributes", attrId, numValue)
        end
        return changed, ulCom.getStat("attributes", attrId)
    end,
    -- Get a skill value, also set it if value is not nil
    setSkill = function(skillId, value)
        if not skillId or (not NPC.stats.skills[skillId] and not I.SkillFramework.getSkillRecord(skillId)) then
            error(string.format("Invalid skill id \"%s\""), skillId)
        end
        local changed = false
        if value then
            local numValue = tonumber(value)
            if not numValue or numValue < 0 then
                error(string.format("Invalid skill value \"%s\""), value)
            end
            changed = ulCom.setStat("skills", skillId, numValue)
        end
        return changed, ulCom.getStat("skills", skillId)
    end,
    -- Get a skill progress value, also set it if value is not nil
    setSkillProgress = function(skillId, value)
        local skillStat = state.skills.custom[skillId] and I.SkillFramework.getSkillStat(skillId) or NPC.stats.skills[skillId](self)
        if not skillId or not skillStat then
            error(string.format("Invalid skill id \"%s\""), skillId)
        end
        local changed = false
        if value then
            local numValue = tonumber(value)
            if not numValue or numValue < 0 or numValue >= 1 then
                error(string.format("Invalid skill progress value \"%s\", it must be between 0 and 1"), value)
            end
            changed = skillStat.progress ~= numValue
            skillStat.progress = numValue
        end
        return changed, skillStat.progress
    end,
    setSkillExtMod = function(skillId, value)
        if not skillId or (not NPC.stats.skills[skillId] and not I.SkillFramework.getSkillRecord(skillId)) then
            error(string.format("Invalid skill id \"%s\""), skillId)
        end
        local changed = false
        if value then
            local numValue = tonumber(value)
            if not numValue then
                error(string.format("Invalid skill external modifier value \"%s\""), value)
            end
            changed = state.skills.extMod[skillId] ~= numValue
            state.skills.extMod[skillId] = numValue
            self:sendEvent(ulDef.events.updateStartSkills, { baseStart = false, clearAll = false })
        end
        return changed, state.skills.extMod[skillId]
    end,
    setSkillGrowth = function(skillId, value)
        if not skillId or (not NPC.stats.skills[skillId] and not I.SkillFramework.getSkillRecord(skillId)) then
            error(string.format("Invalid skill id \"%s\""), skillId)
        end
        local changed = false
        if value then
            local numValue = tonumber(value)
            if not numValue then
                error(string.format("Invalid skill growth value \"%s\""), value)
            end
            changed = state.skills.growth[skillId] ~= numValue
            state.skills.growth[skillId] = numValue
            self:sendEvent(ulDef.events.updateStats)
        end
        return changed, state.skills.growth[skillId]
    end,
    getSkillAttributeImpactFactors = function(skillId)
        if not skillId or (not NPC.stats.skills[skillId] and not I.SkillFramework.getSkillRecord(skillId)) then
            error(string.format("Invalid skill id \"%s\"", skillId))
        end
        return ulCfg.skillAttributeImpactFactors[skillId] or {}
    end,
    setSkillAttributeImpactFactors = function(skillId, impactFactors)
        if not skillId or (not NPC.stats.skills[skillId] and not I.SkillFramework.getSkillRecord(skillId)) then
            error(string.format("Invalid skill id \"%s\"", skillId))
        end
        if not impactFactors or type(impactFactors) ~= "table" then
            error("Invalid attribute impact factors parameter, it has to be a table (attributeId, impactValue)")
        end
        for attrId, impactFactor in pairs(impactFactors) do
            if not core.stats.Attribute.records[attrId] then
                error(string.format("Invalid attribute id \"%s\"", attrId))
            end
            if type(impactFactor) ~= "number" then
                error(string.format("Invalid impact factor value \"%s\"", impactFactor))
            end
        end
        local changed = ulCfg.setSkillAttributeImpactFactors(skillId, impactFactors)
        self:sendEvent(ulDef.events.updateStats)
        return changed, ulCfg.skillAttributeImpactFactors[skillId] or {}
    end,
    getAttributeHealthImpactFactors = function ()
        return ulCfg.attributeHealthImpactFactors or {}
    end,
    setAttributeHealthImpactFactors = function(impactFactors)
        if not impactFactors or type(impactFactors) ~= "table" then
            error("Invalid health impact factors parameter, it has to be a table (attributeId, impactValue)")
        end
        for attrId, impactFactor in pairs(impactFactors) do
            if not core.stats.Attribute.records[attrId] then
                error(string.format("Invalid attribute id \"%s\"", attrId))
            end
            if type(impactFactor) ~= "number" then
                error(string.format("Invalid impact factor value \"%s\"", impactFactor))
            end
        end
        local changed = ulCfg.setAttributeHealthImpactFactors(impactFactors)
        state.attrs.health.current = ulHpr.initNewTable(0, ulCfg.attributeHealthImpactFactors)
        return changed, ulCfg.attributeHealthImpactFactors or {}
    end,
    getAttributeRetroactiveHealthImpactFactors = function ()
        return ulCfg.attributeRetroactiveHealthImpactFactors or {}
    end,
    setAttributeRetroactiveHealthImpactFactors = function(impactFactors)
        if not impactFactors or type(impactFactors) ~= "table" then
            error("Invalid retroactive health impact factors parameter, it has to be a table (attributeId, impactValue)")
        end
        for attrId, impactFactor in pairs(impactFactors) do
            if not core.stats.Attribute.records[attrId] then
                error(string.format("Invalid attribute id \"%s\"", attrId))
            end
            if type(impactFactor) ~= "number" then
                error(string.format("Invalid impact factor value \"%s\"", impactFactor))
            end
        end
        local changed = ulCfg.setAttributeRetroactiveHealthImpactFactors(impactFactors)
        state.attrs.health.base = ulHpr.initNewTable(0, ulCfg.attributeRetroactiveHealthImpactFactors)
        state.attrs.health.start = ulHpr.initNewTable(0, ulCfg.attributeRetroactiveHealthImpactFactors)
        return changed, ulCfg.attributeRetroactiveHealthImpactFactors or {}
    end,

    -- Reset player's profile stats, useful with old game saves or when some stats are broken
    resetStats = function()
        init(false, true)
    end,
}

return {
    engineHandlers = {
        onFrame = function(data) if not state.initialised then return end updateHealth(data) end,
        onUpdate = function()
            if not state.initialised or not Player.isCharGenFinished(self) then return end

            if I.SkillFramework and not customSkillsHandled and next(state.skills.custom) then
                for skillId in pairs(state.skills.custom) do
                    if not registeredCustomSkills[skillId] then
                        return
                    elseif not state.skills.raceMod[skillId] then
                        --setStartSkills(false, false)
                        --updateStats()
                        self:sendEvent(ulDef.events.updateStartSkills, { baseStart = false, clearAll = false })
                        return
                    end
                end
                customSkillsHandled = true
            end

            ulCom.statsBaseUpdateHandler(state)
        end,
        onKeyPress = function(data)
            if not state.initialised then return end

            local isStatsMenu = ulUi.isStatsMenu()

            if data.code == ulSet.globalStorage:get("statsMenuKey") and ulSet.globalStorage:get("statsMenuToggle") and isStatsMenu then
                ulUi.closeStatsMenu()
                return
            end
            if data.code == ulSet.globalStorage:get("statsMenuKey") and not isStatsMenu then
                self:sendEvent(ulDef.events.showStatsMenu, { create = true })
            end
        end,
        onKeyRelease = function(data)
            local isStatsMenu = ulUi.isStatsMenu()

            if data.code == ulSet.globalStorage:get("statsMenuKey") and not ulSet.globalStorage:get("statsMenuToggle") and isStatsMenu then
                ulUi.closeStatsMenu()
            end
        end,
        onLoad = function(data)
            if not data or not state.initialised then
                --ulCom.showMessage(state, "No data found in save game, Ultimate Leveling will be initialised")
                if Player.isCharGenFinished(self) then
                    self:sendEvent(ulDef.events.init, { baseStart = true, clearAll = false })
                end
                return
            elseif data.savedGameVersion ~= ulDef.savedGameVersion then
                updateState(data)
                ulCom.showMessage(state, string.format("Different Ultimate Leveling save game version detected, updated state from v%.1f to v%.1f", data.savedGameVersion, ulDef.savedGameVersion))
            end
            state = data
            ulCom.addHandlers(state)
            self:sendEvent(ulDef.events.updateStartStats, { baseStart = false, clearAll = false })
        end,
        onSave = function() state.savedGameVersion = ulDef.savedGameVersion return state end,
        --onKeyPress = function(data) if not state.initialised then return end ulUi.onKeyPress(data) end,
        --onKeyRelease = ulUi.onKeyRelease,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            if data.newMode == "ChargenClassReview" or state.initialised and chargenUiModes[data.oldMode] then
                init(false, false)
                updateStats()
            end

            if not state.initialised then return end

            if ulSet.levelStorage:get("sleepLevelUp") and sleep.meditate then
                sleepLevelup(data)
            end

            if ulSet.levelStorage:get("trainingLevelCapper") and data.newMode == "Training" then
                trainingLevelCap()
            end
        end,
        [ulDef.events.init] = function(data)
            ulLog("Event fired: " ..  ulDef.events.init)
            init(data.baseStart, data.clearAll)
            if data.baseStart then
                setStartSkills(false, false)
            end
            updateStats()
        end,
        [ulDef.events.updateStartStats] = function(data)
            if not state.initialised then return end

            ulLog("Event fired: " .. ulDef.events.updateStartStats)
            setStartSkills(data.baseStart, data.clearAll)

            if data.baseStart then
                setStartSkills(false, false)
            end
            setStartAttrs(data.clearAll)
            updateStats()
        end,
        [ulDef.events.updateStartSkills] = function(data)
            if not state.initialised then return end

            ulLog("Event fired: " .. ulDef.events.updateStartSkills)
            setStartSkills(data.baseStart, data.clearAll)

            if data.baseStart then
                setStartSkills(false, false)
            end
            updateStats()
        end,
        [ulDef.events.updateStartAttrs] = function(data) if not state.initialised then return end ulLog("Event fired: " .. ulDef.events.updateStartAttrs) setStartAttrs(data) updateAttributes() end,
        [ulDef.events.updateSkillGrowth] = function(data) ulLog("Event fired: " .. ulDef.events.updateSkillGrowth) updateSkillGrowth(data.skillId, data.skillLevel, data.params) end,
        [ulDef.events.updateReputation] = function(data) ulLog("Event fired: " .. ulDef.events.updateReputation) state.attrs.reputation = data.reputation[self.id] if not state.initialised then return end updateAttributes() end,
        [ulDef.events.updateStats] = function() if not state.initialised then return end ulLog("Event fired: " .. ulDef.events.updateStats) updateStats() end,
        [ulDef.events.updateAttributes] = function() if not state.initialised then return end ulLog("Event fired: " .. ulDef.events.updateAttributes) updateAttributes() end,
        [ulDef.events.updateLevel] = function() if not state.initialised then return end ulLog("Event fired: " .. ulDef.events.updateLevel) updateLevel() end,
        [ulDef.events.updateHealth] = function() if not state.initialised then return end ulLog("Event fired: " .. ulDef.events.updateHealth) updateHealthAsked = true end,
        [ulDef.events.updateStatsExtMod] = function(data) ulLog("Event fired: " .. ulDef.events.updateStatsExtMod) updateStatsExtMod(data) end,
        --[ulDef.events.updatePerSkillRenderer] = function(data) ulLog("Event fired: " .. ulDef.events.updatePerSkillRenderer) ulRdr.updatePerSkillRenderer(data) end,
        [ulDef.events.showStatsMenu] = function(data) ulUi.showStatsMenu(state, data) end,
    },
    interfaceName = ulDef.MOD_NAME,
    interface = interface
}
