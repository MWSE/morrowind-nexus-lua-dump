local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')
local I = require("openmw.interfaces")

local mDef = require('scripts.skill-evolution.config.definition')
local mCfg = require('scripts.skill-evolution.config.configuration')
local mS = require('scripts.skill-evolution.config.store')
local mSettings = require('scripts.skill-evolution.config.settings')
local mCompat = require('scripts.skill-evolution.config.compatibility')
local mHandlers = require('scripts.skill-evolution.skills.handlers')
local mScaling = require('scripts.skill-evolution.skills.scaling')
local mDecay = require('scripts.skill-evolution.skills.decay')
local mMsg = require('scripts.skill-evolution.ui.messages')
local mNotifs = require("scripts.skill-evolution.ui.notifications")
local mStatsUi = require('scripts.skill-evolution.ui.stats')
local mCore = require('scripts.skill-evolution.util.core')
local mHelpers = require('scripts.skill-evolution.util.helpers')
local log = require('scripts.skill-evolution.util.log')

if not mCompat.check(
        {
            "simpleexpscaling.omwscripts",
            "MBSP_Uncapper.omwscripts", "MBSP.omwscripts", "MBSP ncgdMW edit.omwaddon",
            "Skill_Uses_Scaled.omwscripts",
        },
        { "StatsWindow.omwscripts", "StatsWindow.ESP" }
) then return end

mS.configureSettings(mS.configStages.Root)
mS.registerGroups(mS.configStages.Root)

local state = {
    savedGameVersion = mDef.savedGameVersion,
    -- player's profile specialization
    specialization = nil,
    skills = {
        -- map of class and misc skills for quick access
        major = {}, minor = {}, misc = {},
        -- current skill base values (excluding base modifiers)
        base = {},
        -- skill progressions towards level increase
        progress = {},
        -- residual gains during skill increases that may be carried over the next skill level
        excessGain = {},
        -- skill progressions towards level decrease
        decay = {},
        -- max base skill levels reached so far (for decay, excluding base modifiers)
        max = {},
        -- feat stat lists for supported skills
        feats = {},
    },
    -- stats required for skill scaling
    scaled = {
        pos = self.position,
        isOnGround = true,
        groundDist = 0,
        acrobatics = {
            lastJumpTime = core.getSimulationTime(),
            lastJumpMaxDuration = 0.01,
            maxFallPos = self.position,
            stats = nil,
        },
        athletics = {
            runningDuration = 0,
            deltaTime = 0,
            deltaPos = 0,
            lastGameTime = core.getGameTime()
        },
        alchemy = {
            recipeCounts = {},
        },
    },
    decay = {
        -- total decay time previously saved
        lastDecayTime = 0,
        -- total time without decay enabled
        noDecayTime = mCore.totalGameTimeInHours(),
        -- time since decay is disabled
        noDecayTimeStart = mCore.totalGameTimeInHours(),
    },
    lastPlayerPos = nil,
    lastTrainer = nil,
}

local L = core.l10n(mDef.MOD_NAME)
local isSetupDone = false
local gamePaused = false
local settingUpdates = {}
local upgradeFromVersion
local firstStatsWindowShown = true

