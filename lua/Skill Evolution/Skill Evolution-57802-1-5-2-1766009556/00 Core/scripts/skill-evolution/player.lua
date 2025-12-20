local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')
local I = require("openmw.interfaces")

-- Settings first to init the storage which is used everywhere
local mS = require('scripts.skill-evolution.config.settings')
mS.init()

local log = require('scripts.skill-evolution.util.log')
local mDef = require('scripts.skill-evolution.config.definition')
local mCompat = require('scripts.skill-evolution.config.compatibility')

if not mCompat.check(
        {
            "simpleexpscaling.omwscripts",
            "MBSP_Uncapper.omwscripts", "MBSP.omwscripts", "MBSP ncgdMW edit.omwaddon",
            "Skill_Uses_Scaled.omwscripts",
        },
        { "StatsWindow.omwscripts", "StatsWindow.ESP" }
) then return end

local mCore = require('scripts.skill-evolution.util.core')
local mH = require('scripts.skill-evolution.util.helpers')
local mDecay = require('scripts.skill-evolution.skills.decay')
local mHandlers = require('scripts.skill-evolution.skills.handlers')
local mScaling = require('scripts.skill-evolution.skills.scaling')
local mTraining = require('scripts.skill-evolution.skills.training')
local mMsg = require('scripts.skill-evolution.ui.messages')
local mNotifs = require("scripts.skill-evolution.ui.notifications")
local mStatsUi = require('scripts.skill-evolution.ui.stats')

local state = {
    savedGameVersion = mDef.savedGameVersion,
    skills = {
        base = {},
        progress = mH.newTable(0, T.NPC.stats.skills),
        excessGain = mH.newTable(0, T.NPC.stats.skills),
        decay = mH.newTable(0, T.NPC.stats.skills),
        max = mH.newTable(0, T.NPC.stats.skills),
        feats = mH.newTable(function() return {} end, T.NPC.stats.skills),
    },
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
        },
        alchemy = {
            recipeCounts = {},
        },
    },
    decay = {
        lastDecayTime = 0,
        noDecayTime = mCore.totalGameTimeInHours(),
        noDecayTimeStart = mCore.totalGameTimeInHours(),
        lastPlayerPos = self.position,
    },
    lastTrainer = nil,
}

local isSetupDone = false
local gamePaused = false
local chargenUiModes = { ChargenClassReview = true, ChargenClassPick = true, ChargenRace = true, ChargenBirth = true }
local settingUpdates = {}

local function setup()
    if isSetupDone then return end
    isSetupDone = true
    mStatsUi.setStatsWindow(state)
    mHandlers.addHandlers(state)
end

local function updateSkills(params)
    local baseSkillMods = mCore.getBaseSkillMods()
    local decayEnabled = mS.skillsStorage:get("skillDecayRate") ~= "skillDecayNone"
    local skillsCappedValue = mS.getSkillGeneralMaxValue()
    local perSkillCappedValues = mS.getPerSkillMaxValues()

    local changes = {}
    for skillId, getter in pairs(T.NPC.stats.skills) do
        local cappedValue = perSkillCappedValues[skillId] or skillsCappedValue
        local currentBase = mTraining.originalTrainingSkills[skillId] or getter(self).base

        state.skills.max[skillId] = math.min(state.skills.max[skillId], cappedValue)

        local storedBase = state.skills.base[skillId]
        local actualBase = currentBase - (baseSkillMods[skillId] or 0)

        if storedBase and storedBase ~= actualBase then
            changes[skillId] = actualBase - storedBase
            log(string.format("Skill \"%s\" has changed from %s to %s", skillId, storedBase, actualBase))
            if not decayEnabled or actualBase > state.skills.max[skillId] then
                state.skills.max[skillId] = math.min(actualBase, cappedValue)
            end
            for _, feats in pairs(state.skills.feats[skillId]) do
                feats.averages.prevLevel = feats.averages.currLevel
                feats.averages.currLevel = mH.newAvg()
                feats.lists.level = {}
            end
        end

        state.skills.base[skillId] = actualBase

        -- Update skill progress to actual value, because:
        -- - skill increases from the console, books or training alters the progression
        -- - skill progresses need to be set for mid-game installs
        state.skills.progress[skillId] = T.NPC.stats.skills[skillId](self).progress
    end
    if not params.fromHandler and next(changes) then
        self:sendEvent(mDef.events.onSkillsChanged, changes)
    end
end

local function updateStats(params)
    params = params or {}
    updateSkills(params)
    mDecay.updateDecay(state)
    if params.excessGain and params.excessGain > 0 then
        mHandlers.handleGain(state, { skillId = params.skillId, skillGain = params.excessGain, manual = true })
    end
end

