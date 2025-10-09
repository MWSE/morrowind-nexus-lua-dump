local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')
local T = require('openmw.types')
local I = require('openmw.interfaces')

local log = require('scripts.NCGDMW.log')
local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mCore = require('scripts.NCGDMW.core')
local mS = require('scripts.NCGDMW.settings')
local mH = require('scripts.NCGDMW.helpers')

local L = core.l10n(mDef.MOD_NAME)

local currentSerializedBaseStatsMods
local lastUseAnimation
local modStatMessageStack = {}

local module = {}

module.self = {
    health = T.Actor.stats.dynamic.health(self),
    magicka = T.Actor.stats.dynamic.magicka(self),
    fatigue = T.Actor.stats.dynamic.fatigue(self),
    level = T.Actor.stats.level(self),
    inventory = self.type.inventory(self),
    activeEffects = T.Actor.activeEffects(self),
    halfExtents = T.Actor.getPathfindingAgentBounds(self).halfExtents,
}

module.werewolfClawMult = 25

module.showMessage = function(state, ...)
    local arg = { ... }
    ui.showMessage(table.concat(arg, "\n"), { showInDialogue = false })
    for _, message in ipairs(arg) do
        log(message)
        table.insert(state.messagesLog, 1, { message = message, time = os.date("%H:%M:%S") })
        if #state.messagesLog > 12 then
            table.remove(state.messagesLog)
        end
    end
end

module.getTotalPlayerLevel = function(state)
    local levelGain = 1 / mS.skillsStorage:get("classSkillPointsPerLevelUp")
    local totalLevel = 1
    for _, value in pairs(state.skills.growth.level) do
        totalLevel = totalLevel + value * levelGain
    end
    return totalLevel
end

module.getBaseStatsModifiers = function()
    local baseStatsMods = { attributes = {}, skills = {} }
    for _, spell in pairs(T.Actor.activeSpells(self)) do
        if spell.affectsBaseValues then
            for _, effect in pairs(spell.effects) do
                local kind, statId
                if effect.affectedAttribute ~= nil and effect.id == core.magic.EFFECT_TYPE.FortifyAttribute then
                    kind = "attributes"
                    statId = effect.affectedAttribute
                elseif effect.affectedSkill ~= nil and effect.id == core.magic.EFFECT_TYPE.FortifySkill then
                    kind = "skills"
                    statId = effect.affectedSkill
                end
                if kind ~= nil then
                    baseStatsMods[kind][statId] = (baseStatsMods[kind][statId] or 0) + effect.magnitudeThisFrame
                end
            end
        end
    end
    if next(baseStatsMods.attributes) or next(baseStatsMods.skills) then
        local serializedBaseStatsMods = mH.tableOfTablesToString(baseStatsMods)
        if serializedBaseStatsMods ~= currentSerializedBaseStatsMods then
            currentSerializedBaseStatsMods = serializedBaseStatsMods
            log(string.format("Detected base statistics modifiers: %s", serializedBaseStatsMods))
        end
    end
    return baseStatsMods
end

module.getHealthFactor = function(state)
    local baseHPRatio = mS.healthStorage:get("baseHPRatio")
    local factor = baseHPRatio ~= "full" and mS.getBaseHPRatioFactor(baseHPRatio) or 1
    local attrFactor = 0
    for attrId, value in pairs(mCfg.healthAttributeFactors) do
        attrFactor = attrFactor + state.healthAttrs[attrId] * value
    end
    return factor * attrFactor
end

module.getAttributeGrowth = function(state, attrId, growthRateNum)
    local value = 0
    for skillId, attributes in pairs(mCfg.skillsImpactOnAttributes) do
        local impactFactor = attributes[attrId]
        if impactFactor then
            value = value
                    + (mCfg.attributeGrowthFactor * (1 + growthRateNum * mCfg.attributeGrowthFactorIncrease))
                    * state.skills.growth.attributes[skillId]
                    * impactFactor / mCfg.skillsImpactSums[skillId]
        end
    end
    return value