local function updateStats(options)
    options = options or {}
    local baseSkillMods = mCore.getBaseSkillMods()
    local decayEnabled = mSettings.isDecayEnabled()
    local skillsCappedValue = mSettings.getCappedValue(mS.settings.skillUncapper.get())
    local perSkillCappedValues = mSettings.getPerSkillCappedValues()

    local changes = {}
    for skillId, stat in pairs(mCore.getSkillStats()) do
        local cappedValue = perSkillCappedValues[skillId] or skillsCappedValue

        state.skills.max[skillId] = math.min(state.skills.max[skillId], cappedValue)

        local storedBase = state.skills.base[skillId]
        local actualBase = stat.base - (baseSkillMods[skillId] or 0)

        if storedBase and storedBase ~= actualBase then
            changes[skillId] = actualBase - storedBase
            log(string.format("Skill \"%s\" has changed from %s to %s", skillId, storedBase, actualBase))
            if not decayEnabled or actualBase > state.skills.max[skillId] then
                state.skills.max[skillId] = math.min(actualBase, cappedValue)
            end
            for _, feats in pairs(state.skills.feats[skillId]) do
                feats.averages.prevLevel = feats.averages.currLevel
                feats.averages.currLevel = mHelpers.newAvg()
                feats.lists.level = {}
            end
        end

        state.skills.base[skillId] = actualBase

        -- update skill progress to actual value, because:
        -- - skill increases from the console, books or training alters the progression
        -- - skill progresses need to be set for mid-game installs
        if stat.base < 100 then
            state.skills.progress[skillId] = stat.progress
        end
    end

    if not options.fromHandler and next(changes) then
        -- compatibility event for other mods (e.g. NCG)
        self:sendEvent(mDef.events.onSkillsChanged, changes)
    end

    mDecay.updateDecay(state)

    if options.excessGain and options.excessGain > 0 then
        mHandlers.handleGain(state, {
            skillId = options.skillId,
            skillGain = options.excessGain,
            baseSkillMods = baseSkillMods,
            manual = true,
        })
    end
end

local updateCustomSkills
updateCustomSkills = function()
    if not I.SkillFramework then return end

    -- force the skill stat caches regeneration now custom skills should be all registered
    mCore.clearSkillRecordCache()
    mCore.clearSkillStatCaches()

    -- handle unsupported custom skills and mid-game added custom skills
    for skillId in pairs(I.SkillFramework.getSkillRecords()) do
        if not state.skills.progress[skillId] then
            state.skills.progress[skillId] = 0
            state.skills.excessGain[skillId] = 0
            state.skills.decay[skillId] = 0
            state.skills.max[skillId] = 0
            state.skills.feats[skillId] = {}
        end
    end
    I.SkillFramework.addSkillRegisteredHandler(function(skillId)
        if not mCore.getSkillRecord(skillId) then
            updateCustomSkills(state)
        end
    end)
end

local function setup()
    if isSetupDone or not state.isInitialized then return end
    isSetupDone = true
    if upgradeFromVersion then
        if upgradeFromVersion < 2.0 then
            mCore.setClass(state)
        end
        upgradeFromVersion = nil
    end
    updateStats()
    mHandlers.addHandlers(state)
end

local function init()
    mCore.setClass(state)

    if not state.isInitialized then
        local baseSkillMods = mCore.getBaseSkillMods()
        for skillId, skill in pairs(mCore.getSkillStats()) do
            local base = skill.base - (baseSkillMods[skillId] or 0)
            state.skills.base[skillId] = base
            state.skills.max[skillId] = base
            state.skills.progress[skillId] = skill.progress
            state.skills.excessGain[skillId] = 0
            state.skills.decay[skillId] = 0
            state.skills.feats[skillId] = {}
        end
    end

    if mSettings.isDecayEnabled() then
        state.decay.noDecayTimeStart = 0
        log(string.format("Decay time initialized to %s", state.decay.noDecayTime))
    end

    state.isInitialized = true
    setup()
end

local function onGameUnpaused()
    if not state.isInitialized then
        if T.Player.isCharGenFinished(self) then
            init()
        end
        return
    end

    if not isSetupDone then return end

    updateStats()

    if settingUpdates[mDef.events.changeDecayRate] then
        settingUpdates[mDef.events.changeDecayRate] = nil
        mDecay.onDecayRateChanged(state)
    end
end

local function onFrame()
    if not isSetupDone or not state.isInitialized then return end

    mScaling.onFrame()
    if mS.settings.skillScalingDebugNotifsEnabled.get() then
        mNotifs.onFrame()
    end
end

