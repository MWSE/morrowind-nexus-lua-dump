local core = require('openmw.core')
local async = require('openmw.async')
local self = require('openmw.self')
local ui = require('openmw.ui')
local Player = require('openmw.types').Player
local aux_util = require('openmw_aux.util')

local S = require('scripts.NCGDMW.settings')
-- Init settings first to init storage which is used everywhere
S.initSettings()

local log = require('scripts.NCGDMW.log')
local def = require('scripts.NCGDMW.definition')
local cfg = require('scripts.NCGDMW.configuration')
local C = require('scripts.NCGDMW.common')
local H = require('scripts.NCGDMW.helpers')
local ncgdUI = require("scripts.NCGDMW.ui")
local decay = require('scripts.NCGDMW.decay')
local spellHelper = require('scripts.NCGDMW.spells')
local skillHandlers = require('scripts.NCGDMW.skill-handlers')

local L = core.l10n(def.MOD_NAME)

local isDisabled = false
local interfaceVersion = 4
local savedGameVersion = 3.6
local baseTotalStats
local lvlProg = 0
local healthAttributes = H.initNewTable(0, cfg.healthAttributeFactors)
local forceUpdateHealth = false
local lastUpdateHealthTime = 0
local resetStatsAsked = false
local updateStarterSpellsAsked = false
local updatePlayerStatsAsked = false
local updateProfileOnUpdateAsked = false

local countPlugins = (core.contentFiles.has("ncgdmw.omwaddon") and 1 or 0)
        + (core.contentFiles.has("ncgdmw_alt_start.omwaddon") and 1 or 0)
        + (core.contentFiles.has("ncgdmw_starwind.omwaddon") and 1 or 0)
if countPlugins ~= 1 then
    local plugins = { "ncgdmw.omwaddon", "ncgdmw_alt_start.omwaddon", "ncgdmw_starwind.omwaddon" }
    ui.create(ncgdUI.missingPluginWarning(countPlugins == 0 and L("pluginErrorMissingOneOf") or L("pluginErrorTooMany"), plugins))
    return
end
if core.contentFiles.has("MBSP_Uncapper.omwscripts") then
    ui.create(ncgdUI.missingPluginWarning(L("pluginErrorNotCompatible"), { "MBSP_Uncapper.omwscripts" }))
    return
end
if core.contentFiles.has("MBSP.omwscripts") then
    ui.create(ncgdUI.missingPluginWarning(L("pluginErrorNotCompatible"), { "MBSP.omwscripts" }))
    return
end

if core.contentFiles.has("ncgdmw_starwind.omwaddon") then
    print(L("autoStarwind"))
    S.globalStorage:set("starwindNames", true)
end

log("OpenMW 0.49.0 detected. Lua API recent enough for all features.")

---- Core Logic ----

local function getAttributesToRecalculate(baseStatsMods, forceAll)
    local recalculate = {}
    local decayEnabled = S.skillsStorage:get("decayRate") ~= "none"
    local skillsMaxValue = S.skillsStorage:get("uncapperMaxValue")
    local perSkillMaxValues = S.getPerSkillMaxValues()

    for skillId, getter in pairs(Player.stats.skills) do
        local maxValue = perSkillMaxValues[skillId] or skillsMaxValue

        -- Update base and max values in case of manual or uncapper settings changes
        if getter(self).base > maxValue then
            C.setStat("skills", skillId, maxValue)
        end
        C.maxSkills()[skillId] = math.min(C.maxSkills()[skillId], maxValue)

        local actualBase = getter(self).base - (baseStatsMods.skills[skillId] or 0)
        if not decayEnabled or actualBase > C.maxSkills()[skillId] then
            C.maxSkills()[skillId] = actualBase
        end

        local storedBase = C.baseSkills()[skillId]

        if forceAll or storedBase ~= actualBase then
            if storedBase ~= actualBase then
                if storedBase ~= nil then
                    log(string.format("Skill \"%s\" has changed from %s to %.2f", skillId, storedBase, actualBase))
                end
                if (storedBase == nil or actualBase > storedBase) and decayEnabled then
                    C.slowDownSkillDecayOnSkillLevelUp(skillId)
                end
            end
            C.baseSkills()[skillId] = actualBase
            local affected = cfg.skillsImpactOnAttributes[skillId]
            if affected then
                for attributeId, _ in pairs(affected) do
                    --log(string.format("\"%s\" should be recalculated!", attributeId))
                    recalculate[attributeId] = true
                end
            end
        end
    end
    return recalculate
