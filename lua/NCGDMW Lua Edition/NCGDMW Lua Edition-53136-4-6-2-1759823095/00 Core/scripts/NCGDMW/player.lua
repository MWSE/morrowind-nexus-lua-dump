local core = require('openmw.core')
local async = require('openmw.async')
local storage = require('openmw.storage')
local self = require('openmw.self')
local ui = require('openmw.ui')
local T = require('openmw.types')

-- Settings first to init the storage which is used everywhere
local mS = require('scripts.NCGDMW.settings')
local log = require('scripts.NCGDMW.log')
local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mCore = require('scripts.NCGDMW.core')
local mC = require('scripts.NCGDMW.common')
local mH = require('scripts.NCGDMW.helpers')
local mDecay = require('scripts.NCGDMW.decay')
local mSpells = require('scripts.NCGDMW.spells')
local mSkills = require('scripts.NCGDMW.skills')
local mUi = require("scripts.NCGDMW.ui")

local L = core.l10n(mDef.MOD_NAME)

local state = {
    isInitialized = false,
    profileId = nil,
    isCRELMode = false,
    savedGameVersion = mDef.savedGameVersion,
    skills = {
        major = {}, majorOrder = {}, minMajor = 0,
        minor = {}, minorOrder = {}, minMinor = 0,
        misc = {}, miscOrder = {},
        start = {},
        base = {},
        progress = mH.initNewTable(0, T.NPC.stats.skills),
        decay = mH.initNewTable(0, T.NPC.stats.skills),
        max = mH.initNewTable(0, T.NPC.stats.skills),
        growth = {
            level = mH.initNewTable(0, T.NPC.stats.skills),
            attributes = mH.initNewTable(0, T.NPC.stats.skills),
        },
        scaled = {
            deltaTime = 0,
            pos = self.position,
            health = mC.self.health.current,
            isOnGround = true,
            groundDist = 0,
            weapon = {},
            armor = {
                skillUsedInFrame = false,
                fortifyHealth = 0,
                drainHealth = 0,
            },
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
        }
    },
    attrs = {
        chargen = {},
        start = {},
        base = {},
        diffs = mH.initNewTable(0, T.Actor.stats.attributes),
    },
    decay = {
        lastDecayTime = 0,
        noDecayTime = mCore.totalGameTimeInHours(),
        noDecayTimeStart = mCore.totalGameTimeInHours(),
        lastPlayerPos = self.position,
    },
    lvlProg = nil,
    healthAttrs = mH.initNewTable(0, mCfg.healthAttributeFactors),
    lastTrainer = nil,
    messagesLog = {},
}

local requests = {}
local lastUpdateHealthTime = 0
local isStarwindMode = mCore.isStarwindMode()
local CRELCells = { ["CREL Start"] = true, ["AB2 Start"] = true }
local chargenUiModes = { ChargenClassReview = true, ChargenClassPick = true, ChargenRace = true, ChargenBirth = true }

local incompatiblePlugins = {}
for _, plugin in ipairs({ "simpleexpscaling.omwscripts", "MBSP_Uncapper.omwscripts", "MBSP.omwscripts", "MBSP ncgdMW edit.omwaddon" }) do
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

---- Core Logic ----

