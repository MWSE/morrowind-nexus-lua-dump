local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local T = require('openmw.types')

local log = require('scripts.NCG.util.log')
local mDef = require('scripts.NCG.config.definition')
local mCfg = require('scripts.NCG.config.configuration')
local mCore = require('scripts.NCG.util.core')
local mS = require('scripts.NCG.config.settings')
local mH = require('scripts.NCG.util.helpers')

local L = core.l10n(mDef.MOD_NAME)

local currBaseStatModsKey
local modAttrMessageStack = {}

local module = {}

module.self = {
    health = T.Actor.stats.dynamic.health(self),
    level = T.Actor.stats.level(self),
}

module.showMessage = function(state, ...)
    local arg = { ... }
    ui.showMessage(table.concat(arg, "\n"), { showInDialogue = false })
    for _, message in ipairs(arg) do
        log(message)
        table.insert(state.messagesLog, 1, { message = message, time = os.date("%H:%M:%S") })
        if #state.messagesLog > 25 then
            table.remove(state.messagesLog)
        end
    end
end

module.setPlayerLevelStats = function(state)
    local skillUps = 0
    for _, value in pairs(state.skills.growth.level) do
        skillUps = skillUps + value
    end
    state.level.skillUpsPerLevel = mS.globalStorage:get("classSkillPointsPerLevelUp")
    state.level.skillUps = skillUps
    state.level.prog = (skillUps % state.level.skillUpsPerLevel) / state.level.skillUpsPerLevel
    state.level.value = 1 + math.max(0, math.floor(state.level.skillUps / state.level.skillUpsPerLevel))
end

module.getBaseStatMods = function()
    local baseStatMods = { attr = {}, skill = {} }
    for _, spell in pairs(T.Actor.activeSpells(self)) do
        if spell.affectsBaseValues then
            for _, effect in pairs(spell.effects) do
                if effect.affectedAttribute and effect.id == core.magic.EFFECT_TYPE.FortifyAttribute then
                    baseStatMods.attr[effect.affectedAttribute] = (baseStatMods.attr[effect.affectedAttribute] or 0) + effect.magnitudeThisFrame
                end
                if effect.affectedSkill and effect.id == core.magic.EFFECT_TYPE.FortifySkill then
                    baseStatMods.skill[effect.affectedSkill] = (baseStatMods.skill[effect.affectedSkill] or 0) + effect.magnitudeThisFrame
                end
            end
        end
    end
    if next(baseStatMods) then
        local baseStatModsKey = string.format("(%s, %s)", mH.mapToString(baseStatMods.attr), mH.mapToString(baseStatMods.skill))
        if baseStatModsKey ~= currBaseStatModsKey then
            currBaseStatModsKey = baseStatModsKey
            log(string.format("Detected new base stats modifiers: %s", baseStatModsKey))
        end
    end
    return baseStatMods
end

module.getHealthFactor = function(state)
    local factor = mS.getBaseHPFactor()
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

module.getLuckGrowth = function(state)
    local luckGrowthRate = mS.getLuckGrowthRate()
    local growth = luckGrowthRate * (module.self.level.current - 1)
    if mS.healthStorage:get("deathCounter") then
        local modifier = mS.healthStorage:get("luckModifierPerDeath")
        local count = storage.playerSection(state.profileId):get("deathCount") or 0
        growth = growth + count * modifier
    end
    return growth
end

module.getAttributeDiff = function(state, attrId, baseAttrMods)
    -- Try to see if something else has modified an attribute and preserve that difference.
    local diff = T.Actor.stats.attributes[attrId](self).base
            - (baseAttrMods[attrId] or 0)
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

    local startSkills = {}
    for _, skill in ipairs(core.stats.Skill.records) do
        startSkills[skill.id] = 5
        if skill.specialization == playerClass.specialization then
            startSkills[skill.id] = startSkills[skill.id] + 5
        end
    end
    for skillId, value in pairs(playerRace.skills) do
        startSkills[skillId] = startSkills[skillId] + value
    end
    state.skills.major = {}
    for _, skillId in ipairs(playerClass.majorSkills) do
        state.skills.major[skillId] = true
        startSkills[skillId] = startSkills[skillId] + 25
    end
    state.skills.minor = {}
    for _, skillId in ipairs(playerClass.minorSkills) do
        state.skills.minor[skillId] = true
        startSkills[skillId] = startSkills[skillId] + 10
    end
    state.skills.misc = {}
    for _, skill in ipairs(core.stats.Skill.records) do
        if not state.skills.major[skill.id] and not state.skills.minor[skill.id] then
            state.skills.misc[skill.id] = true
        end
        if state.isCRELMode then
            startSkills[skill.id] = T.NPC.stats.skills[skill.id](self).base
        end
    end
    if playerRecord.race == "argonian" and core.contentFiles.has("racesrespected.omwscripts") then
        if playerRecord.isMale then
            startSkills.athletics = startSkills.athletics + 5
            startSkills.unarmored = startSkills.unarmored + 5
            startSkills.spear = startSkills.spear + 5
        else
            startSkills.alchemy = startSkills.alchemy + 5
            startSkills.illusion = startSkills.illusion + 5
            startSkills.mysticism = startSkills.mysticism + 5
        end
    end
    state.skills.start = startSkills
end

module.showModAttrMessages = function(state)
    if #modAttrMessageStack > 0 then
        module.showMessage(state, table.unpack(modAttrMessageStack))
        modAttrMessageStack = {}
    end
end

module.setAttr = function(attrId, value)
    local current = T.NPC.stats.attributes[attrId](self).base
    value = math.floor(value)
    if current == value then return end

    T.NPC.stats.attributes[attrId](self).base = value

    local toShow = value > current and "attrUp" or "attrDown"
    if mS.attributesStorage:get("showAttributeChangeNotifications") then
        local message = L(toShow, { stat = mCore.getAttrName(attrId), value = value })
        table.insert(modAttrMessageStack, message)
    end
end

module.upgradeOldState = function(oldState)
    if type(mS.globalStorage:get("messagesLogKey")) == "number" then
        mS.globalStorage:set("messagesLogKey", "")
    end
    if oldState.savedGameVersion < 1.31 then
        oldState.bitterCup = {}
    end
    return true
end

return module
