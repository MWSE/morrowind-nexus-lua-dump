local core = require('openmw.core')
local ambient = require('openmw.ambient')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local Player = require('openmw.types').Player

local log = require('scripts.NCGDMW.log')
local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mSettings = require('scripts.NCGDMW.settings')
local mCommon = require('scripts.NCGDMW.common')
local mDecay = require('scripts.NCGDMW.decay')
local mSpells = require('scripts.NCGDMW.spells')
local mHelpers = require('scripts.NCGDMW.helpers')

local Skills = core.stats.Skill.records
local L = core.l10n(mDef.MOD_NAME)

local magickaSkills = {
    [Skills.destruction.id] = true,
    [Skills.restoration.id] = true,
    [Skills.conjuration.id] = true,
    [Skills.mysticism.id] = true,
    [Skills.illusion.id] = true,
    [Skills.alteration.id] = true,
}

local weaponSkills = {
    [Skills.handtohand.id] = true,
    [Skills.axe.id] = true,
    [Skills.bluntweapon.id] = true,
    [Skills.longblade.id] = true,
    [Skills.marksman.id] = true,
    [Skills.shortblade.id] = true,
    [Skills.spear.id] = true,
}

local skillOrder = {}
for i, skill in ipairs(Skills) do
    skillOrder[skill.id] = i
end

local spellSchoolRatios = {}
local modifiedTrainingSkills = {}
local weaponSpeeds = {}

local module = {}

local function setSkillGrowths(state, skillId, skillValue, startValuesRatio, luckGrowthRate)
    state.skills.growth.level[skillId] = state.skills.misc[skillId] and 0 or skillValue - state.skills.start[skillId]

    local attrGrowth = skillValue - startValuesRatio * state.skills.start[skillId]
    local settingKey = state.skills.major[skillId] and "Major" or (state.skills.minor[skillId] and "Minor" or "Misc")
    state.skills.growth.attributes[skillId] = attrGrowth
            * mSettings.attributesStorage:get("growthFactorFrom" .. settingKey .. "Skills") / 100
            * (1 - luckGrowthRate / 4)
end
module.setSkillGrowths = setSkillGrowths

local function updateSkills(state, baseStatsMods, allAttrs)
    local attributesToUpdate = {}
    local decayEnabled = mSettings.skillsStorage:get("skillDecayRate") ~= "skillDecayNone"
    local skillsMaxValue = mSettings.skillsStorage:get("uncapperMaxValue")
    local perSkillMaxValues = mSettings.getPerSkillMaxValues()
    local startValuesRatio = mSettings.getAttributeStartValuesRatio(mSettings.attributesStorage:get("startValuesRatio"))
    local luckGrowthRate = mSettings.getLuckGrowthRate(mSettings.attributesStorage:get("luckGrowthRate"))

    for skillId, getter in pairs(Player.stats.skills) do
        local maxValue = perSkillMaxValues[skillId] or skillsMaxValue

        -- Update base and max values in case of manual or uncapper settings changes
        if getter(self).base > maxValue then
            mCommon.setStat(state, "skills", skillId, maxValue)
        end
        state.skills.max[skillId] = math.min(state.skills.max[skillId], maxValue)

        local actualBase = getter(self).base - (baseStatsMods.skills[skillId] or 0)
        if not decayEnabled or actualBase > state.skills.max[skillId] then
            state.skills.max[skillId] = actualBase
        end

        local storedBase = state.skills.base[skillId]

        if allAttrs or storedBase ~= actualBase then
            if storedBase ~= actualBase then
                if storedBase ~= nil then
                    log(string.format("Skill \"%s\" has changed from %s to %s", skillId, storedBase, actualBase))
                end
                if (storedBase == nil or actualBase > storedBase) and decayEnabled then
                    mDecay.slowDownSkillDecayOnSkillLevelUp(state, skillId)
                end
            end

            state.skills.base[skillId] = actualBase

            -- Update skill progress to actual value, because:
            -- - skill increases from the console, books or training alters the progression
            -- - skill progresses need to be set for mid-game installs
            state.skills.progress[skillId] = Player.stats.skills[skillId](self).progress

            setSkillGrowths(state, skillId, state.skills.base[skillId], startValuesRatio, luckGrowthRate)

            for attrId, _ in pairs(mCfg.skillsImpactOnAttributes[skillId]) do
                --log(string.format("\"%s\" should be recalculated!", attrId))
                attributesToUpdate[attrId] = true
            end
        end
    end
    if next(attributesToUpdate) then
        state.skills.minMajor = math.huge
        for skillId in pairs(state.skills.major) do
            state.skills.minMajor = math.min(state.skills.base[skillId], state.skills.minMajor)
        end
        state.skills.minMinor = math.huge
        for skillId in pairs(state.skills.minor) do
            state.skills.minMinor = math.min(state.skills.base[skillId], state.skills.minMinor)
        end
    end
    return attributesToUpdate