local function onUpdate(deltaTime)
    if deltaTime == 0 then
        gamePaused = true
        return
    elseif gamePaused == true then
        gamePaused = false
        onGameUnpaused()
    end

    if not state.isInitialized then return end

    mDecay.onUpdate(state, deltaTime)
    mScaling.onUpdate(state, deltaTime)
    state.lastPlayerPos = self.position
end

local function uiModeChanged(data)
    log(string.format('UI mode changed from %s to %s, arg is %s', data.oldMode, data.newMode, data.arg))
    -- mods like HBFS or BMS refreshes the UI window
    if data.newMode == data.oldMode then return end

    if data.oldMode == "ChargenClassReview" then
        init()
    end

    if not state.isInitialized then return end

    mDecay.onUiModeChanged(state, data)
    mHandlers.uiModeChanged(state, data)
    mScaling.uiModeChanged(data)

    if data.arg
            and data.arg.type == T.NPC
            and mCompat.isQuickTrainUiEnabled()
            and data.arg.type.record(data.arg).servicesOffered.Training then
        if mS.settings.capSkillTraining.get() then
            self:sendEvent(mDef.events.showMessage, L("quickTrainCapIncompatibility"))
        end
        local range = mS.settings.scaledTrainingDuration.get()
        if range.from ~= 2 or range.to ~= 2 then
            self:sendEvent(mDef.events.showMessage, L("quickTrainDurationIncompatibility"))
        end
    end
end

local function onTimePassed()
    -- decay is disabled during training, let's re-enable it
    mDecay.setIsPaused(false)
    updateStats()
end

local function onTeleported()
    -- detect transport
    mDecay.updateDecay(state)
end

local function upgradeOldState(oldState)
    if oldState.savedGameVersion < 1.1 then
        oldState.skills.excessGain = mHelpers.newMap(0, mCore.getSkillStats())
    end
    if oldState.savedGameVersion < 1.2 then
        oldState.skills.feats = mHelpers.newMap(function() return {} end, mCore.getSkillStats())
    end
    if oldState.savedGameVersion < 1.6 then
        local range = mS.settings.magickaBasedSkillScaling.get()
        range.to = 300
        mS.settings.magickaBasedSkillScaling.set(range)
    end
    if oldState.savedGameVersion < 1.62 then
        local keys = { mS.settings.weaponSkillScaling.key, mS.settings.securitySkillScaling.key, mS.settings.athleticsSkillScaling.key }
        for i = 1, #keys do
            local range = mS.settings[keys[i]].get()
            if range.to > mCfg.maxScaledSkillGainPercent then
                range.to = mCfg.maxScaledSkillGainPercent
                mS.settings[keys[i]].set(range)
            end
        end
        local range = mS.settings.alchemySkillScaling.get()
        range.to = 350
        mS.settings.alchemySkillScaling.set(range)
    end
    if oldState.savedGameVersion >= 1.2 and oldState.savedGameVersion < 1.76 then
        local blockFeats = oldState.skills.feats.block[I.SkillProgression.SKILL_USE_TYPES.Block_Success]
        if blockFeats then
            for _, feats in pairs(blockFeats.lists) do
                for i = 1, #feats do
                    feats[i].props.hitChance = feats[i].props.hitChance * 100
                end
            end
        end
    end
    if oldState.savedGameVersion < 1.77 then
        oldState.scaled.athletics.lastGameTime = core.getGameTime()
    end
    if oldState.savedGameVersion < 1.9 then
        local range = mS.settings.scaledTrainingDuration.get()
        if range.from < 2 then
            range.from = 2
            range.to = math.max(2, range.to)
            mS.settings.scaledTrainingDuration.set(range)
        end
    end
    if oldState.savedGameVersion < 2.0 then
        oldState.lastPlayerPos = self.position
        oldState.scaled.pos = nil
        oldState.decay.lastPlayerPos = nil
    end
    return true
end

local function onActive()
    -- set skill data now custom skills should be registered
    updateCustomSkills()
    mSettings.configurePerSkillUncapperSetting()
    mSettings.configureSkillUseGainsSetting()
    mS.configureSettings(mS.configStages.OnActive)
    mS.registerGroups(mS.configStages.OnActive)
    mSettings.setCustomSkillMaxLevels()
    mSettings.init()
    setup()