end

local function attributeDiff(attributeId, baseStatsMods)
    -- Try to see if something else has modified an attribute and preserve that difference.
    local diff = C.attributeDiffs()[attributeId]
            + Player.stats.attributes[attributeId](self).base
            - (baseStatsMods.attributes[attributeId] or 0)
            - C.baseAttributes()[attributeId]
    if diff ~= C.attributeDiffs()[attributeId] then
        log(string.format("Detected external change %d for \"%s\", base is %d, stored base is %d",
                diff, attributeId, Player.stats.attributes[attributeId](self).base, C.baseAttributes()[attributeId]))
    end
    C.attributeDiffs()[attributeId] = diff
    return diff
end

local function updateStarterSpells()
    local baseSpellIds = spellHelper.getPlayerInnateSpellIds(self)
    for _, spell in pairs(Player.spells(self)) do
        if spell.starterSpellFlag and not baseSpellIds[spell.id] then
            Player.spells(self):remove(spell.id)
            log(string.format("Removed existing starter spell: %s", spell.id))
        end
    end

    local starterSpells = spellHelper.autoCalcPlayerSpells(self)
    for _, spellId in ipairs(starterSpells) do
        Player.spells(self):add(spellId)
        log(string.format("Added starter spell: %s", spellId))
    end
end

local function updatePlayerStats(forceUpdateAttributes)
    local growthRateNum = S.getAttributeGrowthRates(S.attributesStorage:get("growthRate"))
    local baseStatsMods = C.getBaseStatsModifiers()
    local toRecalculate = getAttributesToRecalculate(baseStatsMods, forceUpdateAttributes)
    local attributesChanged = false
    local attributesMaxValue = S.attributesStorage:get("uncapperMaxValue")
    local perAttributeMaxValues = S.getPerAttributeMaxValues()

    -- Look at each attribute, determine if it should be recalculated based on its related skills
    for attributeId, _ in pairs(toRecalculate) do
        local getter = Player.stats.attributes[attributeId]
        local maxValue = perAttributeMaxValues[attributeId] or attributesMaxValue

        -- Update base value in case of manual or uncapper settings changes
        if getter(self).base > maxValue then
            C.setStat("attributes", attributeId, maxValue)
        end

        -- First check for an external change to the attribute. If found, save it to be reapplied later
        local diff = attributeDiff(attributeId, baseStatsMods)

        -- Calculate XP based on each attribute's related skills
        local total = 0
        for skillId, attributes in pairs(cfg.skillsImpactOnAttributes) do
            local impactFactor = attributes[attributeId]
            if impactFactor then
                total = total + (C.baseSkills()[skillId] ^ 2) * impactFactor
            end
        end

        total = math.floor(math.sqrt(total * growthRateNum / 27)
                + C.startAttributes()[attributeId])
                + diff
                + (baseStatsMods.attributes[attributeId] or 0)
        total = math.min(total, maxValue)

        -- If the attribute has changed, signal to recalculate LUCK
        local changed = C.setStat("attributes", attributeId, total)
        if changed then
            attributesChanged = true
        end
    end

    if next(toRecalculate) ~= nil then
        -- Recalculate level progress
        local totalStats = 0
        for _, value in pairs(C.baseSkills()) do
            totalStats = totalStats + value ^ 2
        end
        local totalLevel = math.sqrt(totalStats * 2 / 27)

        local currentLevel = Player.stats.level(self).current
        if baseTotalStats == nil then
            -- First stats update, we preserve player level and level progression
            baseTotalStats = totalLevel - currentLevel - Player.stats.level(self).progress / core.getGMST("iLevelupTotal")
        end
        totalLevel = totalLevel - baseTotalStats

        lvlProg = math.floor(totalLevel % 1 * 100)
        local newLevel = math.floor(totalLevel)

        if newLevel ~= currentLevel then
            forceUpdateHealth = true
        end

        -- Something changed, show a message to the player
        if newLevel > 0 then
            if newLevel > currentLevel then
                C.showMessage(L("lvlUp", { level = newLevel }))
            elseif newLevel < currentLevel then
                C.showMessage(L("lvlDown", { level = newLevel }))
            end
            Player.stats.level(self).current = newLevel
        end

        if attributesChanged then
            local diff = attributeDiff("luck", baseStatsMods)
            if diff > 0 then
                log(string.format("Adding external change for Luck: %d", diff))
            end
            local newLuck = math.floor(math.sqrt(totalStats * growthRateNum / 27)
                    + C.startAttributes().luck)
                    + diff
                    + (baseStatsMods.attributes.luck or 0)
            C.setStat("attributes", "luck", newLuck)
        end
    end

    if updateStarterSpellsAsked then
        updateStarterSpellsAsked = false
        updateStarterSpells()
    end
