local core = require('openmw.core')
local async = require('openmw.async')
local storage = require('openmw.storage')
local input = require("openmw.input")
local self = require('openmw.self')
local T = require('openmw.types')
local I = require('openmw.interfaces')

local mDef = require('scripts.NCG.config.definition')
local mCfg = require('scripts.NCG.config.configuration')
local mS = require('scripts.NCG.config.store')
local mCompat = require('scripts.NCG.config.compatibility')
local mC = require('scripts.NCG.core.common')
local mAttrs = require('scripts.NCG.core.attributes')
local mSkills = require('scripts.NCG.core.skills')
local mHealth = require('scripts.NCG.core.health')
local mHelpers = require('scripts.NCG.util.helpers')
local mSpells = require('scripts.NCG.util.spells')
local mWindows = require("scripts.NCG.ui.windows")
local mStatsUi = require('scripts.NCG.ui.stats')
local log = require('scripts.NCG.util.log')

local L = core.l10n(mDef.MOD_NAME)

mS.registerGroups()
mC.initPlayerSettings()
if not mCompat.check(
        {
            "ncgdmw.omwscripts", "ncgdmw.omwaddon", "ncgdmw_starwind.omwaddon",
            "PotentialCharacterProgression.omwscripts", "ImprovedVanillaLeveling.omwscripts",
        },
        { "StatsWindow.omwscripts", "StatsWindow.ESP" },
        { "ncg.omwaddon", "ncg_starwind.omwaddon" }
) then return end

local state = {
    savedGameVersion = mDef.savedGameVersion,
    -- recent NCG notifications
    messagesLog = {},
    -- track chargen mod registrations
    chargenMods = {},
    -- true once the player has passed through the chargen class review window
    isClassReviewDone = false,
    -- true once NCG saved the starting stat values
    isInitialized = false,
    -- character profile ID saved into the store and used for the death counter
    profileId = nil,
    -- internal level progress as NCG stops the vanilla progress
    levelProgress = 0,
    -- support for uncapped attributes when drinking the Bitter Cup potion
    bitterCup = { object = nil, attrSave = nil },

    attrs = {
        -- attributes saved on first initialization (excluding base modifiers)
        init = {},
        -- attribute starting values (a ratio of the init attributes)
        start = {},
        -- current attribute base values (excluding base and extra modifiers)
        base = {},
        -- attribute progressions towards next increase
        progress = mHelpers.initNewTable(0, T.Actor.stats.attributes),
        -- tracked extra modifiers from console commands, other mods or quest rewards
        diffs = mHelpers.initNewTable(0, T.Actor.stats.attributes),
        -- normalization value added to all attributes to keep the average of non-luck attributes equal to the initial average
        normValue = 0,
    },
    skills = {
        -- map of class and misc skills for quick access
        major = {}, minor = {}, misc = {},
        -- skill starting values, saved on first initialization
        start = {},
        -- current attribute growth per skill
        growth = {},
    },
    health = {
        -- current health base value (excluding extra modifiers)
        base = mC.self.health.base,
        -- tracked extra modifiers from console commands, other mods or quest rewards
        diff = 0,
        -- current health attribute values
        attributes = mHelpers.initNewTable(0, mCfg.healthAttributeFactors),
    },
}

local requests = {}
local isSetupDone = false
local gamePaused = false
local lastUpdateHealthTime = 0
local CRELChargenCells = { ["CREL Start"] = true, ["AB2 Start"] = true }

local function setup()
    if isSetupDone or not state.isInitialized then return end
    isSetupDone = true
    mSkills.updateCustomSkills(state)
    mStatsUi.setStatsWindow(state)
    mSkills.addHandlers()
    if I.SkillFramework then
        I.SkillFramework.addSkillRegisteredHandler(function(skillId)
            if not state.skills.start[skillId] then
                log(string.format("New custom skill registered: %s", skillId))
                mSkills.updateCustomSkills(state)
            end
        end)
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

