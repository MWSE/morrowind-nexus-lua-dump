local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local T = require('openmw.types')
local util = require('openmw.util')

local log = require('scripts.NCG.util.log')
local mDef = require('scripts.NCG.config.definition')
local mCfg = require('scripts.NCG.config.configuration')
local mS = require('scripts.NCG.config.store')
local mC = require('scripts.NCG.core.common')
local mSkills = require('scripts.NCG.core.skills')
local mHelpers = require('scripts.NCG.util.helpers')

local L = core.l10n(mDef.MOD_NAME)

local module = {}

module.setBaseValue = function(attrId, value)
    local current = T.NPC.stats.attributes[attrId](self).base
    value = math.floor(value)
    if current == value then return end

    T.NPC.stats.attributes[attrId](self).base = value

    if mS.settings.showAttributeChangeNotifications.get() then
        mC.queueMessage(L(value > current and "statUp" or "statDown", { stat = core.stats.Attribute.records[attrId].name, prev = current, value = value }))
    end
end

module.saveInitialValues = function(state, baseAttrMods)
    for attrId, getter in pairs(T.Actor.stats.attributes) do
        state.attrs.init[attrId] = getter(self).base - (baseAttrMods[attrId] or 0)
    end
end

module.saveInitialDiffs = function(state, baseAttrMods)
    for attrId, getter in pairs(T.Actor.stats.attributes) do
        state.attrs.diffs[attrId] = getter(self).base - (baseAttrMods[attrId] or 0) - state.attrs.init[attrId]
        if state.attrs.diffs[attrId] ~= 0 then
            log(string.format("Initial diff for %s is %s", attrId, state.attrs.diffs[attrId]))
        end
    end
end

module.setStartValues = function(state, baseSkillMods)
    baseSkillMods = baseSkillMods or mC.getBaseStatMods().skill
    -- Compare initial attribute average value with grown attributes with current settings and starting skills
    local startValuesRatio = mS.settings.startAttrRatio.get()
    local luckGrowthRate = mS.settings.luckGrowthRate.get()
    -- Compute initial skill growth (based on starting skill values)
    for skillId in pairs(mSkills.getStats()) do
        mSkills.setGrowthForAttributes(state, skillId, state.skills.start[skillId], startValuesRatio, luckGrowthRate, baseSkillMods)
    end
    local growthRate = mS.settings.attrGrowthRate.get()
    local growthRateKey = mS.settings.attrGrowthRate.keys[growthRate]
    local initAttrSum, alteredAttrSum = 0, 0
    for attrId, value in pairs(state.attrs.init) do
        if attrId ~= "luck" then
            initAttrSum = initAttrSum + value
            alteredAttrSum = alteredAttrSum + value * startValuesRatio + module.getGrowth(state, attrId, growthRate)
        end
    end
    -- -1 to remove luck
    local startAttrAvg = mHelpers.avg(initAttrSum, (#core.stats.Attribute.records - 1))
    local alteredAttrAvg = mHelpers.avg(alteredAttrSum, (#core.stats.Attribute.records - 1))
    state.attrs.normValue = startAttrAvg - alteredAttrAvg
    log(string.format(
            "Attribute averages (growth %s, start ratio %.1f): start values = %.1f, grown values with current settings and start skills = %.1f, norm = %.2f",
            L(growthRateKey), startValuesRatio, startAttrAvg, alteredAttrAvg, state.attrs.normValue))

    for attrId, value in pairs(state.attrs.init) do
        if attrId == "luck" then
            state.attrs.start[attrId] = state.attrs.init[attrId]
        else
            local start = math.max(5, util.round(value * startValuesRatio + state.attrs.normValue))
            state.attrs.start[attrId] = start
        end
    end
end

module.setBaseValues = function(state, baseAttrMods)
    for attrId, getter in pairs(T.Actor.stats.attributes) do
        state.attrs.base[attrId] = getter(self).base - (baseAttrMods[attrId] or 0) - state.attrs.diffs[attrId]
        if state.attrs.diffs[attrId] ~= 0 then
            log(string.format("Preserving \"%s\" external change of %d", attrId, state.attrs.diffs[attrId]))
        end
    end
end

module.computeChargenValues = function(state)
    local playerRecord = T.NPC.record(self)
    local playerClass = T.NPC.classes.record(playerRecord.class)
    local playerRace = T.NPC.races.record(playerRecord.race)

    local specAttributes = {}
    for _, attrId in ipairs(playerClass.attributes) do
        specAttributes[attrId] = true
    end
    local attributes = {}
    for attrId, value in pairs(playerRace.attributes) do
        attributes[attrId] = (playerRecord.isMale and value.male or value.female) + (specAttributes[attrId] and 10 or 0)
    end
    state.attrs.init = attributes
end

module.getCappedValue = function(value)
    return value == 0 and math.huge or value
end

module.getPerAttrCappedValues = function()
    local map = {}
    local caps = mS.settings.perAttributeUncapper.get()
    for i = 1, #caps do
        local item = caps[i]
        map[item.key] = module.getCappedValue(item.value)
    end
    return map
end

module.setExternalDiff = function(state, attrId, baseAttrMods)
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

module.getGrowth = function(state, attrId, growthRateNum)
    local value = 0
    for skillId in pairs(mSkills.getStats()) do
        local impactFactor = mCfg.skillImpactOnAttributes[skillId][attrId]
        if impactFactor then
            value = value
                    + mCfg.attributeGrowthFactor
                    * growthRateNum
                    * state.skills.growth[skillId]
                    * impactFactor / mCfg.skillImpactSums[skillId]
        end
    end
    return value
end

module.getLuckGrowth = function(state)
    local luckGrowthRate = mS.settings.luckGrowthRate.get()
    local growth = luckGrowthRate * (mC.self.level.current - 1)
    if mS.settings.deathCounter.get() then
        local count = storage.playerSection(state.profileId):get("deathCount") or 0
        growth = growth + count * mS.settings.luckModifierPerDeath.get()
    end
    return growth
end

return module