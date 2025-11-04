local core = require('openmw.core')
local ambient = require('openmw.ambient')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local T = require('openmw.types')

local log = require('scripts.NCGDMW.log')
local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mS = require('scripts.NCGDMW.settings')
local mCore = require('scripts.NCGDMW.core')
local mC = require('scripts.NCGDMW.common')
local mDecay = require('scripts.NCGDMW.decay')
local mSpells = require('scripts.NCGDMW.spells')
local mScaling = require('scripts.NCGDMW.skill-scaling')
local mH = require('scripts.NCGDMW.helpers')

local Skills = core.stats.Skill.records
local L = core.l10n(mDef.MOD_NAME)

local skillOrder = {}
for i, skill in ipairs(Skills) do
    skillOrder[skill.id] = i
end

local externalSkillUsedHandlers = {}
local externalOnHitHandlers = {}
local spellSchoolRatios = {}
local originalTrainingSkills = {}
local weaponSpeeds = {}

local module = {}

module.setSkillGrowths = function(state, skillId, skillValue, startValuesRatio, luckGrowthRate)
    state.skills.growth.level[skillId] = state.skills.misc[skillId] and 0 or skillValue - state.skills.start[skillId]

    local attrGrowth = skillValue - startValuesRatio * state.skills.start[skillId]
    local settingKey = state.skills.major[skillId] and "Major" or (state.skills.minor[skillId] and "Minor" or "Misc")
    state.skills.growth.attributes[skillId] = attrGrowth
            * mS.attributesStorage:get("growthFactorFrom" .. settingKey .. "Skills") / 100
            * (1 - luckGrowthRate / 4)
end

module.updateSkills = function(state, baseStatsMods, updateMode)
    local decayEnabled = mS.skillsStorage:get("skillDecayRate") ~= "skillDecayNone"
    local skillsCappedValue = mS.skillsStorage:get("uncapperMaxValue")
    local perSkillCappedValues = mS.getPerSkillMaxValues()
    local startValuesRatio = mS.getAttributeStartValuesRatio(mS.attributesStorage:get("startValuesRatio"))
    local luckGrowthRate = mS.getLuckGrowthRate(mS.attributesStorage:get("luckGrowthRate"))

    for skillId, getter in pairs(T.NPC.stats.skills) do
        local cappedValue = perSkillCappedValues[skillId] or skillsCappedValue
        local currentBase = originalTrainingSkills[skillId] or getter(self).base

        -- Update base and max values in case of manual or uncapper settings changes
        if currentBase > cappedValue then
            mC.setStat(state, "skills", skillId, cappedValue)
        end
        state.skills.max[skillId] = math.min(state.skills.max[skillId], cappedValue)

        local storedBase = state.skills.base[skillId]
        local actualBase = currentBase - (baseStatsMods.skills[skillId] or 0)

        if storedBase and storedBase ~= actualBase then
            log(string.format("Skill \"%s\" has changed from %s to %s", skillId, storedBase, actualBase))
            if decayEnabled and updateMode == mDef.refreshModes.skillChange and actualBase > storedBase then
                mDecay.slowDownSkillDecayOnSkillLevelUp(state, skillId, actualBase - storedBase)
            end
            if not decayEnabled or actualBase > state.skills.max[skillId] then
                state.skills.max[skillId] = actualBase
            end
        end

        state.skills.base[skillId] = actualBase

        -- Update skill progress to actual value, because:
        -- - skill increases from the console, books or training alters the progression
        -- - skill progresses need to be set for mid-game installs
        state.skills.progress[skillId] = T.NPC.stats.skills[skillId](self).progress

        module.setSkillGrowths(state, skillId, state.skills.base[skillId], startValuesRatio, luckGrowthRate)
    end

    state.skills.minMajor = math.huge
    for skillId in pairs(state.skills.major) do
        state.skills.minMajor = math.min(state.skills.base[skillId], state.skills.minMajor)
    end
    state.skills.minMinor = math.huge
    for skillId in pairs(state.skills.minor) do
        state.skills.minMinor = math.min(state.skills.base[skillId], state.skills.minMinor)
    end
end

local function getTrainingSkillIds(npc)
    local skills = {}
    for skillId in mH.spairs(T.NPC.stats.skills,
            function(t, a, b)
                return t[a](npc).base == t[b](npc).base
                        and skillOrder[a] < skillOrder[b]
                        or t[a](npc).base > t[b](npc).base
            end) do
        table.insert(skills, skillId)
        if #skills == 3 then
            return skills
        end
    end
end

