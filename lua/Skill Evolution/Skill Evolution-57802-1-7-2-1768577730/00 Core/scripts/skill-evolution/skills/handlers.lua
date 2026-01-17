local core = require('openmw.core')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local T = require('openmw.types')

local log = require('scripts.skill-evolution.util.log')
local mDef = require('scripts.skill-evolution.config.definition')
local mCfg = require('scripts.skill-evolution.config.configuration')
local mS = require('scripts.skill-evolution.config.settings')
local mCore = require('scripts.skill-evolution.util.core')
local mDecay = require('scripts.skill-evolution.skills.decay')
local mSpells = require('scripts.skill-evolution.util.spells')
local mScaling = require('scripts.skill-evolution.skills.scaling')
local mTraining = require('scripts.skill-evolution.skills.training')

local Skills = core.stats.Skill.records
local L = core.l10n(mDef.MOD_NAME)

local externalSkillUsedHandlers = {}
local externalOnHitHandlers = {}
local spellSchoolRatios = {}
local weaponSpeeds = {}

local module = {}

local function getGainStats(skill, params)
    local skillRequirement = I.SkillProgression.getSkillProgressRequirement(params.skillId)
    local progress = skill.progress + params.skillGain / skillRequirement
    local excess = math.max(0, (progress - 1) * skillRequirement)
    log(string.format("Skill %s gain %.3f (requirement %.3f), progress %.5f -> %.5f, excess %.3f",
            params.skillId, params.skillGain, skillRequirement, skill.progress, progress, excess))
    return progress, excess
end

module.handleGain = function(state, params)
    local skill = T.NPC.stats.skills[params.skillId](self)

    if skill.base >= mS.getSkillMaxValue(params.skillId) then
        state.skills.excessGain[params.skillId] = 0
        skill.progress = 0
        params.skillGain = 0
        return
    end

    local progress, excessGain = getGainStats(skill, params)

    if excessGain == 0 then
        if skill.base < 100 and not params.manual then
            return
        end
        state.skills.excessGain[params.skillId] = 0
        state.skills.progress[params.skillId] = progress
        skill.progress = progress
        params.skillGain = 0
        return
    end

    -- Skill up, with or without excess

    local lostLevels = state.skills.max[params.skillId] - state.skills.base[params.skillId]
    if lostLevels > 0 then
        params.manual = true
        excessGain = mCfg.decayLostLevelsSkillGainFact(lostLevels - 1)
                * excessGain
                / mCfg.decayLostLevelsSkillGainFact(lostLevels)
        log(string.format("Excess gain of recovered skill %s is reduced to %.3f", params.skillId, excessGain))
    end
    state.skills.excessGain[params.skillId] = excessGain

    if not mS.skillsStorage:get("carryOverExcessSkillGain") then
        state.skills.excessGain[params.skillId] = 0
    end

    if skill.base >= 100 or params.manual then
        state.skills.progress[params.skillId] = 0
        skill.progress = 0
        params.skillGain = 0
        I.SkillProgression.skillLevelUp(params.skillId, I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
    end
end

local function skillUsedHandlerFinal(state, skillId, params)
    if params.skillGain == 0 then return end

    log(string.format("Final handler: Skill \"%s\", gain %.5f x scale %.5f -> %.5f",
            skillId, params.skillGain, params.scale, params.skillGain * params.scale))
    params.skillGain = params.skillGain * params.scale

    params.skillId = skillId
    module.handleGain(state, params)
end

local function skillUsedHandlerLevelBasedGainScaling(_, skillId, params)
    if params.skillGain == 0 then return end

    local range = mS.skillsStorage:get("skillLevelBasedScalingRange")
    if range[1] == 100 and range[2] == 100 then return end

    local level = T.NPC.stats.skills[skillId](self).base
    local factor = mDef.logRangeFunctions[mDef.logRangeTypes.skillLevelBasedScalingRange](level, range[1], range[2])
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

    if not mCore.hasJustSpellCasted() then
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
        mCore.modMagicka(refund)
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
        { name = "levelScaled", handler = function(skillId, params) return skillUsedHandlerLevelBasedGainScaling(state, skillId, params) end },
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

local function getSkillLevelUpHandler(state)
    return function(skillId, source)
        local skill = T.NPC.stats.skills[skillId](self)

        local trained = source == I.SkillProgression.SKILL_INCREASE_SOURCES.Trainer

        if trained then
            local capMsg = mTraining.getSkillCappedMsg(skillId)
            if capMsg then
                self:sendEvent(mDef.events.showMessage, L(capMsg, { skill = Skills[skillId].name }))
                mTraining.restoreTrainingState()
                return false
            end
        end

        if skill.base >= mS.getSkillMaxValue(skillId) then
            state.skills.progress[skillId] = 0
            skill.progress = 0
            return false
        end

        if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Book and not mS.skillsStorage:get("skillIncreaseFromBooks") then
            log(string.format("Preventing skill \"%s\" level up from book", skillId))
            -- Stop skill level up handlers
            return false
        end

        -- Wait the next frame to check if the skill level up actually happened (not blocked by other mods)
        self:sendEvent(mDef.events.onSkillLevelUp, { skillId = skillId, skillLevel = skill.base, source = source })

        if skill.base >= 100 then
            local governedAttr = core.stats.Skill.records[skillId].attribute
            local level = T.Actor.stats.level(self)
            local levelProg, skillUps = mCore.getSkillUpStats(skillId)
            level.skillIncreasesForAttribute[governedAttr] = level.skillIncreasesForAttribute[governedAttr] + skillUps
            level.progress = level.progress + levelProg
            if level.progress >= mCore.GMSTs.iLevelupTotal then
                self:sendEvent(mDef.events.showMessage, core.getGMST("sLevelUpMsg"))
            end
        end
        if state.skills.base[skillId] < state.skills.max[skillId] then
            mCore.modSkill(skillId, 1, { recovered = true })
            return false
        end
        if skill.base >= 100 then
            mCore.modSkill(skillId, 1)
        end
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
        self:sendEvent(mDef.events.showMessage, L("trainingDuration", {
            skill = mCore.getSkillName(skillId),
            level = skillLevel + 1,
            hours = math.floor(extraTimePassed),
            minutes = math.floor(extraTimePassed % 1 * 60)
        }))
    end
    mDecay.slowDownSkillDecayOnSkillLevelUp(state, skillId)

    self:sendEvent(mDef.events.updateStats, { skillId = skillId, excessGain = state.skills.excessGain[skillId], fromHandler = true })
end

module.addHandlers = function(state)
    for _, handler in ipairs(getSkillUsedHandlers(state)) do
        I.SkillProgression.addSkillUsedHandler(handler.handler)
    end

    I.SkillProgression.addSkillLevelUpHandler(getSkillLevelUpHandler(state))

    I.Combat.addOnHitHandler(function(attack)
        self:sendEvent(mDef.events.onPlayerHit, attack)
    end)
    for _, handler in ipairs(externalOnHitHandlers) do
        I.Combat.addOnHitHandler(handler)
    end
end

module.applySkillUsedHandlers = function(state, skillId, params, afterHandler)
    params.manual = true
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

module.uiModeChanged = function(state, data)
    if data.newMode == "Training" then
        mTraining.setTrainingCap(state, data.arg)
    elseif data.oldMode == "Training" then
        mTraining.clearTrainingCap()
    end
end

return module