local function setStartAttributes()
    -- Compare chargen attribute average value with grown attributes with current settings and chargen skills
    local startValuesRatio = mS.getAttributeStartValuesRatio(mS.attributesStorage:get("startValuesRatio"))
    local luckGrowthRate = mS.getLuckGrowthRate(mS.attributesStorage:get("luckGrowthRate"))
    for skillId in pairs(T.NPC.stats.skills) do
        mSkills.setSkillGrowths(state, skillId, state.skills.start[skillId], startValuesRatio, luckGrowthRate)
    end
    local growthRate = mS.attributesStorage:get("attributeGrowthRate")
    local growthRateNum = mS.getAttributeGrowthRates(growthRate) - 1
    local chargenAttrSum, alteredAttrSum = 0, 0
    for attrId, value in pairs(state.attrs.chargen) do
        if attrId ~= "luck" then
            chargenAttrSum = chargenAttrSum + value
            alteredAttrSum = alteredAttrSum + value * startValuesRatio + mC.getAttributeGrowth(state, attrId, growthRateNum)
        end
    end
    local startAttrAvg = mH.avg(chargenAttrSum, (#core.stats.Attribute.records - 1))
    local alteredAttrAvg = mH.avg(alteredAttrSum, (#core.stats.Attribute.records - 1))
    local attrAvgDiff = startAttrAvg - alteredAttrAvg
    log(string.format("Attribute averages (growth %s, start ratio %.1f): Start values = %.1f, grown values with current settings and chargen skills = %.1f, diff = %.1f",
            L(growthRate), startValuesRatio, startAttrAvg, alteredAttrAvg, attrAvgDiff))

    for attrId, value in pairs(state.attrs.chargen) do
        if attrId == "luck" then
            state.attrs.start[attrId] = state.attrs.chargen[attrId]
        else
            local start = math.max(5, math.floor(value * startValuesRatio + attrAvgDiff + 0.5))
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

local function init(clearAll)
    print("NCGDMW Lua Edition initialization begins!")

    if state.isCRELMode then
        print("CREL mod detected, changes on attributes and skills starting values will be preserved")
    end
    mS.convertOldSettingValues()
    if not state.isInitialized or not state.isCRELMode then
        mC.setChargenStats(state)
    end
    setStartAttributes()
    local baseStatsMods = mC.getBaseStatsModifiers()

    for attrId, value in pairs(state.attrs.start) do
        state.attrs.base[attrId] = value
        T.Actor.stats.attributes[attrId](self).base = state.attrs.start[attrId] + (baseStatsMods.attributes[attrId] or 0)
        if clearAll or state.attrs.diffs[attrId] == nil then
            state.attrs.diffs[attrId] = 0
        elseif state.attrs.diffs[attrId] ~= 0 then
            log(string.format("Preserving previous \"%s\" external change of %d", attrId, state.attrs.diffs[attrId]))
        end
    end
    state.healthAttrs = mH.initNewTable(0, mCfg.healthAttributeFactors)

    for skillId, getter in pairs(T.NPC.stats.skills) do
        -- Max skills shall not include base skill modifiers
        state.skills.max[skillId] = getter(self).base - (baseStatsMods.skills[skillId] or 0)
    end

    if mS.skillsStorage:get("skillDecayRate") ~= "skillDecayNone" then
        log(string.format("Decay time initialized to %s", state.decay.noDecayTime))
    end

    if not state.profileId then
        initProfileId()
    end

    mSkills.addHandlers(state)
    requests[mDef.requestTypes.refreshStats] = mDef.refreshModes.normal
    requests[mDef.requestTypes.starterSpells] = true

    state.isInitialized = true

    if mS.globalStorage:get("showIntro") then
        -- Wait a few seconds, then flash a message to prompt the user to configure the mod
        async:newSimulationTimer(2, async:registerTimerCallback(
                "newGameGreeting",
                function()
                    mC.showMessage(state, L("doSettings"))
                    log("NCGDMW Lua Edition INIT has ended!")
                end
        ))
    end
end

local function updateGrowth(updateMode)
    local baseStatsMods = mC.getBaseStatsModifiers()
    mSkills.updateSkills(state, baseStatsMods, updateMode)
    local growthRateNum = mS.getAttributeGrowthRates(mS.attributesStorage:get("attributeGrowthRate")) - 1
    local attributesCappedValue = mS.attributesStorage:get("uncapperMaxValue")
    local perAttributeCappedValues = mS.getPerAttributeMaxValues()

    local function growAttribute(attrId)
        local cappedValue = perAttributeCappedValues[attrId] or attributesCappedValue

        -- Update base value in case of manual or uncapper settings changes
        if T.Actor.stats.attributes[attrId](self).base > cappedValue then
            T.Actor.stats.attributes[attrId](self).base = cappedValue
        end

        -- First check for an external change to the attribute. If found, save it to be reapplied later
        local diff = mC.getAttributeDiff(state, attrId, baseStatsMods)

        local growth
        if attrId == "luck" then
            local luckGrowthRate = mS.getLuckGrowthRate(mS.attributesStorage:get("luckGrowthRate"))
            growth = luckGrowthRate * (mC.self.level.current - 1)
            if mS.healthStorage:get("deathCounter") then
                local modifier = mS.healthStorage:get("luckModifierPerDeath")
                local count = storage.playerSection(state.profileId):get("deathCount") or 0
                growth = growth + count * modifier
            end
        else
            -- Calculate growth based on each attribute's related skills
            growth = mC.getAttributeGrowth(state, attrId, growthRateNum)
        end
        local value = growth
                -- Add chargen values
                + state.attrs.start[attrId]
                -- Add external changes
                + diff
                -- Add base modifiers
                + (baseStatsMods.attributes[attrId] or 0)
        value = math.max(5, math.min(value, cappedValue))

        mC.setStat(state, "attributes", attrId, value)
    end

    -- Look at each attribute, determine if it should be recalculated based on its related skills
    for _, attr in ipairs(core.stats.Attribute.records) do
        if attr.id ~= "luck" then
            growAttribute(attr.id)
        end
    end

    requests[mDef.requestTypes.health] = true

    local totalLevel = mC.getTotalPlayerLevel(state)

    state.lvlProg = totalLevel % 1 * 100
    local newLevel = math.max(1, math.floor(totalLevel))

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

    mC.showModStatMessages(state)
end

local function updateHealth(deltaTime)
    lastUpdateHealthTime = lastUpdateHealthTime + (deltaTime or 0.5)
    if lastUpdateHealthTime < 0.5 then return end
    lastUpdateHealthTime = 0

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

    local hpGainRatio = mS.getPerLevelHPGainFactor(mS.healthStorage:get("perLevelHPGain"))
    local currentLevel = mC.self.level.current
    local healthFactor = mC.getHealthFactor(state)
    local maxHealthModifier = mCore.getMaxHealthModifier(self)
    if maxHealthModifier ~= 0 then
        log(string.format("Detected max health modifier: %d", maxHealthModifier))
    end
    local maxHealth = math.floor(healthFactor + (currentLevel - 1) * hpGainRatio * healthFactor + maxHealthModifier)
    local health = mC.self.health
    local prevHealth = health.current
    local ratio = health.current / health.base
    health.base = maxHealth
    health.current = ratio * maxHealth
    if health.current - prevHealth ~= 0 then
        if not mDef.isOpenMW50 then
            mSkills.onHealthModified(state, health.current - prevHealth)
        end
        log(string.format("Player's health changed from %d to %d (diff %d)", prevHealth, health.current, health.current - prevHealth))
    end
end

local function onFrame(deltaTime)
    if not state.isInitialized then return end

    local refreshParam = requests[mDef.requestTypes.refreshStats]
    if refreshParam then
        requests[mDef.requestTypes.refreshStats] = false
        updateGrowth(refreshParam)
    end

    mDecay.onFrame(state, deltaTime)
    mSkills.onFrame()
    mUi.onFrame()
    updateHealth(deltaTime)
end

local function onUpdate(deltaTime)
    if deltaTime == 0 then return end
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
        requests[mDef.requestTypes.refreshStatsOnResume] = true
    end
    if requests[mDef.requestTypes.refreshStatsOnResume] then
        requests[mDef.requestTypes.refreshStatsOnResume] = false
        updateGrowth(mDef.refreshModes.normal)
        requests[mDef.requestTypes.health] = true
    end

    mSkills.onUpdate(state, deltaTime)
end

local function uiModeChanged(data)
    --log(string.format('UI mode changed from %s to %s (%s)', data.oldMode, data.newMode, data.arg))
    if not data.newMode and (data.oldMode == "ChargenClassReview" or state.isInitialized and chargenUiModes[data.oldMode]) then
        requests[mDef.requestTypes.softInit] = true
        state.isInitialized = false
    end

    if not state.isInitialized then return end

    mDecay.onUiModeChanged(state, data)
    mSkills.uiModeChanged(state, data)
end

local function showStatsMenu(data)
    mDecay.updateDecay(state)
    updateGrowth(mDef.refreshModes.normal)
    updateHealth()
    mUi.showStatsMenu(state, data)
end

local function onLoad(data)
    mS.convertOldSettingValues()

    if not data then
        mC.showMessage(state, "No data found in save game, NCGDMW will be initialized")
        return
    end

    if data.savedGameVersion == mDef.savedGameVersion then
        state = data
        requests[mDef.requestTypes.refreshStats] = mDef.refreshModes.normal
        if not state.profileId then
            initProfileId()
        end
        if state.isInitialized then
            mSkills.addHandlers(state)
        end
        return
    end

    requests[mDef.requestTypes.softInit] = true
    mS.migrateOldSettings(data.savedGameVersion)
    if mC.upgradeOldState(state, data) then
        state = data
    end
    mC.showMessage(state, string.format("Old NCGDMW game save detected, upgraded from v%.2f to v%.2f", data.savedGameVersion, mDef.savedGameVersion))
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
        if attrId == nil or T.Actor.stats.attributes[attrId] == nil then
            error(string.format("Invalid attribute id \"%s\""), attrId)
        end
        local changed = false
        if value ~= nil then
            local numValue = tonumber(value)
            if numValue == nil or numValue < 0 then
                error(string.format("Invalid attribute value \"%s\""), value)
            end
            changed = mC.setStat(state, "attributes", attrId, numValue)
        end
        return changed, mC.getStat("attributes", attrId)
    end,
    -- Get a skill value, also set it if value is not nil
    Skill = function(skillId, value)
        if skillId == nil or T.NPC.stats.skills[skillId] == nil then
            error(string.format("Invalid skill id \"%s\""), skillId)
        end
        local changed = false
        if value ~= nil then
            local numValue = tonumber(value)
            if numValue == nil or numValue < 0 then
                error(string.format("Invalid skill value \"%s\""), value)
            end
            changed = mC.setStat(state, "skills", skillId, numValue)
            state.skills.max[skillId] = numValue
            state.skills.decay[skillId] = 0
        end
        return changed, mC.getStat("skills", skillId)
    end,
    -- Get a skill progress value, also set it if value is not nil
    SkillProgress = function(skillId, value)
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
    -- Get skill affected attributes, also set them if attrImpacts is set (map attributeId -> impactValue)
    SkillAffectedAttributes = function(skillId, attrImpacts)
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
        requests[mDef.requestTypes.refreshStatsOnResume] = true
    end,
    -- Get player level process value
    LevelProgress = function()
        return state.lvlProg
    end,
    -- Get player no decay time value (total time in hours without decay)
    NoDecayTime = function()
        return state.decay.noDecayTime
    end,
    -- Reset player's profile stats, useful with old game saves or when some stats are broken
    ResetStats = function()
        init(true)
    end,
    ModHealth = function(value)
        log(string.format("Health externally modified: %.1f", value))
        mSkills.onHealthModified(state, value)
    end,
    AddSkillUsedHandler = function(handler)
        mSkills.addSkillUsedHandler(handler)
    end,
    AddOnHitHandler = function(handler)
        mSkills.addOnHitHandler(handler)
    end,
}

local function onPlayerDeath()
    local count = storage.playerSection(state.profileId):get("deathCount") or 0
    storage.playerSection(state.profileId):set("deathCount", count + 1)
    requests[mDef.requestTypes.refreshStatsOnResume] = true
end

return {
    engineHandlers = {
        onFrame = onFrame,
        onUpdate = onUpdate,
        onKeyPress = function(key) if state.isInitialized then mUi.onKeyPress(key) end end,
        onKeyRelease = mUi.onKeyRelease,
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        Died = onPlayerDeath,
        [mDef.events.showStatsMenu] = showStatsMenu,
        [mDef.events.applySkillUsedHandlers] = function(data) mSkills.applySkillUsedHandlers(state, data.skillId, data.params, data.afterHandler) end,
        [mDef.events.updateRequest] = function(data) requests[data.type] = data.param or true end,
        [mDef.events.onSkillLevelUp] = function(data) mSkills.onSkillLevelUp(state, data.skillId, data.skillLevel, data.source) end,
        [mDef.events.changeDecayRate] = function() if state.isInitialized then mDecay.logDecayTime(state) end end,
        [mDef.events.onActorHit] = function(actor) mSkills.onActorHit(state, actor) end,
        [mDef.events.onPlayerHit] = function(attack) mSkills.onPlayerHit(state, attack) end,
        [mDef.events.onActorAnimHit] = function(data) mSkills.onActorAnimHit(state, data.actor, data.animGroup, data.animKey) end,
        [mDef.events.setWerewolfClawMult] = function(value) mC.werewolfClawMult = value end,
    },
    interfaceName = mDef.MOD_NAME,
    interface = interface
}
