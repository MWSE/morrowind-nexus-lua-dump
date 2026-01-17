local core = require('openmw.core')
local async = require('openmw.async')
local storage = require('openmw.storage')
local input = require("openmw.input")
local self = require('openmw.self')
local T = require('openmw.types')
local I = require("openmw.interfaces")
local util = require('openmw.util')

-- Settings first to init the storage which is used everywhere
local mS = require('scripts.NCG.config.settings')
mS.initPlayerSettings()
local log = require('scripts.NCG.util.log')
local mDef = require('scripts.NCG.config.definition')
local mCfg = require('scripts.NCG.config.configuration')
local mCompat = require('scripts.NCG.config.compatibility')

if not mCompat.check(
        {
            "ncgdmw.omwscripts", "ncgdmw.omwaddon", "ncgdmw_starwind.omwaddon",
            "PotentialCharacterProgression.omwscripts", "ImprovedVanillaLeveling.omwscripts",
        },
        { "StatsWindow.omwscripts", "StatsWindow.ESP" },
        { "ncg.omwaddon", "ncg_starwind.omwaddon" }
) then return end

local mCore = require('scripts.NCG.util.core')
local mC = require('scripts.NCG.common')
local mH = require('scripts.NCG.util.helpers')
local mSpells = require('scripts.NCG.util.spells')
local mSkills = require('scripts.NCG.skills')
local mWindows = require("scripts.NCG.ui.windows")
local mStatsUi = require('scripts.NCG.ui.stats')

local L = core.l10n(mDef.MOD_NAME)

local state = {
    savedGameVersion = mDef.savedGameVersion,
    isInitialized = false,
    profileId = nil,
    isCRELMode = false,
    skills = {
        major = {}, minor = {}, misc = {},
        start = {},
        base = {},
        growth = {
            level = mH.initNewTable(0, T.NPC.stats.skills),
            attributes = mH.initNewTable(0, T.NPC.stats.skills),
        },
    },
    attrs = {
        chargen = {},
        start = {},
        base = {},
        progress = mH.initNewTable(0, T.Actor.stats.attributes),
        diffs = mH.initNewTable(0, T.Actor.stats.attributes),
        normValue = 0,
    },
    level = {
        value = 1,
        prog = 0,
        skillUps = 0,
        skillUpsPerLevel = mS.globalStorage:get("classSkillPointsPerLevelUp"),
    },
    healthAttrs = mH.initNewTable(0, mCfg.healthAttributeFactors),
    messagesLog = {},
    bitterCup = { object = nil, attrSave = nil },
}

local requests = {}
local isSetupDone = false
local gamePaused = false
local lastUpdateHealthTime = 0
local isStarwindMode = mCore.isStarwindMode()
local CRELCells = { ["CREL Start"] = true, ["AB2 Start"] = true }
local chargenUiModes = { ChargenClassReview = true, ChargenClassPick = true, ChargenRace = true, ChargenBirth = true }

---- Core Logic ----

