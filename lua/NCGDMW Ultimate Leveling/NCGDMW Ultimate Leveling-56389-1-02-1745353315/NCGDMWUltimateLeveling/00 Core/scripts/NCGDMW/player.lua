local core = require('openmw.core')
local async = require('openmw.async')
local storage = require('openmw.storage')
local self = require('openmw.self')
local ui = require('openmw.ui')
local Player = require('openmw.types').Player

local mSettings = require('scripts.NCGDMW.settings')
-- Init settings first to init the storage which is used everywhere
mSettings.initSettings()

local log = require('scripts.NCGDMW.log')
local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mCommon = require('scripts.NCGDMW.common')
local mHelpers = require('scripts.NCGDMW.helpers')
local mDecay = require('scripts.NCGDMW.decay')
local mSpells = require('scripts.NCGDMW.spells')
local mSkills = require('scripts.NCGDMW.skills')
local mUi = require("scripts.NCGDMW.ui")

local L = core.l10n(mDef.MOD_NAME)

local state = {
    savedGameVersion = mDef.savedGameVersion,
    chargen = {
        race = nil,
        birthsign = nil,
        name = nil,
        class = nil,
        specialization = nil,
    },
    skills = {
        major = {}, majorOrder = {},
        minor = {}, minorOrder = {},
        misc = {}, miscOrder = {},
        specialization = {},
        race = {},
        start = {},
        base = {},
        progress = mHelpers.initNewTable(0, Player.stats.skills),
        decay = mHelpers.initNewTable(0, Player.stats.skills),
        max = mHelpers.initNewTable(0, Player.stats.skills),
        growth = {
            skill = mHelpers.initNewTable(0, Player.stats.skills),
            level = mHelpers.initNewTable(0, Player.stats.skills),
            attributes = mHelpers.initNewTable(0, Player.stats.skills),
        },
        room = {
            major = 0, minor = 0, misc = 0,
        },
        training = {
            sessions = 0, used = 0,
        },
        books = {
            exp = mHelpers.initNewTable(0, Player.stats.skills),
            totalGain = mHelpers.initNewTable(0, Player.stats.skills),
            skillUp = mHelpers.initNewTable(0, Player.stats.skills),
            read = {}
        },
    },
    attrs = {
        race = {},
        favored = {},
        chargen = {},
        start = {},
        growth = {},
        base = {},
        diffs = mHelpers.initNewTable(0, Player.stats.attributes),
    },
    healthAttrs = {
        start = mHelpers.initNewTable(0, mCfg.retroactiveHealthAttributeFactors),
        retroactive = mHelpers.initNewTable(0, mCfg.retroactiveHealthAttributeFactors),
        health = mHelpers.initNewTable(0, mCfg.healthAttributeFactors),
    },
    decay = {
        lastDecayTime = 0,
        noDecayTime = mCommon.totalGameTimeInHours(),
        noDecayTimeStart = mCommon.totalGameTimeInHours(),
        lastPlayerPos = self.position,
    },
    lvlProg = nil,
    profileId = nil,
    reputation = 0,
    messagesLog = {},
}

local isInitialized = false
local softInitAsked = false
local updateStarterSpellsAsked = false
local updateGrowthAllAttrsAsked = false
local updateGrowthAllAttrsOnResumeAsked = false
local updateStartAttrsOnResumeAsked = false
local updateHealthAsked = false
local lastUpdateHealthTime = 0
local isStarwindMode = mCommon.isStarwindMode()
local chargenUiModes = { ChargenClassReview = true, ChargenBirth = true }

local incompatiblePlugins = {}
for _, plugin in ipairs({ "simpleexpscaling.omwscripts", "MBSP_Uncapper.omwscripts", "MBSP.omwscripts" }) do
    if core.contentFiles.has(plugin) then
        table.insert(incompatiblePlugins, plugin)
    end
end
if #incompatiblePlugins > 0 then
    ui.create(mUi.missingPluginWarning(L("pluginErrorNotCompatible"), incompatiblePlugins))
    return