local function initProfile()
    -- wait for default and custom character generations to finish
    if not state.isInitialized and (not state.isClassReviewDone or next(state.chargenMods)) then return end

    print("NCG initialization begins!")

    if mC.self.level.progress > 0 then
        state.levelProgress = mC.self.level.progress
        mC.self.level.progress = 0
        log(string.format("Preserving existing level progress %d", state.levelProgress))
    end

    local baseStatMods = mC.getBaseStatMods()
    if not state.isInitialized then
        mAttrs.saveInitialDiffs(state, baseStatMods.attr)
        mSkills.saveStartValues(state, baseStatMods.skill)
    end

    mSkills.setClassSkills(state)

    mAttrs.setStartValues(state, baseStatMods.skill)
    mAttrs.setBaseValues(state, baseStatMods.attr)

    if state.health.diff ~= 0 then
        log(string.format("Preserving previous health external change of %d", state.health.diff))
    end
    mHealth.setAttributes(state)
    mHealth.setHealth(state)

    requests[mDef.requestTypes.refreshStats] = true
    if not state.isInitialized then
        -- set starter spells once attributes are grown
        requests[mDef.requestTypes.starterSpells] = true
    end

    state.isInitialized = true

    setup()

    log("NCG init has ended!")
end

local function updatePlayerLevel()
    local currentLevel = mC.self.level.current
    local skillUpsPerLevel = mS.settings.classSkillPointsPerLevelUp.get()
    local newLevel = currentLevel + math.floor(state.levelProgress / skillUpsPerLevel)
    state.levelProgress = state.levelProgress % skillUpsPerLevel

    if newLevel == currentLevel then return end
    if newLevel > currentLevel then
        mC.showMessage(state, L("lvlUp", { level = newLevel }))
    else
        mC.showMessage(state, L("lvlDown", { level = newLevel }))
    end
    mC.self.level.current = newLevel
end

local function updateGrowth()
    if mS.settings.disableGrowth.get() then return end
    local baseStatMods = mC.getBaseStatMods()
    mSkills.setAllGrowthsForAttributes(state, baseStatMods.skill)
    local growthRateNum = mS.settings.attrGrowthRate.get()
    local attributesCappedValue = mAttrs.getCappedValue(mS.settings.attributeUncapper.get())
    local perAttributeCappedValues = mAttrs.getPerAttrCappedValues()

    local function growAttribute(attrId)
        -- First check for an external change to the attribute. If found, save it to be reapplied later
        local diff = mAttrs.setExternalDiff(state, attrId, baseStatMods.attr)

        local growth
        if attrId == "luck" then
            growth = mAttrs.getLuckGrowth(state)
        else
            -- Calculate growth based on each attribute's related skills
            growth = mAttrs.getGrowth(state, attrId, growthRateNum)
        end
        state.attrs.progress[attrId] = growth % 1

        local base = math.floor(growth) + state.attrs.start[attrId]
        local cap = perAttributeCappedValues[attrId] or attributesCappedValue
        base = math.max(0, math.min(base, cap))
        if cap == base then
            state.attrs.progress[attrId] = 0
        end
        state.attrs.base[attrId] = base
        mAttrs.setBaseValue(attrId, base + (baseStatMods.attr[attrId] or 0) + diff)
    end

    -- Look at each attribute, determine if it should be recalculated based on its related skills
    for i = 1, #core.stats.Attribute.records do
        local id = core.stats.Attribute.records[i].id
        if id ~= "luck" then
            growAttribute(id)
        end
    end

    -- force health recalculation
    requests[mDef.requestTypes.health] = true

    updatePlayerLevel()

    -- luck growth is based on the player level and must therefore be calculated after updating the level
    growAttribute("luck")

    if requests[mDef.requestTypes.starterSpells] then
        requests[mDef.requestTypes.starterSpells] = false
        mSpells.updateStarterSpells()
    end

    mC.showMessages(state)
end

local function updateHealth(deltaTime)
    lastUpdateHealthTime = lastUpdateHealthTime + (deltaTime or 0.5)
    if lastUpdateHealthTime < 0.5 then return end
    lastUpdateHealthTime = 0
    if mS.settings.disableGrowth.get() then return end

    local health = mC.self.health
    if state.health.base + state.health.diff ~= health.base then
        local diff = health.base - state.health.base
        log(string.format("Detected health change %d (previously %d), new base is %d", diff, state.health.diff, health.base))
        state.health.diff = diff
    end

    local recalculate = mHealth.setAttributes(state)

    if requests[mDef.requestTypes.health] then
        requests[mDef.requestTypes.health] = false
    elseif not recalculate then
        return
    end

    local prevHealth = health.base
    mHealth.setHealth(state)
    local diff = health.base - prevHealth
    if diff ~= 0 then
        log(string.format("Player's base health changed from %d to %d (diff %d)", prevHealth, health.base, diff))
        if mS.settings.showHealthChangeNotifications.get() then
            mC.showMessage(state, L(diff > 0 and "statUp" or "statDown", { stat = core.getGMST("sHealth"), prev = prevHealth, value = health.base }))
        end
    end