end

module.getAttributeDiff = function(state, attrId, baseStatsMods)
    -- Try to see if something else has modified an attribute and preserve that difference.
    local diff = state.attrs.diffs[attrId]
            + T.Actor.stats.attributes[attrId](self).base
            - (baseStatsMods.attributes[attrId] or 0)
            - state.attrs.base[attrId]
    if diff ~= state.attrs.diffs[attrId] then
        log(string.format("Detected external change %d (previously %d) for \"%s\", base is %d, stored base is %d",
                diff, state.attrs.diffs[attrId], attrId, T.Actor.stats.attributes[attrId](self).base, state.attrs.base[attrId]))
    end
    state.attrs.diffs[attrId] = diff
    return diff
end

module.setChargenStats = function(state)
    local playerRecord = T.NPC.record(self)
    local playerClass = T.NPC.classes.record(playerRecord.class)
    local playerRace = T.NPC.races.record(playerRecord.race)
    local specAttributes = {}
    for _, attrId in ipairs(playerClass.attributes) do
        specAttributes[attrId] = true
    end
    local attributes = {}
    for attrId, value in pairs(playerRace.attributes) do
        if state.isCRELMode then
            attributes[attrId] = T.Actor.stats.attributes[attrId](self).base
        else
            attributes[attrId] = (playerRecord.isMale and value.male or value.female) + (specAttributes[attrId] and 10 or 0)
        end
    end
    state.attrs.chargen = attributes

    local skills = {}
    for _, skill in ipairs(core.stats.Skill.records) do
        skills[skill.id] = 5
        if skill.specialization == playerClass.specialization then
            skills[skill.id] = skills[skill.id] + 5
        end
    end
    for skillId, value in pairs(playerRace.skills) do
        skills[skillId] = skills[skillId] + value
    end
    state.skills.major = {}
    state.skills.majorOrder = {}
    for _, skillId in ipairs(playerClass.majorSkills) do
        state.skills.major[skillId] = true
        table.insert(state.skills.majorOrder, skillId)
        skills[skillId] = skills[skillId] + 25
    end
    state.skills.minor = {}
    state.skills.minorOrder = {}
    for _, skillId in ipairs(playerClass.minorSkills) do
        state.skills.minor[skillId] = true
        table.insert(state.skills.minorOrder, skillId)
        skills[skillId] = skills[skillId] + 10
    end
    state.skills.misc = {}
    state.skills.miscOrder = {}
    for _, skill in ipairs(core.stats.Skill.records) do
        if not state.skills.major[skill.id] and not state.skills.minor[skill.id] then
            state.skills.misc[skill.id] = true
            table.insert(state.skills.miscOrder, skill.id)
        end
        if state.isCRELMode then
            skills[skill.id] = T.NPC.stats.skills[skill.id](self).base
        end
    end
    if core.contentFiles.has("racesrespected.omwscripts") then
        if playerRecord.isMale then
            skills.athletics = skills.athletics + 5
            skills.unarmored = skills.unarmored + 5
            skills.spear = skills.spear + 5
        else
            skills.alchemy = skills.alchemy + 5
            skills.illusion = skills.illusion + 5
            skills.mysticism = skills.mysticism + 5
        end
    end
    state.skills.start = skills
end

module.getStat = function(kind, statId)
    return T.NPC.stats[kind][statId](self).base
end

module.showModStatMessages = function(state)
    local messages = {}
    for _, data in ipairs(modStatMessageStack) do
        table.insert(messages, data.message)
    end
    if #messages > 0 then
        module.showMessage(state, table.unpack(messages))
        modStatMessageStack = {}
    end
end

