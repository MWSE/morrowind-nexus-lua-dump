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
local interfaceVersion = 4
local savedGameVersion = 3.2
local baseTotalStats
local lvlProg = 0
local forceUpdateHealth = false
local lastUpdateHealthTime = 0
local resetStatsAsked = false
local healthAttributeFactors = {
    endurance = 4 / 7,
    strength = 2 / 7,
    willpower = 1 / 7,
}

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

local function getAttributesToRecalculate(baseStatsMods, forceAll)
    local decayRate = decay.getDecayRate()
    local recalculate = {}

    for skillId, getter in pairs(Player.stats.skills) do
        local actualBase = getter(self).base - (baseStatsMods.skills[skillId] or 0)
        local storedBase = C.baseSkills()[skillId]

        if decayRate ~= "none" then
            if storedBase then
                if actualBase > storedBase then
                    decay.decreaseRate(skillId)
                end
            end
        end

        if forceAll or storedBase ~= actualBase then
            if storedBase ~= actualBase then
                C.debugPrint(string.format("Skill \"%s\" has changed from %s to %.2f", skillId, storedBase, actualBase))
            end
            C.baseSkills()[skillId] = actualBase
            local affected = C.affectedAttributes()[skillId]
            if affected then
                for attributeId, _ in pairs(affected) do
                    --C.debugPrint(string.format("\"%s\" should be recalculated!", attributeId))
                    recalculate[attributeId] = true
                end
            end
        end

        if actualBase > C.maxSkills()[skillId] then
            -- C.debugPrint(string.format("Raising stored value for \"%s\"", skillId))
            C.maxSkills()[skillId] = actualBase
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
    C.attributeDiffs()[attributeId] = diff
    return diff
end

local function updatePlayerStats(forceUpdateAttributes)
    local growthRateNum = C.rateMap()[C.getGrowthRate()]
    local baseStatsMods = C.getBaseStatsModifiers()
    local toRecalculate = getAttributesToRecalculate(baseStatsMods, forceUpdateAttributes)
    local attributesChanged = false

    -- Look at each attribute, determine if it should be recalculated based on its related skills
    for attributeId, _ in pairs(toRecalculate) do
        -- First check for an external change to the attribute. If found, save it to be reapplied later
        local diff = attributeDiff(attributeId, baseStatsMods)
        if diff ~= 0 then
            C.debugPrint(string.format("Detected external change %d for \"%s\", base is %d, stored base is %d",
                    diff, attributeId, Player.stats.attributes[attributeId](self).base, C.baseAttributes()[attributeId]))
        end

        -- Calculate XP based on each attribute's related skills
        local total = 0
        for skillId, attributes in pairs(C.affectedAttributes()) do
            local impactFactor = attributes[attributeId]
            if impactFactor then
                total = total + C.baseSkills()[skillId] * C.baseSkills()[skillId] * impactFactor
            end
        end

        -- If the attribute has changed signal to recalculate LUCK
        total = math.floor(math.sqrt(total * growthRateNum / 27)
                + C.startAttributes()[attributeId])
                + diff
                + (baseStatsMods.attributes[attributeId] or 0)
        local changed, _ = I.NCGDMW.Attribute(attributeId, total)
        if changed then
            attributesChanged = true
        end
    end

    if next(toRecalculate) ~= nil then
        C.debugPrint("Checking progression...")
        -- Recalculate level progress
        local totalStats = 0
        for _, value in pairs(C.baseSkills()) do
            totalStats = totalStats + value * value
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
                ui.showMessage(L("lvlUp", { level = newLevel }))
            elseif newLevel < currentLevel then
                ui.showMessage(L("lvlDown", { level = newLevel }))
            end
            Player.stats.level(self).current = newLevel
        end

        if attributesChanged then
            local diff = attributeDiff("luck", baseStatsMods)
            if diff > 0 then
                C.debugPrint(string.format("Adding external change for Luck: %d", diff))
            end
            newLevel = math.floor(math.sqrt(totalStats * growthRateNum / 27) + C.startAttributes().luck) + diff
            I.NCGDMW.Attribute("luck", newLevel)
        end

        decay.recalculateDecayMemory()
    end
end