local function setStartAttributes()
    -- Compare chargen attribute average value with grown attributes with current settings and chargen skills
    local startValuesRatio = mS.getAttributeStartValuesRatio()
    local luckGrowthRate = mS.getLuckGrowthRate()
    local baseSkillMods = mC.getBaseStatMods().skill
    for skillId in pairs(T.NPC.stats.skills) do
        mSkills.setSkillGrowths(state, skillId, state.skills.start[skillId], startValuesRatio, luckGrowthRate, baseSkillMods)
    end
    local growthRateNum, growthRate = mS.getAttributeGrowthRate()
    local chargenAttrSum, alteredAttrSum = 0, 0
    for attrId, value in pairs(state.attrs.chargen) do
        if attrId ~= "luck" then
            chargenAttrSum = chargenAttrSum + value
            alteredAttrSum = alteredAttrSum + value * startValuesRatio + mC.getAttributeGrowth(state, attrId, growthRateNum)
        end
    end
    -- -1 to remove luck
    local startAttrAvg = mH.avg(chargenAttrSum, (#core.stats.Attribute.records - 1))
    local alteredAttrAvg = mH.avg(alteredAttrSum, (#core.stats.Attribute.records - 1))
    state.attrs.normValue = util.round(startAttrAvg - alteredAttrAvg)
    log(string.format("Attribute averages (growth %s, start ratio %.1f): Start values = %.1f, grown values with current settings and chargen skills = %.1f, diff = %.1f",
            L(growthRate), startValuesRatio, startAttrAvg, alteredAttrAvg, state.attrs.normValue))

    for attrId, value in pairs(state.attrs.chargen) do
        if attrId == "luck" then
            state.attrs.start[attrId] = state.attrs.chargen[attrId]
        else
            local start = math.max(5, util.round(value * startValuesRatio + state.attrs.normValue))
            state.attrs.start[attrId] = start
        end
    end
end

local function initProfileId()
    local playerName = T.Player.record(self).name
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

local function setup()
    if isSetupDone then return end
    isSetupDone = true
    mStatsUi.setStatsWindow(state)
    mSkills.addHandlers(state)
end

local function init(clearAll)
    print("NCG initialization begins!")

    if state.isCRELMode then
        print("CREL mod detected, changes on attributes and skills starting values will be preserved")
    end
    if not state.isInitialized or not state.isCRELMode then
        mC.setChargenStats(state)
    end
    setStartAttributes()
    local baseAttrMods = mC.getBaseStatMods().attr

    for attrId, value in pairs(state.attrs.start) do
        state.attrs.base[attrId] = value
        T.Actor.stats.attributes[attrId](self).base = state.attrs.start[attrId] + (baseAttrMods[attrId] or 0)
        if clearAll or state.attrs.diffs[attrId] == nil then
            state.attrs.diffs[attrId] = 0
        elseif state.attrs.diffs[attrId] ~= 0 then
            log(string.format("Preserving previous \"%s\" external change of %d", attrId, state.attrs.diffs[attrId]))
        end
    end
    state.healthAttrs = mH.initNewTable(0, mCfg.healthAttributeFactors)

    requests[mDef.requestTypes.refreshStats] = true
    requests[mDef.requestTypes.starterSpells] = true

    state.isInitialized = true
    setup()

    if mS.globalStorage:get("showIntro") then
        -- Wait a few seconds, then flash a message to prompt the user to configure the mod
        async:newSimulationTimer(2, async:registerTimerCallback(
                "newGameGreeting",
                function()
                    mC.showMessage(state, L("doSettings"))
                    log("NCG init has ended!")
                end
        ))
    end
end

local function updateGrowth()
    if mS.debugStorage:get("disableGrowth") then return end
    mSkills.updateSkills(state)
    local baseAttrMods = mC.getBaseStatMods().attr
    local growthRateNum = mS.getAttributeGrowthRate()
    local attributesCappedValue = mS.getAttributeGeneralMaxValue()
    local perAttributeCappedValues = mS.getPerAttributeMaxValues()

    local function growAttribute(attrId)
        -- First check for an external change to the attribute. If found, save it to be reapplied later
        local diff = mC.getAttributeDiff(state, attrId, baseAttrMods)

        local growth
        if attrId == "luck" then
            growth = mC.getLuckGrowth(state)
        else
            -- Calculate growth based on each attribute's related skills
            growth = mC.getAttributeGrowth(state, attrId, growthRateNum)
        end
        state.attrs.progress[attrId] = growth % 1

        local base = math.floor(growth) + state.attrs.start[attrId]
        local cap = perAttributeCappedValues[attrId] or attributesCappedValue
        base = math.max(0, math.min(base, cap))
        if cap == base then
            state.attrs.progress[attrId] = 0
        end
        state.attrs.base[attrId] = base
        local value = base + (baseAttrMods[attrId] or 0) + diff

        mC.setAttr(attrId, value)
    end

    -- Look at each attribute, determine if it should be recalculated based on its related skills
    for _, attr in ipairs(core.stats.Attribute.records) do
        if attr.id ~= "luck" then
            growAttribute(attr.id)
        end
    end

    requests[mDef.requestTypes.health] = true

    mC.setPlayerLevelStats(state)

    local newLevel = state.level.value

    local currentLevel = mC.self.level.current

    if newLevel ~= currentLevel then
        if newLevel > currentLevel then
            mC.showMessage(state, L("lvlUp", { level = newLevel }))
        elseif newLevel < currentLevel then
            mC.showMessage(state, L("lvlDown", { level = newLevel }))
        end

        mC.self.level.current = newLevel
    end

    growAttribute("luck")

    if requests[mDef.requestTypes.starterSpells] then
        requests[mDef.requestTypes.starterSpells] = false
        if not state.isCRELMode then
            mSpells.updateStarterSpells()
        end
    end

    mC.showModAttrMessages(state)
end

local function updateHealth(deltaTime)
    lastUpdateHealthTime = lastUpdateHealthTime + (deltaTime or 0.5)
    if lastUpdateHealthTime < 0.5 then return end
    lastUpdateHealthTime = 0
    if mS.debugStorage:get("disableGrowth") then return end

    local recalculate = false
    local stateBasedHP = mS.healthStorage:get("stateBasedHP")
    for attribute, value in pairs(state.healthAttrs) do
        local current
        if stateBasedHP then
            current = T.Actor.stats.attributes[attribute](self).modified
        else
            current = T.Actor.stats.attributes[attribute](self).base
        end
        if current ~= value then
            state.healthAttrs[attribute] = current
            recalculate = true
        end
    end

    if requests[mDef.requestTypes.health] then
        requests[mDef.requestTypes.health] = false
    elseif not recalculate then
        return
    end

    local hpPerLevelFactor = mS.getPerLevelHPGainFactor()
    local currentLevel = mC.self.level.current
    local healthFactor = mC.getHealthFactor(state)
    local maxHealthModifier = mCore.getMaxHealthModifier(self)
    if maxHealthModifier ~= 0 then
        log(string.format("Detected max health modifier: %d", maxHealthModifier))
    end
    local maxHealth = math.floor(healthFactor + (currentLevel - 1) * hpPerLevelFactor * healthFactor + maxHealthModifier)
    local health = mC.self.health
    local prevHealth = health.current
    local ratio = health.current / health.base
    health.base = maxHealth
    health.current = ratio * maxHealth
    if health.current - prevHealth ~= 0 then
        log(string.format("Player's health changed from %d to %d (diff %d)", prevHealth, health.current, health.current - prevHealth))
    end
end

local function onFrame(deltaTime)
    if not state.isInitialized then return end

    if requests[mDef.requestTypes.refreshStats] then
        requests[mDef.requestTypes.refreshStats] = false
        updateGrowth()
    end

    updateHealth(deltaTime)
end

local function onGameUnpaused()
    if requests[mDef.requestTypes.softInit] or (not state.isInitialized and not isStarwindMode and T.Player.isCharGenFinished(self)) then
        if CRELCells[self.cell.name] and mC.self.level.current == 1 then
            state.isCRELMode = true
            return
        end
        requests[mDef.requestTypes.softInit] = false
        init(false)
        return
    end

    if not state.isInitialized then return end

    if requests[mDef.requestTypes.startAttrsOnResume] then
        requests[mDef.requestTypes.startAttrsOnResume] = false
        setStartAttributes()
    end
    updateGrowth()
end

local function modAttributes(mods)
    for _, mod in ipairs(mods) do
        local attr = T.Actor.stats.attributes[mod.attrId](self)
        attr.base = attr.base + mod.value
    end
    onGameUnpaused()
end

local function onUpdate(deltaTime)
    if deltaTime == 0 then
        gamePaused = true
        return
    elseif gamePaused == true then
        gamePaused = false
        if state.bitterCup.object then
            for attrId, getter in pairs(T.Actor.stats.attributes) do
                getter(self).base = state.bitterCup.attrSave[attrId]
            end
            core.sendGlobalEvent(mDef.events.onBitterCupHandled, { bitterCup = state.bitterCup.object, player = self })
            state.bitterCup.object = nil
            state.bitterCup.attrSave = nil
            return
        end
        onGameUnpaused()
    end
end

local function onBitterCupActivated(bitterCup)
    state.bitterCup.object = bitterCup
    state.bitterCup.attrSave = {}
    for attrId, getter in pairs(T.Actor.stats.attributes) do
        state.bitterCup.attrSave[attrId] = getter(self).base
    end
end

local function uiModeChanged(data)
    log(string.format('UI mode changed from %s to %s (%s)', data.oldMode, data.newMode, data.arg))
    if not data.newMode and (data.oldMode == "ChargenClassReview" or state.isInitialized and chargenUiModes[data.oldMode]) then
        requests[mDef.requestTypes.softInit] = true
        state.isInitialized = false
    end

    if not state.isInitialized then return end
end

local function refreshLogsWindow()
    updateGrowth()
    updateHealth()
    mWindows.refreshLogsWindow(state)
end

local function onInit()
    input.registerActionHandler(mDef.actions.showLogs, async:callback(function(enabled)
        if not state.isInitialized then return end
        if enabled then
            updateGrowth()
            updateHealth()
            mWindows.showLogsWindow(state)
        else
            mWindows.closeLogsWindow()
        end
    end))

    if not state.profileId then
        initProfileId()
    end
end

local function onLoad(data)
    if not data then
        onInit()
        mC.showMessage(state, "No data found in save game, NCG will be initialized")
        return
    end

    if data.savedGameVersion == mDef.savedGameVersion then
        state = data
        requests[mDef.requestTypes.refreshStats] = true
    else
        if mC.upgradeOldState(data) then
            state = data
        end
        requests[mDef.requestTypes.softInit] = true
        mC.showMessage(state, string.format("Old NCG game save detected, upgraded from v%.2f to v%.2f", data.savedGameVersion, mDef.savedGameVersion))
    end
    onInit()
    if state.isInitialized then
        setup()
    end
end

local function onSave()
    state.savedGameVersion = mDef.savedGameVersion
    return state
end

local function onPlayerDeath()
    local count = storage.playerSection(state.profileId):get("deathCount") or 0
    storage.playerSection(state.profileId):set("deathCount", count + 1)
    updateGrowth()
end

-- Public interface

local interface = {
    version = mDef.interfaceVersion,
    getState = function() return state end,
    -- Get skill affected attributes, also set them if attrImpacts is set (map attributeId -> impactValue)
    skillAffectedAttributes = function(skillId, attrImpacts)
        if skillId == nil or T.NPC.stats.skills[skillId] == nil then
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
        updateGrowth()
    end,
    -- Get player level process value
    levelProgress = function()
        return state.level.prog
    end,
    -- Reset player's character stats, useful with old game saves or when some stats are broken
    resetStats = function()
        init(true)
    end,
    modHealth = function(value)
        log(string.format("Health externally modified: %.1f", value))
        mSkills.onHealthModified(state, value)
    end,
}

return {
    engineHandlers = {
        onFrame = onFrame,
        onUpdate = onUpdate,
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        Died = onPlayerDeath,
        [mDef.events.refreshLogsWindow] = refreshLogsWindow,
        [mDef.events.onSkillLevelUp] = function(data) mSkills.onSkillLevelUp(data.skillId, data.skillLevel) end,
        [mDef.events.updateRequest] = function(type) requests[type] = true end,
        [mDef.events.modAttributes] = modAttributes,
        [mDef.events.onBitterCupActivated] = onBitterCupActivated,
        [I.StatsWindow.Constants.Events.WINDOW_SHOWN] = function() requests[mDef.requestTypes.refreshStats] = true end,
        ["SkillEvolution_on_skills_changed"] = function() requests[mDef.requestTypes.refreshStats] = true end,
    },
    interfaceName = mDef.MOD_NAME,
    interface = interface
}