end

local function onLoad(data)
    if not data then return end

    if data.savedGameVersion == mDef.savedGameVersion then
        state = data
    else
        upgradeFromVersion = data.savedGameVersion
        if upgradeOldState(data) then
            state = data
        end
        self:sendEvent(mDef.events.showMessage, string.format("Old Skill Evolution game save detected, upgraded from v%.2f to v%.2f", data.savedGameVersion, mDef.savedGameVersion))
    end
end

local function onSave()
    state.savedGameVersion = mDef.savedGameVersion
    return state
end

local interface = {
    version = mDef.interfaceVersion,
    getState = function() return state end,
    -- get a skill progress value, also set it if value is not nil
    skillProgress = function(skillId, value)
        if not skillId then
            error(string.format("Missing skill id \"%s\""), skillId)
        end
        local skill = mCore.getSkillStat(skillId)
        if not skill then
            error(string.format("Invalid skill id \"%s\""), skillId)
        end
        local changed = false
        if value then
            local numValue = tonumber(value)
            if numValue == nil or numValue < 0 or numValue >= 1 then
                error(string.format("Invalid skill progress value \"%s\", it must be between 0 and 1"), value)
            end
            changed = state.skills.progress[skillId] ~= value
            state.skills.progress[skillId] = value
            skill.progress = value
        end
        return changed, state.skills.progress[skillId]
    end,
    -- get player no decay time value (total time in hours without decay)
    noDecayTime = function()
        return state.decay.noDecayTime
    end,
    addSkillUsedHandler = function(handler)
        mHandlers.addSkillUsedHandler(handler)
    end,
    addOnHitHandler = function(handler)
        mHandlers.addOnHitHandler(handler)
    end,
}

local function onStatsWindowShown()
    if firstStatsWindowShown then
        mStatsUi.setStatsWindow(state)
        firstStatsWindowShown = false
    end
    updateStats()
end

return {
    engineHandlers = {
        onTeleported = onTeleported,
        onFrame = onFrame,
        onUpdate = onUpdate,
        onActive = onActive,
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        [mDef.events.applySkillUsedHandlers] = function(data) mHandlers.applySkillUsedHandlers(state, data.skillId, data.params, data.afterHandler) end,
        StatsWindow_Shown = onStatsWindowShown,
        [mDef.events.setCapperMaxLevels] = mSettings.setCustomSkillMaxLevels,
        [mDef.events.updateStats] = updateStats,
        [mDef.events.onTimePassed] = onTimePassed,
        [mDef.events.onSkillLevelUp] = function(data) mHandlers.onSkillLevelUp(state, data.skillId, data.skillLevel, data.source) end,
        [mDef.events.changeDecayRate] = function() settingUpdates[mDef.events.changeDecayRate] = true end,
        [mDef.events.onActorHit] = function(actor) mScaling.onActorHit(state, actor) end,
        [mDef.events.onPlayerHit] = function(attack) mScaling.onPlayerHit(state, attack) end,
        [mDef.events.onActorAnimHit] = function(data) mScaling.onActorAnimHit(state, data.actor, data.animGroup, data.animKey) end,
        [mDef.events.skipWeaponScaling] = function() mScaling.skipWeaponScaling(state) end,
        [mDef.events.skipArmorScaling] = function() mScaling.skipArmorScaling(state) end,
        [mDef.events.skipBlockScaling] = function() mScaling.skipBlockScaling(state) end,
        [mDef.events.setWerewolfClawMult] = function(value) mCore.werewolfClawMult = value end,
        [mDef.events.showMessage] = mMsg.showMessage,
        [mDef.events.showModSkill] = function(data) mMsg.showModSkill(data.skillId, data.value, data.diff, data.options) end,
    },
    interfaceName = mDef.MOD_NAME,
    interface = interface
}
