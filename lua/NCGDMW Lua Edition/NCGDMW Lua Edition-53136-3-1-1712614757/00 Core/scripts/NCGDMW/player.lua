local core = require('openmw.core')
local async = require('openmw.async')
local input = require('openmw.input')
local self = require('openmw.self')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local Player = require('openmw.types').Player

local S = require('scripts.NCGDMW.settings')
-- Init settings first to init storage which is used everywhere
S.initSettings()

local C = require('scripts.NCGDMW.common')
local ncgdUI = require("scripts.NCGDMW.ui")
local decay = require('scripts.NCGDMW.decay')
local mbsp = require('scripts.NCGDMW.mbsp')

local L = core.l10n(S.MOD_NAME)

local potionId = "ncgd_start_potion"
local interfaceVersion = 3
local baseTotalStats
local forceUpdateHealth = false
local lvlProg = 0
local lastUpdateHealthTime = 0

local hasPlugins
if S.isLuaApiRecentEnough then
    hasPlugins = core.contentFiles.has("ncgdmw.omwaddon")
            or core.contentFiles.has("ncgdmw_alt_start.omwaddon")
            or core.contentFiles.has("ncgdmw_starwind.omwaddon")
else
    hasPlugins = core.getGMST("iLevelupMajorMult") == 0
            and core.getGMST("iLevelupMinorMult") == 0
end
if not hasPlugins then
    ui.create(ncgdUI.missingPluginWarning())
    print(L("noPluginError0"))
    print(L("noPluginError1"))
    print(L("noPluginError2"))
    print(L("noPluginError3"))
    print(L("noPluginError4"))
    print(L("noPluginError5"))
    print(L("noPluginError6"))
    return
end

if S.isLuaApiRecentEnough then
    if core.contentFiles.has("ncgdmw-vanilla-birthsigns-patch.omwaddon") then
        ui.showMessage(L("dontUseBirthsignsPlugin"))
        print(L("dontUseBirthsignsPlugin"))
    end
    if core.contentFiles.has("ncgdmw_starwind.omwaddon") then
        print(L("autoStarwind"))
        S.playerGlobalStorage:set("starwindNames", true)
    end
end

if S.isOpenMW049 then
    if S.isLuaApiRecentEnough then
        C.debugPrint("OpenMW 0.49.0 detected. Lua API recent enough for all features.")
    else
        C.debugPrint("OpenMW 0.49.0 detected. Lua API too old for recent features.")
    end
else
    C.debugPrint("OpenMW 0.48.0 detected. Some features will be disabled.")
end

---- Core Logic ----

local function getAttributesToRecalculate()
    local decayRate = decay.getDecayRateNum()
    local recalculate = {}

    for skillId, getter in pairs(Player.stats.skills) do
        local stat = getter(self)
        local actualBase = stat.base
        local storedBase = C.baseSkills()[skillId]

        if decayRate > C.rateValues().none then
            if storedBase then
                if actualBase > storedBase then
                    decay.decreaseRate(skillId)
                end
            end
        end

        if storedBase ~= actualBase then
            C.baseSkills()[skillId] = actualBase
            local affected = C.affectedAttributes()[skillId]
            if affected then
                for attribute, _ in pairs(affected) do
                    --C.debugPrint("%s should be recalculated!", attribute)
                    recalculate[attribute] = true
                end
            end
        end

        if actualBase > C.maxSkills()[skillId] then
            -- C.debugPrint("Raising stored value for %s", id)
            C.maxSkills()[skillId] = actualBase
        end
    end
    return recalculate
end

local function handleBirthsigns()
    if not S.isLuaApiRecentEnough then return end

    local signsMap = {
        ["charioteer ability"] = "ncgdmw_charioteer",
        ["mooncalf ability"] = "ncgdmw_mooncalf",
        ["lady's favor"] = "ncgdmw_ladys_favor",
        ["lady's grace"] = "ncgdmw_ladys_grace"
    }

    for _, spell in pairs(Player.spells(self)) do
        local spellId = string.lower(spell.id)
        local newSpell = signsMap[spellId]
        if newSpell then
            C.debugPrint("Birthsigns: Removing %s and adding %s", spellId, newSpell)
            Player.activeSpells(self):remove(spellId)
            Player.spells(self):remove(spellId)
            Player.spells(self):add(newSpell)
        end
    end
