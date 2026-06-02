local core = require('openmw.core')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local T = require('openmw.types')

local mDef = require('scripts.skill-evolution.config.definition')
local mCfg = require('scripts.skill-evolution.config.configuration')
local mS = require('scripts.skill-evolution.config.store')
local mSettings = require('scripts.skill-evolution.config.settings')
local mCore = require('scripts.skill-evolution.util.core')
local mDecay = require('scripts.skill-evolution.skills.decay')
local mSpells = require('scripts.skill-evolution.util.spells')
local mScaling = require('scripts.skill-evolution.skills.scaling')
local mTraining = require('scripts.skill-evolution.skills.training')
local mHelpers = require('scripts.skill-evolution.util.helpers')
local log = require('scripts.skill-evolution.util.log')

local L = core.l10n(mDef.MOD_NAME)

local externalSkillUsedHandlers = {}
local externalOnHitHandlers = {}
local spellSchoolRatios = {}
local weaponSpeeds = {}

local module = {}

local function getGainStats(state, skill, params)
    local skillRequirement = mCore.getSkillProgressRequirement(state, params.skillId, skill)
    local progress = skill.progress + params.skillGain / skillRequirement
    local excess = math.max(0, (progress - 1) * skillRequirement)
    log(string.format("Skill %s gain %.3f (requirement %.3f), progress %.5f -> %.5f, excess %.3f",
            params.skillId, params.skillGain, skillRequirement, skill.progress, progress, excess))
    return progress, excess
end

