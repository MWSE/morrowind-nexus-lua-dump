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

local spellSchoolRatios = {}
local weaponSpeeds = {}

local module = {}

local function setSkillGrowths(state, skillId, skillValue)
    state.skills.growth[skillId] = skillValue - state.skills.start[skillId]
    local skillsMaxValue = mSettings.skillsStorage:get("uncapperMaxValue")
    local perSkillMaxValues = mSettings.getPerSkillMaxValues()
    local maxValue = (perSkillMaxValues[skillId] or skillsMaxValue)
    local settingKey = state.skills.major[skillId] and "Major" or (state.skills.minor[skillId] and "Minor" or "Misc")
    local exponentLevel = mSettings.levelStorage:get("exponentLevelSkillLevel") or 0
    local room = state.skills.major[skillId] and state.skills.room.major or (state.skills.minor[skillId] and state.skills.room.minor or state.skills.room.misc)
    state.skills.growth.level[skillId] = state.skills.growth[skillId]
        * (skillValue / maxValue) ^ exponentLevel
        * mSettings.levelStorage:get("levelFactorFrom" .. settingKey .. "Skills") / 100
        * 1 / room

    local growthFactorFromSpecialization = state.skills.specialization[skillId] and mSettings.attributesStorage:get("growthFactorFromSpecialization") or 1
    local exponentAttribute = mSettings.attributesStorage:get("exponentAttributeSkillLevel") or 0
    state.skills.growth.attributes[skillId] = skillValue
        * (skillValue / maxValue) ^ exponentAttribute
        * mSettings.attributesStorage:get("growthFactorFrom" .. settingKey .. "Skills")
        * growthFactorFromSpecialization
end
module.setSkillGrowths = setSkillGrowths

local function updateSkills(state, baseStatsMods, allAttrs)
    local attributesToUpdate = {}
    local decayEnabled = mSettings.skillsStorage:get("skillDecayRate") ~= "skillDecayNone"
    local skillsMaxValue = mSettings.skillsStorage:get("uncapperMaxValue")
    local maxBook = mSettings.skillsStorage:get("skillBooksMax") or 5
    local bookGain = mSettings.skillsStorage:get("skillBooksExpValue") or 4
    local perSkillMaxValues = mSettings.getPerSkillMaxValues()

    for skillId, getter in pairs(Player.stats.skills) do
        local maxValue = (perSkillMaxValues[skillId] or skillsMaxValue) + (baseStatsMods.skills[skillId] or 0)

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

        local bookExp = math.min(math.max(0, maxBook - state.skills.books.skillUp[skillId]), state.skills.books.exp[skillId])
        state.skills.books.totalGain[skillId] = bookGain * bookExp

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

            setSkillGrowths(state, skillId, state.skills.base[skillId])

            for attrId, _ in pairs(mCfg.skillsImpactOnAttributes[skillId]) do
                --log(string.format("\"%s\" should be recalculated!", attrId))
                attributesToUpdate[attrId] = true
            end
        end
    end
    return attributesToUpdate
end
module.updateSkills = updateSkills

local function capTrainedSkills(state, uiData)
    if not mSettings.skillsStorage:get("capSkillTrainingLevel") then return end

    local messages = {}

    if uiData.newMode == "Training" then
        table.insert(messages, L("skillTrainingCap", { trainingSessions = tostring(state.skills.training.sessions) }))
        for _, message in ipairs(messages) do
            mCommon.showMessage(state, message)
        end
    end
end
module.capTrainedSkills = capTrainedSkills