end

local function refreshBirthsigns()
    if not S.isLuaApiRecentEnough then return end

    local signsMap = {
        ["ncgdmw_charioteer"] = true,
        ["ncgdmw_mooncalf"] = true,
        ["ncgdmw_ladys_favor"] = true,
        ["ncgdmw_ladys_grace"] = true
    }

    for _, spell in pairs(Player.spells(self)) do
        local spellId = string.lower(spell.id)
        if signsMap[spellId] then
            C.debugPrint("Birthsigns: Refreshing %s", spellId)
            Player.activeSpells(self):remove(spellId)
            Player.spells(self):remove(spellId)
            Player.spells(self):add(spellId)
        end
    end
end

local function init()
    C.debugPrint("NCGDMW Lua Edition INIT begins!")

    for id, getter in pairs(Player.stats.attributes) do
        local stat = getter(self)
        C.attributeDiffs()[id] = 0
        local newBase = stat.base / 2
        C.baseAttributes()[id] = newBase
        C.startAttributes()[id] = newBase
        stat.base = newBase
        if id == 'endurance' or id == 'strength' or id == 'willpower' then
            C.healthAttributes()[id] = C.startAttributes()[id]
        end
    end
    for id, getter in pairs(Player.stats.skills) do
        C.maxSkills()[id] = getter(self).base
    end

    decay.init()

    C.setHasStats(true)

    if S.playerGlobalStorage:get("showIntro") then
        -- Wait a few seconds, then flash a message to prompt the user to configure the mod
        async:newSimulationTimer(
                2,
                async:registerTimerCallback(
                        "newGameGreeting",
                        function()
                            ui.showMessage(L("doSettings"))
                            C.debugPrint("NCGDMW Lua Edition INIT has ended!")
                        end
                )
        )
    end
end

local function attributeDiff(a)
    -- Try to see if something else has modified an attribute and preserve that difference.
    local diff = C.attributeDiffs()[a] + Player.stats.attributes[a](self).base - C.baseAttributes()[a]
    C.attributeDiffs()[a] = diff
    return diff
end

local function updatePlayerStats()
    local growthRate = C.getGrowthRateNum()
    local toRecalculate = getAttributesToRecalculate()
    local checkProgression = false
    local recalculateLuck = false

    -- Look at each attribute, determine if it should be recalculated based on its related skills
    for attribute, _ in pairs(toRecalculate) do
        -- Some attributes are being recalculated so we should also check level progression
        checkProgression = true

        -- First check for an external change to the attribute. If found, save it to be reapplied later
        local diff = attributeDiff(attribute)
        if diff > 0 then
            C.debugPrint("Adding external change for %s: %d", attribute, diff)
        end

        -- Calculate XP based on each attribute's related skills
        local total = 0
        for skill, attributes in pairs(C.affectedAttributes()) do
            local mult = attributes[attribute]
            if mult then
                total = total + C.baseSkills()[skill] * C.baseSkills()[skill] * mult
            end
        end

        -- If the attribute has changed signal to recalculate LUCK
        total = math.floor(math.sqrt(total * growthRate / 27) + C.startAttributes()[attribute]) + diff
        local changed, _ = I.NCGDMW.Attribute(attribute, total)
        if changed then
            recalculateLuck = true
        end
    end

    if checkProgression then
        -- Recalculate level progress
        local totalStats = 0
        for _, value in pairs(C.baseSkills()) do
            totalStats = totalStats + value * value
        end
        local tot = math.sqrt(totalStats * 2 / 27)

        local current = Player.stats.level(self).current
        if baseTotalStats == nil then
            baseTotalStats = tot - current - Player.stats.level(self).progress / core.getGMST("iLevelupTotal")
        end
        tot = tot - baseTotalStats

        lvlProg = math.floor(tot % 1 * 100)
        local total = math.floor(tot)

        if total ~= current then
            forceUpdateHealth = true
        end

        -- Something changed, show a message to the player
        if total > 0 then
            if total > current then
                ui.showMessage(L("lvlUp", { level = total }))
            elseif total < current then
                ui.showMessage(L("lvlDown", { level = total }))
            end
            Player.stats.level(self).current = total
        end

        if recalculateLuck then
            local diff = attributeDiff("luck")
            if diff > 0 then
                C.debugPrint("Adding external change for Luck: %d", diff)
            end
            total = math.floor(math.sqrt(totalStats * growthRate / 27) + C.startAttributes().luck) + diff
            I.NCGDMW.Attribute("luck", total)

            decay.recalculateDecayMemory()
        end
    end