end

local function getHealthFactor(attributes)
    local baseHPRatio = S.attributesStorage:get("baseHPRatio")
    local factor = baseHPRatio ~= "full" and S.getBaseHPRatioFactor(baseHPRatio) or 1
    local attributeFactor = 0
    for attributeId, value in pairs(cfg.healthAttributeFactors) do
        attributeFactor = attributeFactor + attributes[attributeId] * value
    end
    return factor * attributeFactor
end

local function doHealth(deltaTime)
    lastUpdateHealthTime = lastUpdateHealthTime + (deltaTime or 0.5)
    if lastUpdateHealthTime < 0.5 then return end
    lastUpdateHealthTime = 0

    local recalculate = false
    local stateBasedHP = S.attributesStorage:get("stateBasedHP")
    for attribute, value in pairs(healthAttributes) do
        local current
        if stateBasedHP then
            current = Player.stats.attributes[attribute](self).modified
        else
            current = Player.stats.attributes[attribute](self).base
        end
        if current ~= value then
            healthAttributes[attribute] = current
            recalculate = true
        end
    end
    if recalculate or forceUpdateHealth then
        local hpGainRatio = 10
        if S.attributesStorage:get("perLevelHPGain") == "low" then
            hpGainRatio = 20
        end
        forceUpdateHealth = false
        local currentLevel = Player.stats.level(self).current
        local maxHealth = math.floor(getHealthFactor(healthAttributes)
                + (currentLevel - 1) * getHealthFactor(healthAttributes) / hpGainRatio
                + C.getMaxHealthModifier())
        local health = Player.stats.dynamic.health(self)
        local ratio = health.current / health.base
        health.base = maxHealth
        health.current = ratio * maxHealth
    end
end

local function updateHealth()
    forceUpdateHealth = true
end