end

local function onFrame(deltaTime)
    if not state.isInitialized then return end

    if requests[mDef.requestTypes.refreshStats] then
        requests[mDef.requestTypes.refreshStats] = false
        if not requests[mDef.requestTypes.initProfile] then
            updateGrowth()
        end
    end

    updateHealth(deltaTime)
end

local function uiModeChanged(data)
    log(string.format('UI mode changed from %s to %s, arg is %s', data.oldMode, data.newMode, data.arg))

    -- fully init NCG only when closing the chargen class review window, instead of using isCharGenFinished()
    -- works for vanilla, Starwind chargen, and probably most quick chargen mods
    -- also works after the console command EnableStatReviewMenu, or other ones leading to the class review
    -- we wait for the game to be unpaused before doing the init, because the player may go back to previous chargen windows
    -- and we cannot rely on data.newMode as it's both empty between chargen windows and when the review window is closed
    if data.oldMode == "ChargenClassReview" then
        -- save initial attribute values to detect changes from chargen mods
        if not state.isInitialized then
            mAttrs.saveInitialValues(state, mC.getBaseStatMods().attr)
        end
        if not state.isClassReviewDone then
            -- wait for the game to resume to be sure the chargen windows are closed
            async:newUnsavableSimulationTimer(0, function()
                -- do it only once
                if state.isClassReviewDone then return end
                log("Chargen class review done")
                state.isClassReviewDone = true
                initProfile()
            end)
            return
        end
        -- chargen is already over, and the player used a console command to open the class review window
        state.isInitialized = false
        requests[mDef.requestTypes.initProfile] = true
    end
end

local function onGameUnpaused()
    if requests[mDef.requestTypes.initProfile] then
        requests[mDef.requestTypes.initProfile] = false
        initProfile()
        return
    end

    if not state.isInitialized then return end

    if requests[mDef.requestTypes.startAttrsOnResume] then
        requests[mDef.requestTypes.startAttrsOnResume] = false
        mAttrs.setStartValues(state)
    end

    if state.bitterCup.object then
        for attrId, getter in pairs(T.Actor.stats.attributes) do
            local attr = getter(self)
            attr.base, attr.modifier, attr.damage = table.unpack(state.bitterCup.attrSave[attrId])
        end
        core.sendGlobalEvent(mDef.events.onBitterCupHandled, { bitterCup = state.bitterCup.object, player = self })
        state.bitterCup.object = nil
        state.bitterCup.attrSave = nil
        return
    end

    -- always check growth on game resume to handle changes during a paused game like console commands
    updateGrowth()
end

local function onUpdate(deltaTime)
    if deltaTime == 0 then
        gamePaused = true
        return
    end
    if gamePaused then
        gamePaused = false
        onGameUnpaused()
    end

    if state.isInitialized then return end

    if CRELChargenCells[self.cell.name] then
        -- the player is in a CREL's special cell, which means the CREL's chargen is not over
        self:sendEvent(mDef.events.onChargenModRegistration, { modId = "CREL" })
    elseif state.chargenMods.CREL then
        -- the player was in a CREL's special cell, which means the CREL's chargen is over
        self:sendEvent(mDef.events.onChargenModFinished, { modId = "CREL" })
    end
end

local function modAttributes(mods)
    for _, mod in ipairs(mods) do
        local attr = T.Actor.stats.attributes[mod.attrId](self)
        attr.base = math.max(0, attr.base + mod.value)
    end
    updateGrowth()
end

local function onBitterCupActivated(bitterCup)
    state.bitterCup.object = bitterCup
    state.bitterCup.attrSave = {}
    for attrId, getter in pairs(T.Actor.stats.attributes) do
        local attr = getter(self)
        state.bitterCup.attrSave[attrId] = { attr.base, attr.modifier, attr.damage }
    end
end

local function refreshLogsWindow()
    updateGrowth()
    updateHealth()
    mWindows.refreshLogsWindow(state)