local function capTrainedSkills(state, uiData)
    if not mS.skillsStorage:get("capSkillTraining") then return end

    -- check old mode because BMSO refreshes the training window and we get old mode = new mode
    if uiData.newMode == "Training" and uiData.oldMode ~= "Training" then
        local npc = uiData.arg
        local skillIds = getTrainingSkillIds(npc)
        local messages = {}
        originalTrainingSkills = {}
        for _, skillId in ipairs(skillIds) do
            local skill = T.NPC.stats.skills[skillId]
            if skill(self).base < skill(npc).base then
                local msgKey
                if state.skills.minor[skillId] and state.skills.base[skillId] >= state.skills.minMajor then
                    msgKey = "skillTrainingCapMinor"
                end
                if state.skills.misc[skillId] and state.skills.base[skillId] >= state.skills.minMinor then
                    msgKey = "skillTrainingCapMisc"
                end
                if msgKey then
                    originalTrainingSkills[skillId] = skill(self).base
                    log(string.format("Training cap: Player's \"%s\" buffed %d -> %d", skillId, skill(self).base, skill(npc).base))
                    skill(self).base = skill(npc).base
                    table.insert(messages, L(msgKey, { skill = Skills[skillId].name }))
                end
            end
        end
        if #messages > 0 and (not state.lastTrainer or state.lastTrainer.id ~= npc.id) then
            state.lastTrainer = npc
            for _, message in ipairs(messages) do
                mC.showMessage(state, message)
            end
        end
    elseif uiData.oldMode == "Training" and uiData.newMode ~= "Training" then
        for skillId, value in pairs(originalTrainingSkills) do
            log(string.format("Training cap: Player's \"%s\" restored %d -> %d", skillId, T.NPC.stats.skills[skillId](self).base, value))
            T.NPC.stats.skills[skillId](self).base = value
        end
        originalTrainingSkills = {}
    end
end

---- Skill handlers ----

local function addSkillGain(state, skillId, skillGain)
    local skillRequirement = I.SkillProgression.getSkillProgressRequirement(skillId)
    local progress = T.NPC.stats.skills[skillId](self).progress + skillGain / skillRequirement
    local excessSkillGain = (progress - 1) * skillRequirement
    log(string.format("Add skill \"%s\" gain %.3f (requirement %.3f, excess %.3f), progress %.5f -> %.5f",
            skillId, skillGain, skillRequirement, excessSkillGain > 0 and excessSkillGain or 0, T.NPC.stats.skills[skillId](self).progress, progress))
    if excessSkillGain >= 0 then
        mC.modStat(state, "skills", skillId, 1)
        if not mS.skillsStorage:get("carryOverExcessSkillGain") or
                T.NPC.stats.skills[skillId](self).base >= mS.getSkillMaxValue(skillId) then
            progress = 0
        else
            T.NPC.stats.skills[skillId](self).progress = 0
            -- Recursive function to allow gaining multiple levels with one skill action (unlikely but possible)
            addSkillGain(state, skillId, excessSkillGain)
            return
        end
    end
    state.skills.progress[skillId] = progress
    T.NPC.stats.skills[skillId](self).progress = progress
end

local function skillUsedHandlerFinal(state, skillId, params)
    if params.skillGain == 0 then return end

    log(string.format("Final handler: Skill \"%s\", gain %.5f x scale %.5f -> %.5f",
            skillId, params.skillGain, params.scale, params.skillGain * params.scale))
    params.skillGain = params.skillGain * params.scale

    local skillLevel = T.NPC.stats.skills[skillId](self).base
    addSkillGain(state, skillId, params.skillGain)
    if skillLevel ~= T.NPC.stats.skills[skillId](self).base then
        ambient.playSound("skillraise")
        self:sendEvent(mDef.events.updateRequest, { type = mDef.requestTypes.refreshStats, param = mDef.refreshModes.skillChange })
    end
    -- Allow other mods to get the skill used trigger, but with no skill gain as we handle it manually
    params.skillGain = 0
end

local function skillUsedHandlerLevelGainScaling(_, skillId, params)
    if params.skillGain == 0 then return end

    local range = mS.skillsStorage:get("skillGainFactorRange")
    if range[1] == 100 and range[2] == 100 then return end

    local level = T.NPC.stats.skills[skillId](self).base
    local factor = mDef.logRangeFunctions[mDef.logRangeTypes.skillGainFactorRange](level, range[1], range[2])
    local scale = params.scale
    params.scale = scale * factor
    log(string.format("Gain factor handler: Skill \"%s\" level %d, range [%s, %s], scale %.5f x scale %.5f -> %.5f",
            skillId, level, range[1], range[2], scale, factor, params.scale))
end