end

local function getHealthFactor(attributes)
    local baseHPRatio = S.playerAttributesStorage:get("baseHPRatio")
    local factor = baseHPRatio ~= "full" and S.getBaseHPRatioFactor(baseHPRatio) or 1
    return factor * (attributes.endurance * 4 + attributes.strength * 2 + attributes.willpower) / 7
end

local function doHealth(deltaTime)
    lastUpdateHealthTime = lastUpdateHealthTime + deltaTime
    if lastUpdateHealthTime < 0.5 then return end
    lastUpdateHealthTime = 0

    local recalculate = false
    local stateBasedHP = S.playerAttributesStorage:get("stateBasedHP")
    for attribute, value in pairs(C.healthAttributes()) do
        local current
        if stateBasedHP then
            current = Player.stats.attributes[attribute](self).modified
        else
            current = Player.stats.attributes[attribute](self).base
        end
        if current ~= value then
            C.healthAttributes()[attribute] = current
            recalculate = true
        end
    end
    if recalculate or forceUpdateHealth then
        local hpGainRatio = 10
        if S.playerAttributesStorage:get("perLevelHPGain") == "low" then
            hpGainRatio = 20
        end
        forceUpdateHealth = false
        local currentLevel = Player.stats.level(self).current
        local maxHealth = getHealthFactor(C.healthAttributes()) + (currentLevel - 1) * getHealthFactor(C.healthAttributes()) / hpGainRatio
        local health = Player.stats.dynamic.health(self)
        local ratio = health.current / health.base
        health.base = maxHealth
        health.current = ratio * maxHealth
    end
end

local function updatePlayer()
    forceUpdateHealth = true
end

local function hasOrHadPotion()
    -- Even if the player isn't using the alt start version, if they have stats
    -- then for all intents and purposes they may as well have had the potion.
    if C.hasStats() then return true end

    -- Being in possession of the potion will prevent init()
    -- from running on its own (see "onConsume" below).
    if S.isLuaApiRecentEnough then
        return #Player.inventory(self):findAll(potionId) > 0
    else
        return Player.inventory(self):countOf(potionId) > 0
    end
end

local function onConsume(item)
    -- No need to do any record checking if the player already has stats.
    if C.hasStats() then return end

    -- But if we don't have stats, check to see if this
    -- is the right potion and do init() as needed.
    if item.recordId == potionId then
        init()
    end
end

local initializing = false
local function onFrame(deltaTime)
    -- This is a hack to see if we're far enough along in CharGen to have stats
    if not initializing and not C.hasStats() and not hasOrHadPotion() and input.getControlSwitch(input.CONTROL_SWITCH.ViewMode) then
        initializing = true
        handleBirthsigns()
        -- Wait a short time in order to birthsign curses trick to properly apply on player
        async:newSimulationTimer(
                1,
                async:registerTimerCallback(
                        "init",
                        function()
                            init()
                            updatePlayerStats()
                            initializing = false
                        end
                )
        )

    elseif not initializing and C.hasStats() then
        -- Main loop
        if not S.isLuaApiRecentEnough then
            updatePlayerStats()
        end
        decay.onFrame(deltaTime)
        mbsp.onFrame(deltaTime)
        doHealth(deltaTime)
    end
end

local function uiModeChanged(data)
    decay.checkJailTime(data)
end

-- Recursive function to allow gaining multiple levels with one skill action (unlikely but possible)
local function addSkillGain(skillId, skillGain)
    local skillRequirement = I.SkillProgression.getSkillProgressRequirement(skillId)
    local progress = Player.stats.skills[skillId](self).progress + skillGain / skillRequirement
    local excessSkillGain = (progress - 1) * skillRequirement
    C.debugPrint("Add skill %s gain %s (requirement %s, excess %s), progress %s to %s",
            skillId, skillGain, skillRequirement, excessSkillGain, Player.stats.skills[skillId](self).progress, progress)
    if excessSkillGain >= 0 then
        C.increaseSkill(skillId)
        if not S.playerSkillsStorage:get("carryOverExcessSkillGain") or
                not S.playerSkillsStorage:get("uncapperEnabled") and Player.stats.skills[skillId](self).base > 99 then
            progress = 0
        else
            Player.stats.skills[skillId](self).progress = 0
            addSkillGain(skillId, excessSkillGain)
            return
        end
    end
    C.skillProgress()[skillId] = progress
    Player.stats.skills[skillId](self).progress = progress