end

local function onChargenModRegistration(data)
    if state.isInitialized or state.chargenMods[data.modId] then return end
    log(string.format("Chargen mod \"%s\" registered, will wait for it to finish altering the initial player's profile", data.modId))
    state.chargenMods[data.modId] = true
end

local function onChargenModFinished(data)
    if state.isInitialized or not state.chargenMods[data.modId] then return end
    log(string.format("Chargen mod \"%s\" finished its player's profile changes", data.modId))
    state.chargenMods[data.modId] = nil
    initProfile()
end

local function onActive()
    setup()
end

local function init()
    if not state.profileId then
        initProfileId()
    end

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
end

local function onInit()
    if T.Player.isCharGenFinished(self) then
        state.isClassReviewDone = true
        mS.settings.startAttrRatio.set(mS.enums.startAttrRatios.Full)
    end
    init()
end

local function onLoad(data)
    if not data then
        init()
        mC.showMessage(state, "No data found in save game, NCG will be initialized")
        return
    end

    if data.savedGameVersion == mDef.savedGameVersion then
        state = data
        requests[mDef.requestTypes.refreshStats] = true
    else
        if data.savedGameVersion < 1.31 then
            data.bitterCup = {}
        end
        if data.savedGameVersion < 1.5 then
            data.health = {
                base = mC.self.health.base,
                diff = 0,
                attributes = data.healthAttrs,
            }
            data.healthAttrs = nil
        end
        if data.savedGameVersion < 2.0 then
            data.chargenMods = {}
            data.attrs.init = data.attrs.chargen
            data.attrs.chargen = nil
            data.skills.base = nil
            data.skills.growth = data.skills.growth.attributes
            data.levelProgress = data.level.skillUps % mS.settings.classSkillPointsPerLevelUp.get()
            data.level.value = nil
            data.level.prog = nil
            data.level.skillUps = nil
        end
        state = data
        if state.isInitialized then
            requests[mDef.requestTypes.initProfile] = true
        end
        mC.showMessage(state, string.format("Old NCG game save detected, upgraded save format from v%.2f to v%.2f",
                data.savedGameVersion, mDef.savedGameVersion))
    end
    init()
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

local interface = {
    version = mDef.interfaceVersion,
    getState = function() return state end,
    -- Get the weighted attributes impacted by a skill, or set them if attrImpacts is set (map attributeId -> impactValue)
    skillImpactOnAttributes = function(skillId, attrImpacts)
        if not skillId or not mSkills.getStat(skillId) then
            error(string.format("Invalid skill id \"%s\"", skillId))
        end
        if attrImpacts == nil then
            return mCfg.skillImpactOnAttributes[skillId]
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
        mCfg.setSkillImpactSums()
        updateGrowth()
    end,
    -- Get or set the player level progress
    levelProgress = function(progress)
        if not progress then
            return state.levelProgress
        end
        if type(progress) == "number" and math.floor(progress) == progress then
            state.levelProgress = progress
            updateGrowth()
        else
            error(string.format("Invalid progress value \"%s\", it has to be an integer", progress))
        end
    end,
    computeChargenStats = function()
        mAttrs.computeChargenValues(state)
        mSkills.computeChargenValues(state)
        initProfile()
    end,
}

return {
    interfaceName = mDef.MOD_NAME,
    interface = interface,
    engineHandlers = {
        onFrame = onFrame,
        onUpdate = onUpdate,
        onInit = onInit,
        onActive = onActive,
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        Died = onPlayerDeath,
        [mDef.events.refreshLogsWindow] = refreshLogsWindow,
        [mDef.events.onSkillLevelUp] = function(data) mSkills.onSkillLevelUp(state, data.skillId, data.skillLevel) end,
        [mDef.events.updateRequest] = function(type) requests[type] = true end,
        [mDef.events.modAttributes] = modAttributes,
        [mDef.events.onBitterCupActivated] = onBitterCupActivated,
        -- External events
        [mDef.events.statsWindowShown] = function() requests[mDef.requestTypes.refreshStats] = true end,
        [mDef.events.skillEvolutionOnSkillsChanged] = function() requests[mDef.requestTypes.refreshStats] = true end,
        [mDef.events.onChargenModRegistration] = onChargenModRegistration,
        [mDef.events.onChargenModFinished] = onChargenModFinished,

    },
}