local function init(clearAll)
    log("NCGDMW Lua Edition INIT begins!")

    C.init()

    local attributes = {}
    -- Get race attributes and class specialized attributes to improve initialization on existing games
    local playerRecord = Player.record(self)
    local specAttributes = {}
    for _, attributeId in ipairs(Player.classes.record(playerRecord.class).attributes) do
        specAttributes[attributeId] = true
    end
    for attributeId, value in pairs(Player.races.record(playerRecord.race).attributes) do
        attributes[attributeId] = (playerRecord.isMale and value.male or value.female) + (specAttributes[attributeId] and 10 or 0)
    end
    baseTotalStats = nil

    local baseStatsMods = C.getBaseStatsModifiers()

    for attributeId, value in pairs(attributes) do
        C.baseAttributes()[attributeId] = value
        C.startAttributes()[attributeId] = value / 2
        Player.stats.attributes[attributeId](self).base = C.baseAttributes()[attributeId] + (baseStatsMods.attributes[attributeId] or 0)
        if clearAll or C.attributeDiffs()[attributeId] == nil then
            C.attributeDiffs()[attributeId] = 0
        elseif C.attributeDiffs()[attributeId] ~= 0 then
            log(string.format("Preserving previous \"%s\" external change of %d", attributeId, C.attributeDiffs()[attributeId]))
        end
        healthAttributes = H.initNewTable(0, cfg.healthAttributeFactors)
    end

    for skillId, getter in pairs(Player.stats.skills) do
        -- Base skills will be set in getAttributesToRecalculate. Set to nil to detect the new value and update attributes accordingly
        C.baseSkills()[skillId] = nil
        -- Max skills shall not include base skill modifiers
        C.maxSkills()[skillId] = getter(self).base - (baseStatsMods.skills[skillId] or 0)
    end

    decay.init()

    C.setCharGenDone(true)

    updatePlayerStatsAsked = true
    updateStarterSpellsAsked = true
    skillHandlers.addSkillUsedHandlers()

    if S.globalStorage:get("showIntro") then
        -- Wait a few seconds, then flash a message to prompt the user to configure the mod
        async:newSimulationTimer(
                2,
                async:registerTimerCallback(
                        "newGameGreeting",
                        function()
                            C.showMessage(L("doSettings"))
                            log("NCGDMW Lua Edition INIT has ended!")
                        end
                )
        )
    end
end

local function resetStats(clearAll)
    log("Resetting abilities...")
    for _, activeSpell in pairs(Player.activeSpells(self)) do
        if not activeSpell.fromEquipment then
            log(string.format("Clearing active spell \"%s\"", activeSpell.name))
            Player.activeSpells(self):remove(activeSpell.id)
        end
    end
    for _, spell in pairs(Player.spells(self)) do
        if spell.type == core.magic.SPELL_TYPE.Ability or spell.type == core.magic.SPELL_TYPE.Curse then
            log(string.format("Removing ability spell \"%s\"", spell.name))
            Player.spells(self):remove(spell.id)
        end
    end
    local spellIds = {}
    local birthSign = Player.birthSigns.record(Player.getBirthSign(self))
    if birthSign ~= nil then
        for _, spellId in pairs(birthSign.spells) do
            table.insert(spellIds, spellId)
        end
    end
    local race = Player.races.record(Player.record(self).race)
    for _, spellId in pairs(race.spells) do
        table.insert(spellIds, spellId)
    end
    for _, spellId in ipairs(spellIds) do
        local spell = core.magic.spells.records[spellId]
        if spell.type == core.magic.SPELL_TYPE.Ability then
            log(string.format("Adding ability \"%s\"", spell.name))
            Player.spells(self):add(spell.id)
        end
    end

    -- Wait a short time in order to abilities reset to take effect
    -- Using 2 different callbacks as we cannot pass a variable to them
    if clearAll then
        async:newSimulationTimer(
                1,
                async:registerTimerCallback(
                        "initHardNCGD",
                        function()
                            init(true)
                        end
                )
        )
    else
        async:newSimulationTimer(
                1,
                async:registerTimerCallback(
                        "initSoftNCGD",
                        function()
                            init(false)
                        end
                )
        )
    end
end

local function onFrame(deltaTime)
    if isDisabled or not C.charGenDone() then return end
    -- This is a hack to see if we're far enough along in CharGen to have stats
    -- Main loop
    if updatePlayerStatsAsked then
        updatePlayerStatsAsked = false
        updatePlayerStats(true)
    end
    decay.onFrame(deltaTime)
    doHealth(deltaTime)