local function refundMagicka(skillId, spell, ratio)
    local refund = spell.cost * ratio * (mS.magickaStorage:get("refundMult") / 5)
            * (1 - 0.5 ^ (math.max(T.NPC.stats.skills[skillId](self).base - mS.magickaStorage:get("refundStart"), 0) / 100))
    if refund > 0 then
        log(string.format("Magicka handler: Magic skill \"%s\" refund: %.2f", skillId, refund))
        return refund
    end
    return 0
end

local function mbsp(skillId, spell, params)
    local mbspRate = mS.magickaStorage:get("mbspRate")
    local scale = params.scale
    params.scale = scale * spell.cost / mbspRate
    log(string.format("Magic handler: MBSP, \"%s\" increase, cost = %d, XP rate = %d, scale %.5f x ratio %.5f -> %.5f",
            skillId, spell.cost, mbspRate, scale, spell.cost / mbspRate, params.scale))
end

local function skillUsedHandlerMagic(_, skillId, params)
    if params.skillGain == 0 or not mCore.magickaSkills[skillId] then return end

    if not mC.hasJustSpellCasted() then
        log("Magic handler: No spell cast detected")
        return
    end

    local spell = T.Player.getSelectedSpell(self)
    if not spell then
        log(string.format("Magic handler: No spell selected for skill \"%s\" for multi-school handler", skillId))
        return
    end

    if mS.magickaStorage:get("mbspEnabled") then
        mbsp(skillId, spell, params)
    end

    spellSchoolRatios[spell.id] = spellSchoolRatios[spell.id] or mSpells.getSchoolRatios(spell, self)
    local hasRefund = mS.magickaStorage:get("refundEnabled")
    local refund = 0
    for school, ratio in pairs(spellSchoolRatios[spell.id]) do
        if ratio < 1 then
            local skillGain = params.skillGain * ratio
            log(string.format("Magic handler: Magicka skill \"%s\" increase, gain %.5f x ratio %.2f -> %.5f",
                    school, params.skillGain, ratio, skillGain))
            if skillId == school then
                params.skillGain = skillGain
            else
                -- preserve reductions of previous handlers, preserve potential addons changes on base skill gains
                skillGain = skillGain * core.stats.Skill.records[skillId].skillGain[1] / core.stats.Skill.records[school].skillGain[1]
                self:sendEvent(mDef.events.applySkillUsedHandlers, {
                    skillId = school,
                    params = { skillGain = skillGain, scale = params.scale, useType = params.useType },
                    afterHandler = "magic",
                })
            end
        end
        if hasRefund then
            refund = refund + refundMagicka(skillId, spell, ratio)
        end
    end
    if refund > 0 then
        mC.modMagicka(refund)
    end
end

local function skillUsedHandlerExternal(_, skillId, params)
    for _, handler in ipairs(externalSkillUsedHandlers) do
        return handler(skillId, params)
    end
end

local function skillUsedHandlerUses(_, skillId, params)
    if params.skillGain ~= 0 then
        local gainCustom = mS.getSkillUseGain(skillId, params.useType)
        local gainVanilla = mCfg.skillUseTypes[skillId][params.useType].vanilla
        if gainCustom ~= gainVanilla then
            log(string.format("Skill used handler: Custom base gain for skill \"%s\" is %.2f (instead of input %.2f and vanilla %.2f)",
                    skillId, gainCustom, params.skillGain, gainVanilla))
            params.skillGain = gainCustom
        end
    end

    if not mCore.weaponSkills[skillId] then
        return
    end
    local speed = 1.5 -- estimated speed for hand to hand
    local weapon = T.Actor.getEquipment(self, T.Actor.EQUIPMENT_SLOT.CarriedRight)
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
    local factor = 1 / (speed ^ 0.5)
    local scale = params.scale
    params.scale = scale * factor
    log(string.format("Skill uses handler: \"%s\", weapon speed %.2f, scale %.5f x factor %.5f -> %.5f", skillId, speed, scale, factor, params.scale))
end

local function skillUsedHandlerCapper(_, skillId, params)
    if T.NPC.stats.skills[skillId](self).base >= mS.getSkillMaxValue(skillId) then
        T.NPC.stats.skills[skillId](self).progress = 0
        params.skillGain = 0
    end
end

local function skillUsedHandlerScale(_, skillId, params)
    -- - Ensure there is a scale
    -- - Restore the original gain to allow its override in the "uses" handler
    -- - It won't work properly with mods that trigger the skill use while providing both the skillGain and the scale
    local scale = params.scale
    params.scale = math.max(1, scale or 1)
    log(string.format("Scale handler: Skill \"%s\", scale %s -> %.5f, gain %.3f / %.3f -> %.3f",
            skillId, scale, params.scale, params.skillGain, params.scale, params.skillGain / params.scale))
    params.skillGain = params.skillGain / params.scale