local function addModStatMessage(kind, statId, prevValue, options)
    options = options or {}
    local current = T.NPC.stats[kind][statId](self).base
    if prevValue == current then return false end
    local toShow
    if kind == "attributes" then
        toShow = current > prevValue and "attrUp" or "attrDown"
    elseif kind == "skills" then
        toShow = current > prevValue and "skillUp" or "skillDown"
    end
    local message = L(toShow, { stat = mCore.getStatName(kind, statId), value = math.floor(current + 0.5) })
    if options.details then
        message = message .. options.details
    end
    local entry = { statId = statId, message = message }
    for i, data in ipairs(modStatMessageStack) do
        -- override previous message if same stat id
        if data.statId == statId then
            modStatMessageStack[i] = entry
            return
        end
    end
    table.insert(modStatMessageStack, entry)
end

module.setStat = function(state, kind, statId, value, options)
    options = options or {}
    value = math.floor(value)
    if kind == "attributes" then
        state.attrs.base[statId] = value - (module.getBaseStatsModifiers()[kind][statId] or 0)
    end
    local current = T.NPC.stats[kind][statId](self).base
    if current == value then
        return false
    end

    T.NPC.stats[kind][statId](self).base = value
    addModStatMessage(kind, statId, current, options)
    return true
end

module.modStat = function(state, kind, stat, value, options)
    return module.setStat(state, kind, stat, T.NPC.stats[kind][stat](self).base + value, options)
end

module.modMagicka = function(amount)
    module.self.magicka.current = module.self.magicka.current + amount
end

module.hasJustMeleeAttacked = function()
    return lastUseAnimation and mCore.meleeNpcAttackGroups[lastUseAnimation.group] and string.sub(lastUseAnimation.key, -3) == "hit"
end

module.hasJustSpellCasted = function()
    return lastUseAnimation and lastUseAnimation.group == "spellcast" and string.sub(lastUseAnimation.key, -7) == "release"
end

module.isLockPicking = function()
    return lastUseAnimation and lastUseAnimation.group == "pickprobe" and lastUseAnimation.key == "start"
end

module.upgradeOldState = function(newState, oldState)
    if oldState.savedGameVersion < 4.0 then
        newState.lvlProg = oldState.lvlProg
        newState.attrs.diffs = oldState.attributeDiffs
        newState.healthAttrs = oldState.healthAttributes
        newState.skills.max = oldState.maxSkills
        newState.skills.progress = oldState.skillProgress
        newState.skills.decay = oldState.decaySkills
        newState.decay.lastDecayTime = oldState.lastDecayTime
        newState.decay.noDecayTime = oldState.noDecayTime
        newState.decay.noDecayTimeStart = oldState.noDecayTimeStart
        newState.messagesLog = oldState.messagesLog
        return false
    end

    if oldState.savedGameVersion < 4.1 then
        oldState.skills.decay = oldState.decay.skills
        oldState.decay.skills = nil
    end

    if oldState.savedGameVersion < 4.3 then
        oldState.skills.scaled = newState.skills.scaled
    end

    if oldState.savedGameVersion < 4.4 then
        oldState.isInitialized = true
    end

    if oldState.savedGameVersion >= 4.5 and oldState.savedGameVersion < 4.52 then
        for skillId in pairs(T.NPC.stats.skills) do
            oldState.skills.max[skillId] = oldState.skills.base[skillId]
        end
    end

    if oldState.savedGameVersion < 4.6 then
        oldState.skills.scaled.weapon = {}
    end

    if oldState.savedGameVersion < 4.62 then
        local prog = T.NPC.stats.skills.mercantile(self).progress
        local stateProg = oldState.skills.mercantile.progress
        if prog ~= prog or prog < 0 or prog > 1 or stateProg ~= stateProg or stateProg < 0 or stateProg > 1 then
            T.NPC.stats.skills.mercantile(self).progress = 0
            oldState.skills.mercantile.progress = 0
        end

        oldState.skills.scaled.acrobatics.maxFallPos = self.position
    end

    return true
end

I.AnimationController.addTextKeyHandler('', function(group, key)
    if mCore.useAttackGroups[group] then
        lastUseAnimation = { group = group, key = key }
    end
end)

return module