end

local function onUpdate()
    if updateProfileOnUpdateAsked then
        updateProfileOnUpdateAsked = false
        if C.charGenDone() then
            updatePlayerStats(true)
            updateHealth()
        end
    end
end

local function uiModeChanged(data)
    if not C.charGenDone()
            and data.oldMode == "ChargenClassReview"
            and data.newMode == nil
    then
        init(true)
    end

    skillHandlers.onUiModeChanged(data)
    decay.onUiModeChanged(data)
end

local function onActive()
    if resetStatsAsked then
        resetStatsAsked = false
        resetStats(false)
    end
end

local function onLoad(data)
    log(string.format("Loaded saved game data:\n%s", aux_util.deepToString(data, 5)))
    if not data then
        C.setCharGenDone(true)
        return
    end
    cfg.updateConfig(data.configuration or {})
    baseTotalStats = data.baseTotalStats
    lvlProg = data.lvlProg
    healthAttributes = data.healthAttributes or healthAttributes
    C.onLoad(data)
    decay.onLoad(data)
    local isDataMissing = not C.charGenDone() or C.baseSkills() == nil or C.baseAttributes() == nil or C.startAttributes() == nil
    if data.savedGameVersion == nil or data.savedGameVersion < 3.4 then
        if S.attributesStorage:get("uncapperMaxValue") then
            S.attributesStorage:set("uncapperMaxValue", 1000)
        else
            S.attributesStorage:set("uncapperMaxValue", 100)
        end
        if S.skillsStorage:get("uncapperMaxValue") then
            S.skillsStorage:set("uncapperMaxValue", 1000)
        else
            S.skillsStorage:set("uncapperMaxValue", 100)
        end
        return
    end
    -- Saved games before 3.2 (no version) need a reset as storage values have changed
    -- Saved games from 3.2 need a reset because of a bug on baseTotalStats not properly reset
    if data.savedGameVersion == nil or data.savedGameVersion < 3.3 or isDataMissing then
        resetStatsAsked = true
        return
    end
    updatePlayerStatsAsked = true
    if C.charGenDone() then
        skillHandlers.addSkillUsedHandlers()
    end
end

local function onSave()
    local data = {
        savedGameVersion = savedGameVersion,
        configuration = cfg.getData(),
        baseTotalStats = baseTotalStats,
        lvlProg = lvlProg,
        healthAttributes = healthAttributes,
    }
    C.onSave(data)
    decay.onSave(data)
    return data
end

-- Public interface