end
module.updateSkills = updateSkills

local function restoreTrainingSkills()
    for skillId, value in pairs(modifiedTrainingSkills) do
        types.NPC.stats.skills[skillId](self).base = value
    end
    modifiedTrainingSkills = {}
end
module.restoreTrainingSkills = restoreTrainingSkills

local function getTrainingSkillIds(npc)
    local skills = {}
    for skillId in mHelpers.spairs(types.NPC.stats.skills,
            function(t, a, b)
                return t[a](npc).modified == t[b](npc).modified
                        and skillOrder[a] < skillOrder[b]
                        or t[a](npc).modified > t[b](npc).modified
            end) do
        table.insert(skills, skillId)
        if #skills == 3 then
            return skills
        end
    end
end

local function capTrainedSkills(state, uiData)
    if not mSettings.skillsStorage:get("capSkillTraining") then return end

    if uiData.newMode == "Training" then
        local npc = uiData.arg
        local skillIds = getTrainingSkillIds(npc)
        local messages = {}
        modifiedTrainingSkills = {}
        for _, skillId in ipairs(skillIds) do
            local skill = types.NPC.stats.skills[skillId]
            if skill(self).modified < skill(npc).modified then
                local msgKey
                if state.skills.minor[skillId] and state.skills.base[skillId] >= state.skills.minMajor then
                    msgKey = "skillTrainingCapMinor"
                end
                if state.skills.misc[skillId] and state.skills.base[skillId] >= state.skills.minMinor then
                    msgKey = "skillTrainingCapMisc"
                end
                if msgKey then
                    modifiedTrainingSkills[skillId] = skill(self).base
                    skill(self).base = skill(npc).modified - skill(self).modifier
                    table.insert(messages, L(msgKey, { skill = Skills[skillId].name }))
                end
            end
        end
        if #messages > 0 and (not state.lastTrainer or state.lastTrainer.id ~= npc.id) then
            state.lastTrainer = npc
            for _, message in ipairs(messages) do
                mCommon.showMessage(state, message)
            end
        end
    elseif uiData.oldMode == "Training" then
        restoreTrainingSkills()
    end
end
module.capTrainedSkills = capTrainedSkills

---- Skill handlers ----

local function addSkillGain(state, skillId, skillGain)
    local skillRequirement = I.SkillProgression.getSkillProgressRequirement(skillId)
    local progress = Player.stats.skills[skillId](self).progress + skillGain / skillRequirement
    local excessSkillGain = (progress - 1) * skillRequirement
    log(string.format("Add skill \"%s\" gain %.5f (requirement %.5f, excess %.5f), progress %.5f to %.5f",
            skillId, skillGain, skillRequirement, excessSkillGain > 0 and excessSkillGain or 0, Player.stats.skills[skillId](self).progress, progress))
    if excessSkillGain >= 0 then
        mCommon.modStat(state, "skills", skillId, 1)
        if not mSettings.skillsStorage:get("carryOverExcessSkillGain") or
                Player.stats.skills[skillId](self).base >= mSettings.getSkillMaxValue(skillId) then
            progress = 0
        else
            Player.stats.skills[skillId](self).progress = 0
            -- Recursive function to allow gaining multiple levels with one skill action (unlikely but possible)
            addSkillGain(state, skillId, excessSkillGain)
            return
        end
    end
    state.skills.progress[skillId] = progress
    Player.stats.skills[skillId](self).progress = progress