end

local countPlugins = (core.contentFiles.has("ncgdmw.omwaddon") and 1 or 0)
        + (core.contentFiles.has("ncgdmw_starwind.omwaddon") and 1 or 0)
if countPlugins ~= 1 then
    local plugins = { "ncgdmw.omwaddon", "ncgdmw_starwind.omwaddon" }
    ui.create(mUi.missingPluginWarning(countPlugins == 0 and L("pluginErrorMissingOneOf") or L("pluginErrorTooMany"), plugins))
    return
end

log("OpenMW 0.49.0 detected. Lua API recent enough for all features.")

---- Core Logic ----

local function setStartAttributes()
    -- Compare chargen attribute average value with grown attributes with current settings and chargen skills
    local startAttributesPenalty = mSettings.attributesStorage:get("startAttributesPenalty") or 15
    local luckStartAttributesPenalty = mSettings.attributesStorage:get("luckStartAttributesPenalty") or 0
    for skillId in pairs(Player.stats.skills) do
        mSkills.setSkillGrowths(state, skillId, state.skills.start[skillId])
    end

    for attrId, value in pairs(state.attrs.chargen) do
        if attrId == "luck" then
            state.attrs.start[attrId] = value - luckStartAttributesPenalty
        else
            state.attrs.start[attrId] = value - startAttributesPenalty
        end
    end
end

local function init(clearAll)
    log("NCGDMW Ultimate Leveling INIT begins!")

    mCommon.convertOldSettingValues()
    mCommon.setChargenStats(state)
    setStartAttributes()
    local baseStatsMods = mCommon.getBaseStatsModifiers()

    for attrId, value in pairs(state.attrs.start) do
        state.attrs.base[attrId] = value
        Player.stats.attributes[attrId](self).base = state.attrs.start[attrId] + (baseStatsMods.attributes[attrId] or 0)
        if clearAll or state.attrs.diffs[attrId] == nil then
            state.attrs.diffs[attrId] = 0
        elseif state.attrs.diffs[attrId] ~= 0 then
            log(string.format("Preserving previous \"%s\" external change of %d", attrId, state.attrs.diffs[attrId]))
        end
    end
    state.healthAttrs.health = mHelpers.initNewTable(0, mCfg.healthAttributeFactors)
    state.healthAttrs.retroactive = mHelpers.initNewTable(0, mCfg.retroactiveHealthAttributeFactors)
    state.healthAttrs.start = mHelpers.initNewTable(0, mCfg.retroactiveHealthAttributeFactors)

    for skillId, getter in pairs(Player.stats.skills) do
        -- Max skills shall not include base skill modifiers
        state.skills.max[skillId] = getter(self).base - (baseStatsMods.skills[skillId] or 0)
    end

    if mSettings.skillsStorage:get("skillDecayRate") ~= "skillDecayNone" then
        log(string.format("Decay time initialized to %s", state.decay.noDecayTime))
    end

    if not state.profileId then
        local playerName = Player.record(self).name
        local index = 1
        while (not state.profileId) do
            local profileId = string.format("%s_%s_%d", mDef.MOD_NAME, playerName, index)
            if not storage.playerSection(profileId):get("deathCount") then
                state.profileId = profileId
                storage.playerSection(profileId):set("deathCount", 0)
            end
            index = index + 1
        end
    end

    isInitialized = true

    mSkills.addSkillUsedHandlers(state)
    updateGrowthAllAttrsAsked = true
    updateStarterSpellsAsked = true

    if mSettings.globalStorage:get("showIntro") then
        -- Wait a few seconds, then flash a message to prompt the user to configure the mod
        async:newSimulationTimer(2, async:registerTimerCallback(
                "newGameGreeting",
                function()
                    mCommon.showMessage(state, L("doSettings"))
                    log("NCGDMW Ultimate Leveling INIT has ended!")
                end
        ))
    end
end