local function getHealthFactor(attributes)
    local baseHPRatio = S.playerAttributesStorage:get("baseHPRatio")
    local factor = baseHPRatio ~= "full" and S.getBaseHPRatioFactor(baseHPRatio) or 1
    local attributeFactor = 0
    for attributeId, value in pairs(healthAttributeFactors) do
        attributeFactor = attributeFactor + attributes[attributeId] * value
    end
    return factor * attributeFactor
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
        local maxHealth = getHealthFactor(C.healthAttributes())
                + (currentLevel - 1) * getHealthFactor(C.healthAttributes()) / hpGainRatio
                + C.getMaxHealthModifier()
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
    C.debugPrint("NCGDMW Lua Edition INIT begins!")

    C.init()

    local attributes = {}
    if S.isLuaApiRecentEnough then
        -- Get race attributes and class specialized attributes to improve initialization on existing games
        local playerRecord = Player.record(self)
        local specAttributes = {}
        for _, attributeId in ipairs(Player.classes.record(playerRecord.class).attributes) do
            specAttributes[attributeId] = true
        end
        for attributeId, value in pairs(Player.races.record(playerRecord.race).attributes) do
            attributes[attributeId] = (playerRecord.isMale and value.male or value.female) + (specAttributes[attributeId] and 10 or 0)
        end
    else
        for attributeId, getter in pairs(Player.stats.attributes) do
            attributes[attributeId] = getter(self).base
        end
    end

    if not S.isLuaApiRecentEnough and Player.stats.level(self).current == 1 then
        local fortifiedHealth = Player.stats.dynamic.health(self).base - (Player.stats.attributes.strength(self).base + Player.stats.attributes.endurance(self).base) / 2
        if fortifiedHealth > 0 then
            C.setFortifiedHealthV48(fortifiedHealth)
            C.debugPrint(string.format("Detected fortified health: %d", fortifiedHealth))
        end
    end

    local baseStatsMods = C.getBaseStatsModifiers()

    for attributeId, value in pairs(attributes) do
        local newBase = value / 2
        C.baseAttributes()[attributeId] = newBase
        C.startAttributes()[attributeId] = newBase
        if clearAll or C.attributeDiffs()[attributeId] == nil then
            C.attributeDiffs()[attributeId] = 0
        elseif C.attributeDiffs()[attributeId] ~= 0 then
            C.debugPrint(string.format("Preserving previous \"%s\" external change of %d", attributeId, C.attributeDiffs()[attributeId]))
        end
        Player.stats.attributes[attributeId](self).base = newBase + (baseStatsMods.attributes[attributeId] or 0)
        if healthAttributeFactors[attributeId] ~= nil then
            C.healthAttributes()[attributeId] = C.startAttributes()[attributeId]
        else
            C.healthAttributes()[attributeId] = nil
        end
    end

    for skillId, getter in pairs(Player.stats.skills) do
        -- Base skills will be set in getAttributesToRecalculate. Set to nil to detect the new value and update attributes accordingly
        C.baseSkills()[skillId] = nil
        -- Max skills shall not include base skill modifiers
        C.maxSkills()[skillId] = getter(self).base - (baseStatsMods.skills[skillId] or 0)
    end

    decay.init()

    C.setHasStats(true)

    updatePlayerStats(true)

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

local function onConsume(item)
    -- No need to do any record checking if the player already has stats.
    if C.hasStats() then return end

    -- But if we don't have stats, check to see if this
    -- is the right potion and do init() as needed.
    if item.recordId == potionId then
        init(true)
    end
end

local function resetStats(clearAll)
    C.debugPrint("Resetting abilities...")
    for _, activeSpell in pairs(Player.activeSpells(self)) do
        if not activeSpell.fromEquipment then
            C.debugPrint(string.format("Clearing active spell \"%s\"", activeSpell.name))
            Player.activeSpells(self):remove(activeSpell.id)
        end
    end
    for _, spell in pairs(Player.spells(self)) do
        if spell.type == core.magic.SPELL_TYPE.Ability or spell.type == core.magic.SPELL_TYPE.Curse then
            C.debugPrint(string.format("Removing ability spell \"%s\"", spell.name))
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
            C.debugPrint(string.format("Adding ability \"%s\"", spell.name))
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

local function onFrame(deltaTime)
    -- This is a hack to see if we're far enough along in CharGen to have stats
    if not C.hasStats() and not hasOrHadPotion() and input.getControlSwitch(input.CONTROL_SWITCH.ViewMode) then
        init(true)
    elseif C.hasStats() then
        -- Main loop
        if not S.isLuaApiRecentEnough then
            updatePlayerStats(false)
        end
        decay.onFrame(deltaTime)
        mbsp.onFrame(deltaTime)
        doHealth(deltaTime)
    end