end
module.addSkillGain = addSkillGain

local function skillUsedHandlerFinal(state, skillId, params)
    local skillLevel = Player.stats.skills[skillId](self).base
    addSkillGain(state, skillId, params.skillGain)
    if skillLevel ~= Player.stats.skills[skillId](self).base then
        ambient.playSound("skillraise")
        self:sendEvent(mDef.events.updateGrowth)
    end
    -- We handle skill level up
    return false
end

local function skillUsedHandlerReduction(_, skillId, params)
    local range = mSettings.skillsStorage:get("skillGainFactorRange")
    if range[1] == 100 and range[2] == 100 then return end

    local level = Player.stats.skills[skillId](self).base
    local gain = params.skillGain
    params.skillGain = gain * mDef.formulas.getLogRangeFactor(level, range[1], range[2])
    log(string.format("Skill \"%s\" level %d, gain changed from %.5f to %.5f, from setting range [%s, %s]",
            skillId, level, gain, params.skillGain, range[1], range[2]))
end

local function skillUsedHandlerMbsp(_, skillId, params)
    if not magickaSkills[skillId] or not mSettings.mbspStorage:get("mbspEnabled") then return end

    local magickaXPRate = mSettings.mbspStorage:get("magickaXPRate")
    local spell = Player.getSelectedSpell(self)
    if not spell then
        log(string.format("No spell selected for skill \"%s\", can't do MBSP", skillId))
        return
    end
    log(string.format("MBSP: Magicka skill \"%s\" increase, base gain = %.5f, cost = %d, XP rate = %d, final gain = %.5f",
            skillId, params.skillGain, spell.cost, magickaXPRate, params.skillGain * spell.cost / magickaXPRate))
    params.skillGain = params.skillGain * spell.cost / magickaXPRate
    if mSettings.mbspStorage:get("refundEnabled") then
        local refund = spell.cost * (mSettings.mbspStorage:get("refundMult") / 5)
                * (1 - 0.5 ^ (math.max(Player.stats.skills[skillId](self).base - mSettings.mbspStorage:get("refundStart"), 0) / 100))
        if refund > 0 then
            log(string.format("MBSP: Magic skill \"%s\" refund: %.2f", skillId, refund))
            mCommon.modMagicka(refund)
        end
    end
end

local function skillUsedHandlerMultiSchool(_, skillId, params)
    if not magickaSkills[skillId] then return end

    local spell = Player.getSelectedSpell(self)
    spellSchoolRatios[spell.id] = spellSchoolRatios[spell.id] or mSpells.getSchoolRatios(spell, self)
    local skillGain = params.skillGain
    for school, ratio in pairs(spellSchoolRatios[spell.id]) do
        if ratio < 1 then
            log(string.format("Magicka skill \"%s\" increase, base gain = %.5f, multi-school ratio = %.2f, final gain = %.5f",
                    school, skillGain, ratio, skillGain * ratio))

            local gain = ratio * skillGain
            if skillId == school then
                params.skillGain = gain
            else
                -- preserve reductions of previous handlers, preserve potential addons changes on base skill gains
                gain = gain * core.stats.Skill.records[skillId].skillGain[1] / core.stats.Skill.records[school].skillGain[1]
                self:sendEvent(mDef.events.applySkillUsedHandlers, { skillId = school, params = { skillGain = gain }, afterHandler = "multiSchool" })
            end
        end
    end
end