local function init()
    local baseStatsMods = mCore.getBaseSkillMods()
    for skillId, getter in pairs(T.NPC.stats.skills) do
        -- Max skills shall not include base skill modifiers
        state.skills.max[skillId] = getter(self).base - (baseStatsMods[skillId] or 0)
    end
    if mS.skillsStorage:get("skillDecayRate") ~= "skillDecayNone" then
        log(string.format("Decay time initialized to %s", state.decay.noDecayTime))
    end

    state.isInitialized = true
    setup()
    updateStats()
end

local function onFrame(deltaTime)
    if not state.isInitialized then return end

    if deltaTime == 0 then
        gamePaused = true
    elseif gamePaused == true then
        gamePaused = false
        self:sendEvent(mDef.events.onGameUnpaused)
    end
    mDecay.onFrame(state, deltaTime)
    mScaling.onFrame()
    mNotifs.onFrame()
end

local function onUpdate(deltaTime)
    if deltaTime == 0 then return end

    if not state.isInitialized then
        if T.Player.isCharGenFinished(self) then
            init()
        end
        return
    end

    mScaling.onUpdate(state, deltaTime)
end

local function uiModeChanged(data)
    --log(string.format('UI mode changed from %s to %s (%s)', data.oldMode, data.newMode, data.arg))
    -- mods like HBFS or BMS refreshes the UI window
    if data.newMode == data.oldMode then return end

    if not data.newMode and (data.oldMode == "ChargenClassReview" or state.isInitialized and chargenUiModes[data.oldMode]) then
        state.isInitialized = false
    end

    if not state.isInitialized then return end

    mDecay.onUiModeChanged(state, data)
    mHandlers.uiModeChanged(state, data)
    mScaling.uiModeChanged(data)
end

local function onGameUnpaused()
    if not state.isInitialized then return end
    updateStats()
    if settingUpdates[mDef.events.changeDecayRate] then
        settingUpdates[mDef.events.changeDecayRate] = nil
        mDecay.logDecayTime(state)
    end
end

local function upgradeOldState(oldState)
    if oldState.savedGameVersion < 1.1 then
        oldState.skills.excessGain = mH.newTable(0, T.NPC.stats.skills)
    end
    if oldState.savedGameVersion < 1.2 then
        oldState.skills.feats = mH.newTable(function() return {} end, T.NPC.stats.skills)
    end
    return true
end

local function onLoad(data)
    if not data then return end

    if data.savedGameVersion == mDef.savedGameVersion then
        state = data
    else
        if upgradeOldState(data) then
            state = data
        end
        self:sendEvent(mDef.events.showMessage, string.format("Old Skill Evolution game save detected, upgraded from v%.2f to v%.2f", data.savedGameVersion, mDef.savedGameVersion))
    end
    if state.isInitialized then
        setup()
    end
end

local function onSave()
    state.savedGameVersion = mDef.savedGameVersion
    return state
end

local interface = {
    version = mDef.interfaceVersion,
    getState = function() return state end,
    -- Get a skill progress value, also set it if value is not nil
    skillProgress = function(skillId, value)
        if skillId == nil or T.NPC.stats.skills[skillId] == nil then
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
            T.NPC.stats.skills[skillId](self).progress = value
        end
        return changed, state.skills.progress[skillId]
    end,
    -- Get player no decay time value (total time in hours without decay)
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

return {
    engineHandlers = {
        onFrame = onFrame,
        onUpdate = onUpdate,
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        [mDef.events.onGameUnpaused] = onGameUnpaused,
        [mDef.events.applySkillUsedHandlers] = function(data) mHandlers.applySkillUsedHandlers(state, data.skillId, data.params, data.afterHandler) end,
        [I.StatsWindow.Constants.Events.WINDOW_SHOWN] = function() updateStats() end,
        [mDef.events.updateStats] = function(params) updateStats(params) end,
        [mDef.events.onSkillLevelUp] = function(data) mHandlers.onSkillLevelUp(state, data.skillId, data.skillLevel, data.source) end,
        [mDef.events.changeDecayRate] = function() settingUpdates[mDef.events.changeDecayRate] = true end,
        [mDef.events.onActorHit] = function(actor) mScaling.onActorHit(state, actor) end,
        [mDef.events.onPlayerHit] = function(attack) mScaling.onPlayerHit(state, attack) end,
        [mDef.events.onActorAnimHit] = function(data) mScaling.onActorAnimHit(state, data.actor, data.animGroup, data.animKey) end,
        [mDef.events.setWerewolfClawMult] = function(value) mCore.werewolfClawMult = value end,
        [mDef.events.showMessage] = mMsg.showMessage,
        [mDef.events.showModSkill] = function(data) mMsg.showModSkill(data.skillId, data.value, data.diff, data.options) end,
    },
    interfaceName = mDef.MOD_NAME,
    interface = interface
}
