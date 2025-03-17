local core = require('openmw.core')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local Player = require('openmw.types').Player

local S = require('scripts.NCGDMW.settings')

local log = require('scripts.NCGDMW.log')
local def = require('scripts.NCGDMW.definition')
local C = require('scripts.NCGDMW.common')
local decay = require('scripts.NCGDMW.decay')
local spellHelper = require('scripts.NCGDMW.spells')

local lastUiMode
local spellSchoolRatios = {}
local weaponSpeeds = {}

local function addSkillGain(skillId, skillGain)
    local skillRequirement = I.SkillProgression.getSkillProgressRequirement(skillId)
    local progress = Player.stats.skills[skillId](self).progress + skillGain / skillRequirement
    local excessSkillGain = (progress - 1) * skillRequirement
    log(string.format("Add skill \"%s\" gain %.5f (requirement %.5f, excess %.5f), progress %.5f to %.5f",
            skillId, skillGain, skillRequirement, excessSkillGain > 0 and excessSkillGain or 0, Player.stats.skills[skillId](self).progress, progress))
    if excessSkillGain >= 0 then
        C.increaseSkill(skillId)
        if not S.skillsStorage:get("carryOverExcessSkillGain") or
                Player.stats.skills[skillId](self).base >= S.getSkillMaxValue(skillId) then
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

local function skillUsedHandlerFinal(skillId, params)
    local skillLevel = Player.stats.skills[skillId](self).base
    addSkillGain(skillId, params.skillGain)
    if skillLevel ~= Player.stats.skills[skillId](self).base then
        self:sendEvent(def.events.updatePlayerStats)
    end
    -- We handle skill level up
    return false
end

local function skillUsedHandlerReduction(skillId, params)
    log(string.format("Skill \"%s\" used, base gain = %.5f", skillId, params.skillGain))
    local skillIncreaseConstantFactor = S.skillsStorage:get("skillIncreaseConstantFactor")
    if skillIncreaseConstantFactor ~= "vanilla" then
        params.skillGain = params.skillGain / S.getSkillIncreaseConstantFactor(skillIncreaseConstantFactor)
        log(string.format("Skill gain of \"%s\" reduced by constant, new gain = %.5f", skillId, params.skillGain))
    end
    local skillIncreaseSquaredLevelFactor = S.skillsStorage:get("skillIncreaseSquaredLevelFactor")
    if skillIncreaseSquaredLevelFactor ~= "disabled" then
        params.skillGain = params.skillGain / (
                (S.getSkillIncreaseSquaredLevelFactor(skillIncreaseSquaredLevelFactor) - 1)
                        * (Player.stats.skills[skillId](self).base / 100) ^ 2
                        + 1)
        log(string.format("Skill gain of \"%s\" reduced by square, new gain = %.5f", skillId, params.skillGain))
    end
end

local function skillUsedHandlerMbsp(skillId, params)
    if not C.magickaSkills[skillId] or not S.mbspStorage:get("mbspEnabled") then return end

    local magickaXPRate = S.mbspStorage:get("magickaXPRate")
    local spell = Player.getSelectedSpell(self)
    if not spell then
        log(string.format("No spell selected for skill \"%s\", can't do MBSP", skillId))
        return
    end
    log(string.format("MBSP: Magicka skill \"%s\" increase, base gain = %.5f, cost = %d, XP rate = %d, final gain = %.5f",
            skillId, params.skillGain, spell.cost, magickaXPRate, params.skillGain * spell.cost / magickaXPRate))
    params.skillGain = params.skillGain * spell.cost / magickaXPRate
    if S.mbspStorage:get("refundEnabled") then
        local refund = spell.cost * (S.mbspStorage:get("refundMult") / 5)
                * (1 - 0.5 ^ (math.max(Player.stats.skills[skillId](self).base - S.mbspStorage:get("refundStart"), 0) / 100))
        if refund > 0 then
            log(string.format("MBSP: Magic skill \"%s\" refund: %.2f", skillId, refund))
            C.modMagicka(refund)
        end
    end
end

local function skillUsedHandlerMultiSchool(skillId, params)
    if not C.magickaSkills[skillId] then return end

    local spell = Player.getSelectedSpell(self)
    spellSchoolRatios[spell.id] = spellSchoolRatios[spell.id] or spellHelper.getSchoolRatios(spell, self)
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
                self:sendEvent(def.events.applySkillUsedHandlers, { skillId = school, params = { skillGain = gain }, afterHandler = "multiSchool" })
            end
        end
    end
end

local function skillUsedHandlerUses(skillId, params)
    local gain = S.getSkillUseGain(skillId, params.useType)
    log(string.format("Base gain for skill \"%s\" is %.2f (instead of %.2f)", skillId, gain, params.skillGain))
    params.skillGain = gain

    if C.weaponSkills[skillId] then
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

local function skillUsedHandlerCapper(skillId, _)
    if Player.stats.skills[skillId](self).base >= S.getSkillMaxValue(skillId) then
        Player.stats.skills[skillId](self).progress = 0
        -- Stop skill used handlers
        return false
    end
end

local skillUsedHandlers = {
    { name = "final", handler = skillUsedHandlerFinal },
    { name = "reduction", handler = skillUsedHandlerReduction },
    { name = "decay", handler = decay.skillUsedHandler },
    { name = "mbsp", handler = skillUsedHandlerMbsp },
    { name = "multiSchool", handler = skillUsedHandlerMultiSchool },
    { name = "uses", handler = skillUsedHandlerUses },
    { name = "capper", handler = skillUsedHandlerCapper },
}

local function addSkillUsedHandlers()
    for _, handler in ipairs(skillUsedHandlers) do
        I.SkillProgression.addSkillUsedHandler(handler.handler)
    end

    I.SkillProgression.addSkillLevelUpHandler(function(skillId, source)
        if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Book and not S.skillsStorage:get("skillIncreaseFromBooks") then
            log(string.format("Preventing skill \"%s\" level up from book", skillId))
            -- Stop skill level up handlers
            return false
        end
        if lastUiMode == "Training" then
            decay.setLastTrainedSkillId(skillId)
        end
        -- Send an event to give time to the skill to level up before updating player stats
        self:sendEvent(def.events.updatePlayerStatsOnFrame)
    end)
end

local function applySkillUsedHandlers(skillId, params, afterHandler)
    local apply = not afterHandler
    for i = #skillUsedHandlers, 1, -1 do
        local handler = skillUsedHandlers[i]
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

local function onUiModeChanged(data)
    lastUiMode = data.newMode
end

return {
    addSkillUsedHandlers = addSkillUsedHandlers,
    applySkillUsedHandlers = applySkillUsedHandlers,
    onUiModeChanged = onUiModeChanged,
}