local function skillUsedHandlerUses(_, skillId, params)
    local gain = mSettings.getSkillUseGain(skillId, params.useType)
    log(string.format("Base gain for skill \"%s\" is %.2f (instead of %.2f)", skillId, gain, params.skillGain))
    params.skillGain = gain

    if weaponSkills[skillId] then
        local speed = 1.5 -- estimated speed for hand to hand
        local weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
        if weapon then
            weaponSpeeds[weapon.id] = weaponSpeeds[weapon.id] or weapon.type.record(weapon).speed
            speed = weaponSpeeds[weapon.id]
        end
        -- Faster weapons reduce the gain, but less than proportionally to the speed
        -- Examples with gain 0.75:
        -- - speed 1.0 -> gain 0.75
        -- - speed 1.5 -> gain 0.61
        -- - speed 2.0 -> gain 0.53
        -- - speed 2.5 -> gain 0.47
        params.skillGain = params.skillGain / (speed ^ 0.5)
        log(string.format("Modified gain for skill \"%s\" is %.5f, based on weapon speed %.2f", skillId, params.skillGain, speed))
    end
end

local function skillUsedHandlerCapper(_, skillId, _)
    if Player.stats.skills[skillId](self).base >= mSettings.getSkillMaxValue(skillId) then
        Player.stats.skills[skillId](self).progress = 0
        -- Stop skill used handlers
        return false
    end
end

local function getSkillUsedHandlers(state)
    return {
        { name = "final", handler = function(skillId, params) return skillUsedHandlerFinal(state, skillId, params) end },
        { name = "reduction", handler = function(skillId, params) return skillUsedHandlerReduction(state, skillId, params) end },
        { name = "decay", handler = function(skillId, params) return mDecay.skillUsedHandler(state, skillId, params) end },
        { name = "mbsp", handler = function(skillId, params) return skillUsedHandlerMbsp(state, skillId, params) end },
        { name = "multiSchool", handler = function(skillId, params) return skillUsedHandlerMultiSchool(state, skillId, params) end },
        { name = "uses", handler = function(skillId, params) return skillUsedHandlerUses(state, skillId, params) end },
        { name = "capper", handler = function(skillId, params) return skillUsedHandlerCapper(state, skillId, params) end },
    }
end

local function addSkillUsedHandlers(state)
    for _, handler in ipairs(getSkillUsedHandlers(state)) do
        I.SkillProgression.addSkillUsedHandler(handler.handler)
    end

    I.SkillProgression.addSkillLevelUpHandler(function(skillId, source)
        if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Book and not mSettings.skillsStorage:get("skillIncreaseFromBooks") then
            log(string.format("Preventing skill \"%s\" level up from book", skillId))
            -- Stop skill level up handlers
            return false
        end
        local details
        if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Trainer then
            mDecay.setLastTrainedSkillId(skillId)
            if mSettings.skillsStorage:get("progressiveTrainingDuration") then
                local extraTimePassed = 14 * (state.skills.base[skillId] / 100) ^ 2
                log(string.format("Training skill \"%s\" took 2 + %.2f hours", skillId, extraTimePassed))
                core.sendGlobalEvent(mDef.events.skipGameHours, { player = self, hours = extraTimePassed })
                details = L("trainingDuration", { hours = 2 + math.floor(extraTimePassed), minutes = math.floor(extraTimePassed % 1 * 60) })
            end
        end
        self:sendEvent(mDef.events.updateGrowthAllAttrs)
        mCommon.modStat(state, "skills", skillId, 1, { details = details })
        return false
    end)
end
module.addSkillUsedHandlers = addSkillUsedHandlers

local function applySkillUsedHandlers(state, skillId, params, afterHandler)
    local apply = not afterHandler
    local handlers = getSkillUsedHandlers(state)
    for i = #handlers, 1, -1 do
        local handler = handlers[i]
        if apply then
            if false == handler.handler(state, skillId, params) then
                return
            end
        end
        if afterHandler and handler.name == afterHandler then
            apply = true
        end
    end
end
module.applySkillUsedHandlers = applySkillUsedHandlers

return module