end

local function uiModeChanged(data)
    decay.checkJailTime(data)
end

local function addSkillGain(skillId, skillGain)
    local skillRequirement = I.SkillProgression.getSkillProgressRequirement(skillId)
    local progress = Player.stats.skills[skillId](self).progress + skillGain / skillRequirement
    local excessSkillGain = (progress - 1) * skillRequirement
    C.debugPrint(string.format("Add skill \"%s\" gain %.5f (requirement %.5f, excess %.5f), progress %.5f to %.5f",
            skillId, skillGain, skillRequirement, excessSkillGain > 0 and excessSkillGain or 0, Player.stats.skills[skillId](self).progress, progress))
    if excessSkillGain >= 0 then
        C.increaseSkill(skillId)
        if not S.playerSkillsStorage:get("carryOverExcessSkillGain") or
                not S.playerSkillsStorage:get("uncapperEnabled") and Player.stats.skills[skillId](self).base > 99 then
            progress = 0
        else
            Player.stats.skills[skillId](self).progress = 0
            -- Recursive function to allow gaining multiple levels with one skill action (unlikely but possible)
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
            updatePlayerStats(false)
        end
        -- We handle skill level up
        return false
    end)

    I.SkillProgression.addSkillUsedHandler(function(skillId, params)
        C.debugPrint(string.format("Skill \"%s\" used, base gain = %.5f", skillId, params.skillGain))
        local skillIncreaseConstantFactor = S.playerSkillsStorage:get("skillIncreaseConstantFactor")
        if skillIncreaseConstantFactor ~= "vanilla" then
            params.skillGain = params.skillGain / S.getSkillIncreaseConstantFactor(skillIncreaseConstantFactor)
            C.debugPrint(string.format("Skill gain of \"%s\" reduced by constant, new gain = %.5f", skillId, params.skillGain))
        end
        local skillIncreaseSquaredLevelFactor = S.playerSkillsStorage:get("skillIncreaseSquaredLevelFactor")
        if skillIncreaseSquaredLevelFactor ~= "disabled" then
            local skillLevelNorm = Player.stats.skills[skillId](self).base / 100
            params.skillGain = params.skillGain / ((S.getSkillIncreaseSquaredLevelFactor(skillIncreaseSquaredLevelFactor) - 1) * skillLevelNorm * skillLevelNorm + 1)
            C.debugPrint(string.format("Skill gain of \"%s\" reduced by square, new gain = %.5f", skillId, params.skillGain))
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
            C.debugPrint(string.format("Preventing skill \"%s\" level up from book", skillId))
            -- Stop skill level up handlers
            return false
        end
        updatePlayerStats(false)
    end)
end

local function onLoad(data)
    if data then
        baseTotalStats = data.baseTotalStats
        lvlProg = data.lvlProg
        C.onLoad(data)
        decay.onLoad(data)
        if S.isLuaApiRecentEnough and (data.savedGameVersion == nil) then
            resetStatsAsked = true
        else
            updatePlayerStats(true)
            updateHealth()
        end
    end
end

local function onActive()
    if resetStatsAsked then
        resetStatsAsked = false
        resetStats(false)
    end
end

local function onSave()
    local data = {
        savedGameVersion = savedGameVersion,
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
            if not C.vanillaAttributes()[name] then
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
    end,
    ResetStats = function()
        if not S.isLuaApiRecentEnough then
            print("Resetting stats can only be done with a recent enough OpenMW 0.49 version.")
            return
        end
        resetStats(true)
    end
}

local function showStatsMenu()
    updatePlayerStats(true)
    updateHealth()
    ncgdUI.showStatsMenu()
end

return {
    engineHandlers = {
        onConsume = onConsume,
        onFrame = onFrame,
        onKeyPress = ncgdUI.onKeyPress,
        onKeyRelease = ncgdUI.onKeyRelease,
        onLoad = onLoad,
        onSave = onSave,
        onActive = onActive,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        updatePlayerStats = updatePlayerStats,
        updatePlayerStatsAndHealth = function(forceUpdateAttributes)
            updatePlayerStats(forceUpdateAttributes)
            updateHealth()
        end,
        showStatsMenu = showStatsMenu,
        updateHealth = updateHealth,
        logDecayTime = decay.logDecayTime,
    },
    interfaceName = S.MOD_NAME,
    interface = interface
}