local function updateGrowth(allAttrs)
    local attributeGrowthBase = mSettings.attributesStorage:get("attributeGrowthBase") or 0.3
    local baseStatsMods = mCommon.getBaseStatsModifiers()
    local attrsToUpdate = mSkills.updateSkills(state, baseStatsMods, allAttrs)
    local attributesMaxValue = mSettings.attributesStorage:get("uncapperMaxValue")
    local perAttributeMaxValues = mSettings.getPerAttributeMaxValues()

    local function growAttribute(attrId)
        local maxValue = (perAttributeMaxValues[attrId] or attributesMaxValue) + (baseStatsMods.attributes[attrId] or 0)

        -- Update base value in case of manual or uncapper settings changes
        if Player.stats.attributes[attrId](self).base > maxValue then
            mCommon.setStat(state, "attributes", attrId, maxValue)
        end

        -- First check for an external change to the attribute. If found, save it to be reapplied later
        local diff = mCommon.getAttributeDiff(state, attrId, baseStatsMods)

        local growth
        if attrId == "luck" then
            growth = mCommon.getAttributeGrowth(state, attrId, attributeGrowthBase)
            local luckGrowthBase = mSettings.attributesStorage:get("luckReputationGrowthBase") or 0.5
            local growthFactorFromLuckFavoredAttribute = state.attrs.favored[attrId] and mSettings.attributesStorage:get("growthFactorFromLuckFavoredAttribute") or 1
            local exponentRacialAffinity = mSettings.attributesStorage:get("exponentRacialAffinity") or 0
            growth = growth
                + luckGrowthBase
                * state.reputation
                * growthFactorFromLuckFavoredAttribute
                * (state.attrs.race[attrId] / 40 ) ^ exponentRacialAffinity
        else
            -- Calculate growth based on each attribute's related skills
            growth = mCommon.getAttributeGrowth(state, attrId, attributeGrowthBase)
        end
        local value = growth
                -- Add chargen values
                + state.attrs.start[attrId]
                -- Add external changes
                + diff
                -- Add base modifiers
                + (baseStatsMods.attributes[attrId] or 0)
        value = math.max(5, math.min(value, maxValue))

        mCommon.setStat(state, "attributes", attrId, value)
    end

    -- Look at each attribute, determine if it should be recalculated based on its related skills
    for attrId, _ in pairs(attrsToUpdate) do
        growAttribute(attrId)
    end

    -- if at least on skill has changed
    if next(attrsToUpdate) ~= nil then
        updateHealthAsked = true

        local totalLevel = mCommon.getTotalPlayerLevel(state)

        state.lvlProg = math.floor(totalLevel % 1 * 100)
        local newLevel = math.max(1, math.floor(totalLevel))

        local currentLevel = Player.stats.level(self).current

        growAttribute("luck")

        if newLevel ~= currentLevel then
            if newLevel > currentLevel then
                mCommon.showMessage(state, L("lvlUp", { level = newLevel }))
            elseif newLevel < currentLevel then
                mCommon.showMessage(state, L("lvlDown", { level = newLevel }))
            end

            Player.stats.level(self).current = newLevel
        end
    end

    if updateStarterSpellsAsked then
        updateStarterSpellsAsked = false
        mSpells.updateStarterSpells()
    end

    state.skills.training.sessions = math.max(0, mSettings.skillsStorage:get("capSkillTrainingLevelValue") * Player.stats.level(self).current - state.skills.training.used)

    mCommon.showModStatMessages(state)
end