module.handleGain = function(state, params)
    local skill = mCore.getSkillStat(params.skillId)

    if skill.base - (params.baseSkillMods[params.skillId] or 0) >= mSettings.getSkillCappedValue(params.skillId) then
        state.skills.excessGain[params.skillId] = 0
        skill.progress = 0
        params.skillGain = 0
        return
    end

    local progress, excessGain = getGainStats(state, skill, params)

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

    if not mS.settings.carryOverExcessSkillGain.get() then
        state.skills.excessGain[params.skillId] = 0
    end

    if skill.base >= 100 or params.manual then
        state.skills.progress[params.skillId] = 0
        skill.progress = 0
        params.skillGain = 0
        if mCore.getSkillRecord(params.skillId).isCustom then
            I.SkillFramework.skillLevelUp(params.skillId, I.SkillFramework.SKILL_INCREASE_SOURCES.Usage)
        else
            I.SkillProgression.skillLevelUp(params.skillId, I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
        end
    end
end

local function skillUsedHandlerFinal(state, skillId, params)
    if params.skillGain == 0 then return end

    log(string.format("Final handler: skill \"%s\", gain %.5f x scale %.5f -> %.5f",
            skillId, params.skillGain, params.scale, params.skillGain * params.scale))
    params.skillGain = params.skillGain * params.scale

    params.skillId = skillId
    module.handleGain(state, params)
end

local function skillUsedHandlerLevelBasedGainScaling(_, skillId, params)
    if params.skillGain == 0 then return end

    local range = mS.settings.skillLevelBasedScalingRange.get()
    if range.from == 100 and range.to == 100 then return end

    local level = mCore.getSkillStat(skillId).base
    local factor = mDef.logRangeFunctions[mDef.logRangeTypes.skillLevelBasedScalingRange](level, range.from, range.to)
    local scale = params.scale
    params.scale = scale * factor
    log(string.format("Level-based handler: skill \"%s\" level %d, range [%s, %s], scale %.5f x factor %.5f -> %.5f",
            skillId, level, range.from, range.to, scale, factor, params.scale))
end

local function refundMagicka(skillId, spell, ratio)
    local refund = mSpells.getSpellCost(spell) * ratio * (mS.settings.refundMult.get() / 5)
            * (1 - 0.5 ^ (math.max(mCore.getSkillStat(skillId).base - mS.settings.refundStart.get(), 0) / 100))
    if refund > 0 then
        log(string.format("Magicka handler: magic skill \"%s\" refund: %.2f", skillId, refund))
        return refund
    end
    return 0
end

local function mbsp(skillId, spell, params)
    local mbspRate = mS.settings.mbspRate.get()
    local scale = params.scale
    local cost = mSpells.getSpellCost(spell)
    params.scale = scale * cost / mbspRate
    log(string.format("Magic handler: mBSP, \"%s\" increase, cost = %d, XP rate = %d, scale %.5f x ratio %.5f -> %.5f",
            skillId, cost, mbspRate, scale, cost / mbspRate, params.scale))
end

local function skillUsedHandlerMagic(_, skillId, params)
    if params.skillGain == 0 or not mCore.magickaSkills[skillId] then return end

    if not mCore.hasJustSpellCasted() then
        log("Magic handler: no spell cast detected")
        return
    end

    local spell = T.Player.getSelectedSpell(self)
    if not spell then
        log(string.format("Magic handler: no spell selected for skill \"%s\" for multi-school handler", skillId))
        return
    end

    if mS.settings.mbspEnabled.get() then
        mbsp(skillId, spell, params)
    end

    spellSchoolRatios[spell.id] = spellSchoolRatios[spell.id] or mSpells.getSchoolRatios(spell)
    local hasRefund = mS.settings.refundEnabled.get()
    local refund = 0
    local Skills = mCore.getSkillRecords()
    for school, ratio in pairs(spellSchoolRatios[spell.id]) do
        if params.useType and ratio < 1 then
            local skillGain = params.skillGain * ratio
            log(string.format("Magic handler: magicka skill \"%s\" increase, gain %.5f x ratio %.2f -> %.5f",
                    school, params.skillGain, ratio, skillGain))
            if skillId == school then
                params.skillGain = skillGain
            else
                -- preserve reductions of previous handlers, preserve potential addons changes on base skill gains
                skillGain = skillGain * Skills[skillId].skillGain[1] / Skills[school].skillGain[1]
                self:sendEvent(mDef.events.applySkillUsedHandlers, {
                    skillId = school,
                    handlerParams = mCore.copyHandlerParams(params),
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
    for i = 1, #externalSkillUsedHandlers do
        return externalSkillUsedHandlers[i](skillId, params)
    end
end

local function skillUsedHandlerUses(_, skillId, params)
    local skillGainCfg = mS.settings[mSettings.getSkillUseGainsKey(skillId)].argument.config
    if params.useType and params.skillGain ~= 0 and skillGainCfg then
        local useTypeCfg = skillGainCfg.gains[params.useType]
        if useTypeCfg then
            local gainCustom = mS.settings[mSettings.getSkillUseGainsKey(skillId)].get()[params.useType]
            if not mHelpers.areFloatEqual(gainCustom, useTypeCfg.original) then
                log(string.format("Skill used handler: custom base gain for skill \"%s\" is %.2f (instead of current %.2f and original %.2f)",
                        skillId, gainCustom, params.skillGain, useTypeCfg.original))
                params.skillGain = gainCustom
            elseif mHelpers.areFloatEqual(params.skillGain, mCfg.skillZeroGainHack) then
                params.skillGain = 0
            end
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
    if mCore.getSkillStat(skillId).base - (params.baseSkillMods[skillId] or 0) >= mSettings.getSkillCappedValue(skillId) then
        mCore.getSkillStat(skillId).progress = 0
        params.skillGain = 0
    end
end

local function skillUsedHandlerScale(_, skillId, params)
    params.baseSkillMods = mCore.getBaseSkillMods()
    -- - Ensure there is a scale
    -- - Restore the original gain to allow its override in the "uses" handler
    -- - It won't work properly with mods that trigger the skill use while providing both the skillGain and the scale
    local scale = params.scale
    if scale and scale <= 0 then
        if skillId == "mercantile" then
            params.scale = 1
            scale = 1
            params.skillGain = mCore.getSkillRecord("mercantile").skillGain[I.SkillProgression.SKILL_USE_TYPES.Mercantile_Success + 1]
            log(string.format("Mercantile gain and scale are 0, reverting to base gain %.5f and scale 1", params.skillGain))
        else
            print(string.format("Scale handler: provided scale is %d for skill \"%s\" (gain is %s), this should never happen, stopping the handler chain",
                    scale, skillId, params.skillGain))
            return false
        end
    end
    params.scale = scale or 1
    log(string.format("Scale handler: skill \"%s\", scale %s -> %.5f, gain %.3f / %.3f -> %.3f",
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
        local skill = mCore.getSkillStat(skillId)

        local trained = source == I.SkillProgression.SKILL_INCREASE_SOURCES.Trainer

        if trained then
            local capMsg = mTraining.getSkillCappedMsg(skillId)
            if capMsg then
                self:sendEvent(mDef.events.showMessage, L(capMsg, { skill = mCore.getSkillRecord(skillId).name }))
                mTraining.restoreTrainingState()
                return false
            end
        end

        if skill.base >= mSettings.getSkillCappedValue(skillId) then
            state.skills.progress[skillId] = 0
            skill.progress = 0
            return false
        end

        if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Book and not mS.settings.skillIncreaseFromBooks.get() then
            log(string.format("Preventing skill \"%s\" level up from book", skillId))
            -- Stop skill level up handlers
            return false
        end

        -- Wait the next frame to check if the skill level up actually happened (not blocked by other mods)
        self:sendEvent(mDef.events.onSkillLevelUp, { skillId = skillId, skillLevel = skill.base, source = source })

        if skill.base >= 100 then
            local governedAttr = mCore.getSkillRecord(skillId).attribute
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
    if mCore.getSkillStat(skillId).base <= skillLevel then return end

    if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Trainer then
        mTraining.onSkillTrained(state, skillId, skillLevel)
    else
        mDecay.slowDownSkillDecayOnSkillLevelUp(state, skillId)
    end

    self:sendEvent(mDef.events.updateStats, { skillId = skillId, excessGain = state.skills.excessGain[skillId], fromHandler = true })
end

module.addHandlers = function(state)
    local handlers = getSkillUsedHandlers(state)
    for i = 1, #handlers do
        I.SkillProgression.addSkillUsedHandler(handlers[i].handler)
        if I.SkillFramework then
            I.SkillFramework.addSkillUsedHandler(handlers[i].handler)
        end
    end

    local levelUpHandler = getSkillLevelUpHandler(state)
    I.SkillProgression.addSkillLevelUpHandler(levelUpHandler)
    if I.SkillFramework then
        I.SkillFramework.addSkillLevelUpHandler(levelUpHandler)
    end

    I.Combat.addOnHitHandler(function(attack)
        self:sendEvent(mDef.events.onPlayerHit, attack)
    end)
    for i = 1, #externalOnHitHandlers do
        I.Combat.addOnHitHandler(externalOnHitHandlers[i])
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