end

local function getSkillUsedHandlers(state)
    return {
        { name = "final", handler = function(skillId, params) return skillUsedHandlerFinal(state, skillId, params) end },
        { name = "external", handler = function(skillId, params) return skillUsedHandlerExternal(state, skillId, params) end },
        { name = "levelScaled", handler = function(skillId, params) return skillUsedHandlerLevelGainScaling(state, skillId, params) end },
        { name = "decay", handler = function(skillId, params) return mDecay.skillUsedHandler(state, skillId, params) end },
        { name = "magic", handler = function(skillId, params) return skillUsedHandlerMagic(state, skillId, params) end },
        { name = "scaled", handler = function(skillId, params) return mScaling.skillUsedHandler(state, skillId, params) end },
        { name = "uses", handler = function(skillId, params) return skillUsedHandlerUses(state, skillId, params) end },
        { name = "capper", handler = function(skillId, params) return skillUsedHandlerCapper(state, skillId, params) end },
        { name = "scale", handler = function(skillId, params) return skillUsedHandlerScale(state, skillId, params) end },
    }
end

module.addSkillUsedHandler = function(newHandler)
    table.insert(externalSkillUsedHandlers, newHandler)
end

module.addOnHitHandler = function(newHandler)
    table.insert(externalOnHitHandlers, newHandler)
end

local function getSkillLevelUpHandler()
    return function(skillId, source)
        if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Book and not mS.skillsStorage:get("skillIncreaseFromBooks") then
            log(string.format("Preventing skill \"%s\" level up from book", skillId))
            -- Stop skill level up handlers
            return false
        end

        -- Wait the next frame to check if the skill level up actually happened (not blocked by other mods)
        self:sendEvent(mDef.events.onSkillLevelUp, { skillId = skillId, skillLevel = T.NPC.stats.skills[skillId](self).base, source = source })
    end
end

module.onSkillLevelUp = function(state, skillId, skillLevel, source)
    if T.NPC.stats.skills[skillId](self).base <= skillLevel then return end

    if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Trainer then
        mDecay.setLastTrainedSkillId(skillId)
        local range = mS.skillsStorage:get("scaledTrainingDuration")
        local extraTimePassed = mDef.logRangeFunctions[mDef.logRangeTypes.scaledTrainingDuration](state.skills.base[skillId], range[1], range[2])
        log(string.format("Training skill \"%s\" took %.2f hours", skillId, extraTimePassed))
        core.sendGlobalEvent(mDef.events.skipGameHours, { player = self, hours = extraTimePassed - 2 })
        mC.showMessage(state, L("trainingDuration", {
            skill = mCore.getStatName("skills", skillId),
            level = skillLevel + 1,
            hours = math.floor(extraTimePassed),
            minutes = math.floor(extraTimePassed % 1 * 60)
        }))
    end

    self:sendEvent(mDef.events.updateRequest, { type = mDef.requestTypes.refreshStats, param = mDef.refreshModes.skillChange })
end

module.addHandlers = function(state)
    for _, handler in ipairs(getSkillUsedHandlers(state)) do
        I.SkillProgression.addSkillUsedHandler(handler.handler)
    end

    I.SkillProgression.addSkillLevelUpHandler(getSkillLevelUpHandler())

    if mDef.isOpenMW50 then
        I.Combat.addOnHitHandler(function(attack)
            self:sendEvent(mDef.events.onPlayerHit, attack)
        end)
        for _, handler in ipairs(externalOnHitHandlers) do
            I.Combat.addOnHitHandler(handler)
        end
    end
end

module.applySkillUsedHandlers = function(state, skillId, params, afterHandler)
    local apply = not afterHandler
    local handlers = getSkillUsedHandlers(state)
    for i = #handlers, 1, -1 do
        local handler = handlers[i]
        if apply then
            if false == handler.handler(skillId, params) then
                return
            end
        end
        if afterHandler and handler.name == afterHandler then
            apply = true
        end
    end
end

module.onActorHit = function(state, actor)
    mScaling.onActorHit(state, actor)
end

module.onPlayerHit = function(state, attack)
    mScaling.onPlayerHit(state, attack)
end

module.onActorAnimHit = function(state, actor, animGroup, animKey)
    mScaling.onActorAnimHit(state, actor, animGroup, animKey)
end

module.onHealthModified = function(state, value)
    mScaling.onHealthModified(state, value)
end

module.uiModeChanged = function(state, data)
    capTrainedSkills(state, data)

    mScaling.uiModeChanged(data)
end

module.onUpdate = function(state, deltaTime)
    mScaling.onUpdate(state, deltaTime)
end

module.onFrame = function()
    mScaling.onFrame()
end

return module