local function updateHealth(deltaTime)
    local baseStatsMods = mCommon.getBaseStatsModifiers()
    lastUpdateHealthTime = lastUpdateHealthTime + (deltaTime or 0.5)
    if lastUpdateHealthTime < 0.5 then return end
    lastUpdateHealthTime = 0

    local recalculate = false
    for attribute, value in pairs(state.healthAttrs.health) do
        local current = Player.stats.attributes[attribute](self).modified
        if current ~= value then
            state.healthAttrs.health[attribute] = current
            recalculate = true
        end
    end
    for attribute, value in pairs(state.healthAttrs.retroactive) do
        local current = Player.stats.attributes[attribute](self).base
        if current ~= value then
            state.healthAttrs.retroactive[attribute] = current
            recalculate = true
        end
    end
    for attribute, value in pairs(state.healthAttrs.start) do
        local current = state.attrs.start[attribute] + (baseStatsMods.attributes[attribute] or 0)
        if current ~= value then
            state.healthAttrs.start[attribute] = current
            recalculate = true
        end
    end
    if recalculate or updateHealthAsked then
        updateHealthAsked = false
        local healthFactor = mCommon.getHealthFactor(state)
        local healthMultiplier = mSettings.healthStorage:get("healthMultiplier") or 1
        local currentLevel = Player.stats.level(self).current
        local retroactiveHealthFactor = mCommon.getRetroactiveHealthFactor(state)
        local retroactiveHealthMultiplier = mSettings.healthStorage:get("retroactiveHealthMultiplier") or 0.05
        local maxHealth = math.floor(healthFactor * healthMultiplier
                + (currentLevel - 1) * retroactiveHealthFactor * retroactiveHealthMultiplier
                + mCommon.getMaxHealthModifier())
        local health = Player.stats.dynamic.health(self)
        local ratio = health.current / health.base
        health.base = maxHealth
        health.current = ratio * maxHealth
    end
end

local function onFrame(deltaTime)
    if not isInitialized then return end
    if updateGrowthAllAttrsAsked then
        updateGrowthAllAttrsAsked = false
        updateGrowth(true)
    end
    mDecay.onFrame(state, deltaTime)
    updateHealth(deltaTime)
end

local function onUpdate()
    if softInitAsked or (not isInitialized and not isStarwindMode and Player.isCharGenFinished(self)) then
        softInitAsked = false
        init(false)
    end

    if not isInitialized then return end

    if updateStartAttrsOnResumeAsked then
        updateStartAttrsOnResumeAsked = false
        mCommon.setChargenStats(state)
        setStartAttributes()
        updateGrowthAllAttrsOnResumeAsked = true
    end
    if updateGrowthAllAttrsOnResumeAsked then
        updateGrowthAllAttrsOnResumeAsked = false
        updateGrowth(true)
        updateHealthAsked = true
    end
end

local function uiModeChanged(data)
    --log(string.format('UI mode changed from %s to %s (%s)', data.oldMode, data.newMode, data.arg))
    if chargenUiModes[data.oldMode] then
        softInitAsked = true
        isInitialized = false
    end

    if not isInitialized then return end

    mDecay.onUiModeChanged(state, data)
    mSkills.capTrainedSkills(state, data)
    mSkills.skillBooks(state, data)
end

local function showStatsMenu(data)
    mDecay.updateDecay(state)
    updateGrowth(true)
    updateHealth()
    mUi.showStatsMenu(state, data)
end

local function onLoad(data)
    mCommon.convertOldSettingValues()

    if not data then
        mCommon.showMessage(state, "No data found in save game, NCGDMW Ultimate Leveling will be initialized")
        return
    end

    if data.savedGameVersion == mDef.savedGameVersion then
        state = data
        isInitialized = true
        updateGrowthAllAttrsAsked = true
        mSkills.addSkillUsedHandlers(state)
        return
    end

    softInitAsked = true
    mCommon.migrateOldSettings(data.savedGameVersion)
    if mCommon.upgradeOldState(state, data) then
        state = data
    end
    mCommon.showMessage(state, string.format("Old NCGDMW game save detected, upgraded from v%.2f to v%.2f", data.savedGameVersion, mDef.savedGameVersion))
end

local function onSave()
    state.savedGameVersion = mDef.savedGameVersion
    return state
end

-- Public interface