end

if S.isLuaApiRecentEnough then
    I.SkillProgression.addSkillUsedHandler(function(skillId, params)
        local skillLevel = Player.stats.skills[skillId](self).base
        addSkillGain(skillId, params.skillGain)
        if skillLevel ~= Player.stats.skills[skillId](self).base then
            updatePlayerStats()
        end
        -- We handle skill level up
        return false
    end)

    I.SkillProgression.addSkillUsedHandler(function(skillId, params)
        C.debugPrint("Skill '%s' used, base gain = %s", skillId, params.skillGain)
        local skillIncreaseConstantFactor = S.playerSkillsStorage:get("skillIncreaseConstantFactor")
        if skillIncreaseConstantFactor ~= "vanilla" then
            params.skillGain = params.skillGain / S.getSkillIncreaseConstantFactor(skillIncreaseConstantFactor)
            C.debugPrint("Skill gain of '%s' reduced by constant, new gain = %s", skillId, params.skillGain)
        end
        local skillIncreaseSquaredLevelFactor = S.playerSkillsStorage:get("skillIncreaseSquaredLevelFactor")
        if skillIncreaseSquaredLevelFactor ~= "disabled" then
            local skillLevelNorm = Player.stats.skills[skillId](self).base / 100
            params.skillGain = params.skillGain / ((S.getSkillIncreaseSquaredLevelFactor(skillIncreaseSquaredLevelFactor) - 1) * skillLevelNorm * skillLevelNorm + 1)
            C.debugPrint("Skill gain of '%s' reduced by square, new gain = %s", skillId, params.skillGain)
        end
    end)

    I.SkillProgression.addSkillUsedHandler(mbsp.getSkillUsedHandler())

    I.SkillProgression.addSkillUsedHandler(function(skillId, _)
        if not S.playerSkillsStorage:get("uncapperEnabled") and Player.stats.skills[skillId](self).base > 99 then
            Player.stats.skills[skillId](self).progress = 0
            -- Stop skill used handlers
            return false
        end
    end)

    I.SkillProgression.addSkillLevelUpHandler(function(skillId, source)
        if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Book and not S.playerSkillsStorage:get("skillIncreaseFromBooks") then
            C.debugPrint("Preventing skill '%s' level up from book", skillId)
            -- Stop skill level up handlers
            return false
        end
        updatePlayerStats()
    end)
end

local function onLoad(data)
    if data then
        baseTotalStats = data.baseTotalStats
        lvlProg = data.lvlProg
        C.onLoad(data)
        decay.onLoad(data)
        updatePlayer()
    end
    refreshBirthsigns()
end

local function onSave()
    local data = {
        baseTotalStats = baseTotalStats,
        lvlProg = lvlProg,
    }
    C.onSave(data)
    decay.onSave(data)
    return data
end

-- Public interface
local interface = {
    version = interfaceVersion,
    Attribute = function(name, val)
        local changed
        if name ~= nil then
            if C.vanillaAttributes()[name] == nil then
                print("NCGDMW/Interface/Attribute(): Invalid attribute name given")
                return
            end
            if val ~= nil then
                changed = C.setStat("attributes", name, val)
            end
            return changed, C.getStat("attributes", name)
        else
            print("NCGDMW/Interface/Attribute(): No attribute name given")
        end
    end,
    LevelProgress = function(raw)
        if raw then
            return lvlProg
        else
            return tostring(lvlProg) .. "%"
        end
    end,
    ShowNoDecayTime = function()
        print(decay.noDecayTime())
    end
}

return {
    engineHandlers = {
        onConsume = onConsume,
        onFrame = onFrame,
        onKeyPress = ncgdUI.onKeyPress,
        onKeyRelease = ncgdUI.onKeyRelease,
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        updatePlayerStats = updatePlayerStats,
        updatePlayer = updatePlayer,
        logDecayTime = decay.logDecayTime,
    },
    interfaceName = S.MOD_NAME,
    interface = interface
}