local interface = {
    version = interfaceVersion,
    -- Get an attribute value, also set it if value is not nil
    Attribute = function(attributeId, value)
        if attributeId == nil or Player.stats.attributes[attributeId] == nil then
            error(string.format("Invalid attribute id \"%s\""), attributeId)
        end
        local changed = false
        if value ~= nil then
            local numValue = tonumber(value)
            if numValue == nil or numValue < 0 then
                error(string.format("Invalid attribute value \"%s\""), value)
            end
            changed = C.setStat("attributes", attributeId, numValue)
        end
        return changed, C.getStat("attributes", attributeId)
    end,
    -- Get a skill value, also set it if value is not nil
    Skill = function(skillId, value)
        if skillId == nil or Player.stats.skills[skillId] == nil then
            error(string.format("Invalid skill id \"%s\""), skillId)
        end
        local changed = false
        if value ~= nil then
            local numValue = tonumber(value)
            if numValue == nil or numValue < 0 then
                error(string.format("Invalid skill value \"%s\""), value)
            end
            changed = C.setStat("skills", skillId, numValue)
            C.maxSkills()[skillId] = numValue
            C.decaySkills()[skillId] = 0
        end
        return changed, C.getStat("skills", skillId)
    end,
    -- Get a skill progress value, also set it if value is not nil
    SkillProgress = function(skillId, value)
        if skillId == nil or Player.stats.skills[skillId] == nil then
            error(string.format("Invalid skill id \"%s\""), skillId)
        end
        local changed = false
        if value ~= nil then
            local numValue = tonumber(value)
            if numValue == nil or numValue < 0 or numValue >= 1 then
                error(string.format("Invalid skill progress value \"%s\", it must be between 0 and 1"), value)
            end
            changed = C.skillProgress()[skillId] ~= value
            C.skillProgress()[skillId] = value
            Player.stats.skills[skillId](self).progress = value
        end
        return changed, C.skillProgress()[skillId]
    end,
    -- Get skill affected attributes, also set them if primaryAttrId, secondaryAttrId and tertiaryAttrId are not nil
    SkillAffectedAttributes = function(skillId, primaryAttrId, secondaryAttrId, tertiaryAttrId)
        if skillId == nil or Player.stats.skills[skillId] == nil then
            error(string.format("Invalid skill id \"%s\"", skillId));
        end
        if primaryAttrId == nil and secondaryAttrId == nil and tertiaryAttrId == nil then
            return false, cfg.skillsImpactOnAttributes[skillId]
        end
        if primaryAttrId == nil or Player.stats.attributes[primaryAttrId] == nil then
            error(string.format("Invalid primary attribute id \"%s\"", primaryAttrId));
        end
        if secondaryAttrId == nil or Player.stats.attributes[secondaryAttrId] == nil then
            error(string.format("Invalid secondary attribute id \"%s\"", secondaryAttrId));
        end
        if tertiaryAttrId == nil or Player.stats.attributes[tertiaryAttrId] == nil then
            error(string.format("Invalid tertiary attribute id \"%s\"", tertiaryAttrId));
        end
        if primaryAttrId == secondaryAttrId or primaryAttrId == tertiaryAttrId or secondaryAttrId == tertiaryAttrId then
            error("Affected attributes must be different.");
        end
        if primaryAttrId == "luck" or secondaryAttrId == "luck" or tertiaryAttrId == "luck" then
            error("Luck cannot be set as an affected attribute.");
        end
        local changed = cfg.setSkillsImpactOnAttributes(skillId, primaryAttrId, secondaryAttrId, tertiaryAttrId)
        return changed, cfg.skillsImpactOnAttributes[skillId]
    end,
    -- Get player level process value
    LevelProgress = function(raw)
        if raw then
            return lvlProg
        else
            return tostring(lvlProg) .. "%"
        end
    end,
    -- Get player no decay time value (total time in hours without decay)
    NoDecayTime = function()
        print(decay.noDecayTime())
    end,
    -- Reset player's profile stats, useful with game saved before NCGDMW 3.2 or when some stats are broken
    ResetStats = function()
        resetStats(true)
    end,
}

local function showStatsMenu(data)
    decay.updateDecay()
    updatePlayerStats(true)
    doHealth()
    ncgdUI.showStatsMenu(data)
end

return {
    engineHandlers = {
        onFrame = onFrame,
        onUpdate = onUpdate,
        onKeyPress = ncgdUI.onKeyPress,
        onKeyRelease = ncgdUI.onKeyRelease,
        onLoad = onLoad,
        onSave = onSave,
        onActive = onActive,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        [def.events.applySkillUsedHandlers] = function(data) skillHandlers.applySkillUsedHandlers(data.skillId, data.params, data.afterHandler) end,
        [def.events.updatePlayerStats] = function() updatePlayerStats(false) end,
        [def.events.updatePlayerStatsOnFrame] = function() updatePlayerStatsAsked = true end,
        [def.events.updateProfileOnUpdate] = function() updateProfileOnUpdateAsked = true end,
        [def.events.showStatsMenu] = showStatsMenu,
        [def.events.refreshDecay] = function() decay.logDecayTime() end,
    },
    interfaceName = def.MOD_NAME,
    interface = interface
}