local function skillBooks(state, uiData)
    if uiData.newMode == "Book" then
        local book = uiData.arg
        local bookRecord = book.type.records[book.recordId]
        if bookRecord.skill then
            local messages = {}
            local bookSkillRecord = core.stats.Skill.records[bookRecord.skill]
            local skillId = bookSkillRecord.id
            local skillName = bookSkillRecord.name
            local maxBook = mSettings.skillsStorage:get("skillBooksMax") or 5
            local bookGain = mSettings.skillsStorage:get("skillBooksExpValue") or 4
            if state.skills.books.read[bookRecord.id] then
                table.insert(messages, L("skillBooksRead", { skill = skillName }))
            elseif (state.skills.books.exp[skillId] + state.skills.books.skillUp[skillId]) >= maxBook then
                if mSettings.skillsStorage:get("skillBooksExp") then
                    table.insert(messages, L("skillBooksExpMax", { totalPercentage = state.skills.books.totalGain[skillId] .. "%", maxBook = maxBook, skill = skillName }))
                else
                    table.insert(messages, L("skillBooksMax", { maxBook = maxBook, skill = skillName }))
                end
            elseif mSettings.skillsStorage:get("skillBooksInventory") and uiData.oldMode ~= "Interface" then
                table.insert(messages, L("skillBooksInventory", { skill = skillName }))
            elseif mSettings.skillsStorage:get("skillBooksExp") then
                state.skills.books.exp[skillId] = state.skills.books.exp[skillId] + 1
                state.skills.books.read[bookRecord.id] = true
                ambient.playSound("skillraise")
                local bookExp = math.min(math.max(0, maxBook - state.skills.books.skillUp[skillId]), state.skills.books.exp[skillId])
                state.skills.books.totalGain[skillId] = bookGain * bookExp
                table.insert(messages, L("skillBookExperience", { percentage = bookGain .. "%", skill = skillName, totalPercentage = state.skills.books.totalGain[skillId] .. "%" }))
            end
            if #messages > 0 then
                for _, message in ipairs(messages) do
                    mCommon.showMessage(state, message)
                end
                log(string.format("Preventing skill \"%s\" level up from book", skillId))
                return
            end
            state.skills.books.skillUp[skillId] = state.skills.books.skillUp[skillId] + 1
            state.skills.books.read[bookRecord.id] = true
            self:sendEvent(mDef.events.updateGrowthAllAttrs)
            mCommon.modStat(state, "skills", skillId, 1)
            ambient.playSound("skillraise")
        end
    end
end
module.skillBooks = skillBooks

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
                state.skills.base[skillId] >= mSettings.getSkillMaxValue(skillId) then
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

local function skillUsedHandlerBooks(state, skillId, params)
    if state.skills.books.totalGain[skillId] == 0 then return end

    params.skillGain = params.skillGain * (1 + (state.skills.books.totalGain[skillId] / 100 ))
    log(string.format("Gain for skill \"%s\" is modified by %d%% to %.5f, based on skill books read", skillId, state.skills.books.totalGain[skillId], params.skillGain))
end

local function skillUsedHandlerReduction(state, skillId, params)
    local range = mSettings.skillsStorage:get("skillGainFactorRange")
    if range[1] == 100 and range[2] == 100 then return end

    local level = state.skills.base[skillId]
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

local function skillUsedHandlerCapper(state, skillId, _)
    if state.skills.base[skillId] >= mSettings.getSkillMaxValue(skillId) then
        Player.stats.skills[skillId](self).progress = 0
        -- Stop skill used handlers
        return false
    end
end

local function getSkillUsedHandlers(state)
    return {
        { name = "final", handler = function(skillId, params) return skillUsedHandlerFinal(state, skillId, params) end },
        { name = "books", handler = function(skillId, params) return skillUsedHandlerBooks(state, skillId, params) end },
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
        if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Book then
            return false
        end
        local details
        if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Trainer then
            if mSettings.skillsStorage:get("capSkillTrainingLevel") and state.skills.training.sessions == 0 then
                log(string.format("Preventing skill \"%s\" level up from training", skillId))
                return false
            else
                mDecay.setLastTrainedSkillId(skillId)
                if mSettings.skillsStorage:get("progressiveTrainingDuration") then
                    local extraTimePassed = 14 * (state.skills.base[skillId] / 100) ^ 2
                    log(string.format("Training skill \"%s\" took 2 + %.2f hours", skillId, extraTimePassed))
                    core.sendGlobalEvent(mDef.events.skipGameHours, { player = self, hours = extraTimePassed })
                    details = L("trainingDuration", { hours = 2 + math.floor(extraTimePassed), minutes = math.floor(extraTimePassed % 1 * 60) })
                end
                state.skills.training.used = state.skills.training.used + 1
            end
        end
        self:sendEvent(mDef.events.updateGrowthAllAttrs)
        mCommon.modStat(state, "skills", skillId, 1, { details = details })
        ambient.playSound("skillraise")
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
            if false == handler.handler(skillId, params) then
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