local interface = {
    version = mDef.interfaceVersion,
    GetState = function() return state end,
    -- Get an attribute value, also set it if value is not nil
    Attribute = function(attrId, value)
        if attrId == nil or Player.stats.attributes[attrId] == nil then
            error(string.format("Invalid attribute id \"%s\""), attrId)
        end
        local changed = false
        if value ~= nil then
            local numValue = tonumber(value)
            if numValue == nil or numValue < 0 then
                error(string.format("Invalid attribute value \"%s\""), value)
            end
            changed = mCommon.setStat(state, "attributes", attrId, numValue)
        end
        return changed, mCommon.getStat("attributes", attrId)
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
            changed = mCommon.setStat(state, "skills", skillId, numValue)
            state.skills.max[skillId] = numValue
            state.skills.decay[skillId] = 0
        end
        return changed, mCommon.getStat("skills", skillId)
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
            changed = state.skills.progress[skillId] ~= value
            state.skills.progress[skillId] = value
            Player.stats.skills[skillId](self).progress = value
        end
        return changed, state.skills.progress[skillId]
    end,
    -- Get skill affected attributes, also set them if attrImpacts is set (map attributeId -> impactValue)
    SkillAffectedAttributes = function(skillId, attrImpacts)
        if skillId == nil or Player.stats.skills[skillId] == nil then
            error(string.format("Invalid skill id \"%s\"", skillId))
        end
        if attrImpacts == nil then
            return mCfg.skillsImpactOnAttributes[skillId]
        end
        if type(attrImpacts) ~= "table" then
            error("Invalid attribute impacts parameter, it has to be a map (attributeId, impactValue)")
        end
        for attrId, value in pairs(attrImpacts) do
            if not core.stats.Attribute.records[attrId] then
                error(string.format("Invalid attribute id \"%s\"", attrId))
            end
            if type(value) ~= "number" then
                error(string.format("Invalid attribute value \"%s\"", value))
            end
        end
        mCfg.setSkillsImpactOnAttributes(skillId, attrImpacts)
        setStartAttributes()
        updateGrowthAllAttrsOnResumeAsked = true
    end,
    -- Get player level process value
    LevelProgress = function(raw)
        if raw then
            return state.lvlProg
        else
            return tostring(state.lvlProg) .. "%"
        end
    end,
    -- Get player no decay time value (total time in hours without decay)
    NoDecayTime = function()
        return state.decay.noDecayTime
    end,
    -- Reset player's profile stats, useful with old game saves or when some stats are broken
    ResetStats = function()
        init(true)
    end,
}

local function onPlayerDeath()
    local count = storage.playerSection(state.profileId):get("deathCount")
    storage.playerSection(state.profileId):set("deathCount", count + 1)
end

local function onPlayerReputationUpdated(data)
    state.reputation = data.reputation[self.id]
    updateGrowthAllAttrsOnResumeAsked = true
end

return {
    engineHandlers = {
        onFrame = onFrame,
        onUpdate = onUpdate,
        onKeyPress = function(key) if isInitialized then mUi.onKeyPress(key) end end,
        onKeyRelease = mUi.onKeyRelease,
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        Died = onPlayerDeath,
        [mDef.events.applySkillUsedHandlers] = function(data) mSkills.applySkillUsedHandlers(data.skillId, data.params, data.afterHandler) end,
        [mDef.events.updateGrowth] = function() updateGrowth(false) end,
        [mDef.events.updateGrowthAllAttrs] = function() updateGrowthAllAttrsAsked = isInitialized end,
        [mDef.events.updateGrowthAllAttrsOnResume] = function() updateGrowthAllAttrsOnResumeAsked = isInitialized end,
        [mDef.events.updateStartAttrsOnResume] = function() updateStartAttrsOnResumeAsked = isInitialized end,
        [mDef.events.showStatsMenu] = showStatsMenu,
        [mDef.events.refreshDecay] = function() if isInitialized then mDecay.logDecayTime(state) end end,
        [mDef.events.playerReputation] = onPlayerReputationUpdated,
    },
    interfaceName = mDef.MOD_NAME,
    interface = interface
}
