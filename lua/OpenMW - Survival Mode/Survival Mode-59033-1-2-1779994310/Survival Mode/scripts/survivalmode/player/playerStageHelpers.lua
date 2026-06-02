local M = {}
local self = require('openmw.self')
local types = require('openmw.types')

local PILLOW_RECORD_ID = 'misc_uni_pillow_unique'
local WELL_RESTED_PILLOW_BONUS_MULTIPLIER = 2.0
local WELL_RESTED_DEFAULT_BONUS_MULTIPLIER = 1.0

function M.create(deps)
    local state = assert(deps.state)
    local hungerStages = assert(deps.hungerStages)
    local thirstStages = assert(deps.thirstStages)
    local sleepStages = assert(deps.sleepStages)
    local normalizeKey = assert(deps.normalizeKey)
    local wellFedStageId = assert(deps.wellFedStageId)
    local wellHydratedStageId = assert(deps.wellHydratedStageId)
    local wellRestedStageId = assert(deps.wellRestedStageId)
    local wellFedWeaponSkillGainBonusPct = assert(deps.wellFedWeaponSkillGainBonusPct)
    local wellHydratedMagicSkillGainBonusPct = assert(deps.wellHydratedMagicSkillGainBonusPct)
    local wellRestedArmorSkillGainBonusPct = assert(deps.wellRestedArmorSkillGainBonusPct)
    local wellRestedStaminiaRegenBonusPct = assert(deps.wellRestedStaminiaRegenBonusPct)
    local isHungerSystemEnabled = assert(deps.isHungerSystemEnabled)
    local isThirstSystemEnabled = assert(deps.isThirstSystemEnabled)
    local isSleepSystemEnabled = assert(deps.isSleepSystemEnabled)
    local weaponSkillIds = deps.weaponSkillIds
    local magicSkillIds = deps.magicSkillIds
    local armorSkillIds = deps.armorSkillIds

    local api = {}
    local weaponSkillIdSet = {}
    local magicSkillIdSet = {}
    local armorSkillIdSet = {}

    if type(weaponSkillIds) == 'table' then
        for _, skillId in ipairs(weaponSkillIds) do
            weaponSkillIdSet[normalizeKey(skillId)] = true
        end
    end
    if type(magicSkillIds) == 'table' then
        for _, skillId in ipairs(magicSkillIds) do
            magicSkillIdSet[normalizeKey(skillId)] = true
        end
    end
    if type(armorSkillIds) == 'table' then
        for _, skillId in ipairs(armorSkillIds) do
            armorSkillIdSet[normalizeKey(skillId)] = true
        end
    end

    local function getCurrentWellRestedBonusMultiplier()
        local multiplier = tonumber(state.sleepWellRestedBonusMultiplier) or WELL_RESTED_DEFAULT_BONUS_MULTIPLIER
        if multiplier < WELL_RESTED_DEFAULT_BONUS_MULTIPLIER then
            return WELL_RESTED_DEFAULT_BONUS_MULTIPLIER
        end
        return multiplier
    end

    function api.getStageByValue(stages, value)
        local stageCount = type(stages) == 'table' and #stages or 0
        if stageCount == 0 then
            return nil
        end

        local numericValue = tonumber(value) or 0
        local firstStage = stages[1]
        local firstMin = tonumber(firstStage.min) or 0
        if numericValue < firstMin then
            return firstStage
        end

        for index, stage in ipairs(stages) do
            local stageMin = tonumber(stage.min) or 0
            local nextStage = stages[index + 1]
            local nextMin = nextStage ~= nil and tonumber(nextStage.min) or nil
            if numericValue >= stageMin and (nextMin == nil or numericValue < nextMin) then
                return stage
            end
        end

        return stages[stageCount]
    end

    function api.getInitialNeedValue(stages, fallback)
        if type(stages) == 'table' and type(stages[2]) == 'table' and type(stages[2].min) == 'number' then
            return stages[2].min
        end
        return fallback
    end

    function api.getHungerStage(hungerValue)
        return api.getStageByValue(hungerStages, hungerValue)
    end

    function api.getThirstStage(thirstValue)
        return api.getStageByValue(thirstStages, thirstValue)
    end

    function api.getSleepStage(sleepValue)
        return api.getStageByValue(sleepStages, sleepValue)
    end

    function api.getActiveWellFedStage()
        if not isHungerSystemEnabled() then
            return nil
        end
        local hungerStage = api.getHungerStage(state.hunger)
        if type(hungerStage) ~= 'table' or normalizeKey(hungerStage.id) ~= wellFedStageId then
            return nil
        end
        return hungerStage
    end

    function api.getWellFedWeaponSkillGainMultiplier()
        local hungerStage = api.getActiveWellFedStage()
        if hungerStage == nil then
            return 1.0
        end

        local bonusPct = tonumber(hungerStage.weaponSkillGainBonusPct)
        if bonusPct == nil then
            bonusPct = wellFedWeaponSkillGainBonusPct
        end
        if bonusPct <= 0 then
            return 1.0
        end

        return 1.0 + bonusPct
    end

    function api.getActiveWellHydratedStage()
        if not isThirstSystemEnabled() then
            return nil
        end
        local thirstStage = api.getStageByValue(thirstStages, state.thirst)
        if type(thirstStage) ~= 'table' or normalizeKey(thirstStage.id) ~= wellHydratedStageId then
            return nil
        end
        return thirstStage
    end

    function api.getWellHydratedMagicSkillGainMultiplier()
        local thirstStage = api.getActiveWellHydratedStage()
        if thirstStage == nil then
            return 1.0
        end

        local bonusPct = tonumber(thirstStage.magicSkillGainBonusPct)
        if bonusPct == nil then
            bonusPct = wellHydratedMagicSkillGainBonusPct
        end
        if bonusPct <= 0 then
            return 1.0
        end

        return 1.0 + bonusPct
    end

    function api.getActiveWellRestedStage()
        if not isSleepSystemEnabled() then
            return nil
        end
        local sleepStage = api.getStageByValue(sleepStages, state.sleep)
        if type(sleepStage) ~= 'table'
            or normalizeKey(sleepStage.id) ~= wellRestedStageId
            or state.sleepWellRestedBonusEligible ~= true then
            return nil
        end
        return sleepStage
    end

    function api.getSleepWellRestedBonusMultiplierOnSleep()
        local playerObject = self.object or self
        if types.Actor == nil
            or type(types.Actor.objectIsInstance) ~= 'function'
            or type(types.Actor.inventory) ~= 'function'
            or not types.Actor.objectIsInstance(playerObject) then
            return WELL_RESTED_DEFAULT_BONUS_MULTIPLIER
        end

        local inventory = types.Actor.inventory(playerObject)
        if inventory == nil or type(inventory.countOf) ~= 'function' then
            return WELL_RESTED_DEFAULT_BONUS_MULTIPLIER
        end

        local pillowCount = tonumber(inventory:countOf(PILLOW_RECORD_ID)) or 0
        if pillowCount > 0 then
            return WELL_RESTED_PILLOW_BONUS_MULTIPLIER
        end

        return WELL_RESTED_DEFAULT_BONUS_MULTIPLIER
    end

    function api.getWellRestedArmorSkillGainMultiplier()
        local sleepStage = api.getActiveWellRestedStage()
        if sleepStage == nil then
            return 1.0
        end

        local bonusPct = tonumber(sleepStage.armorSkillGainBonusPct)
        if bonusPct == nil then
            bonusPct = wellRestedArmorSkillGainBonusPct
        end
        if bonusPct <= 0 then
            return 1.0
        end

        return 1.0 + (bonusPct * getCurrentWellRestedBonusMultiplier())
    end

    function api.getWellRestedStaminiaRegenBonusPct()
        local sleepStage = api.getActiveWellRestedStage()
        if sleepStage == nil then
            return 0
        end

        local bonusPct = tonumber(sleepStage.staminiaRegenBonusPct)
        if bonusPct == nil then
            bonusPct = wellRestedStaminiaRegenBonusPct
        end
        if bonusPct <= 0 then
            return 0
        end

        return bonusPct * getCurrentWellRestedBonusMultiplier()
    end

    local function applyNeedsSkillGainBonus(skillId, params)
        if type(params) ~= 'table' then
            return
        end

        local normalizedSkillId = normalizeKey(skillId)
        local isWeaponSkill = weaponSkillIdSet[normalizedSkillId] == true
        local isMagicSkill = magicSkillIdSet[normalizedSkillId] == true
        local isArmorSkill = armorSkillIdSet[normalizedSkillId] == true
        if not isWeaponSkill and not isMagicSkill and not isArmorSkill then
            return
        end

        local skillGain = tonumber(params.skillGain)
        if skillGain == nil or skillGain <= 0 then
            return
        end

        local gainMultiplier = 1.0
        if isWeaponSkill then
            gainMultiplier = gainMultiplier * api.getWellFedWeaponSkillGainMultiplier()
        end
        if isMagicSkill then
            gainMultiplier = gainMultiplier * api.getWellHydratedMagicSkillGainMultiplier()
        end
        if isArmorSkill then
            gainMultiplier = gainMultiplier * api.getWellRestedArmorSkillGainMultiplier()
        end
        if gainMultiplier <= 1.0 then
            return
        end

        local scale = tonumber(params.scale)
        if scale ~= nil then
            if scale <= 0 then
                return
            end
            params.scale = scale * gainMultiplier
            return
        end

        params.skillGain = skillGain * gainMultiplier
    end

    function api.registerExternalSkillGainHandler(addSkillUsedHandler)
        if type(addSkillUsedHandler) ~= 'function' then
            return false
        end

        addSkillUsedHandler(applyNeedsSkillGainBonus)
        return true
    end

    function api.registerSkillProgressionHandler(skillProgressionInterface)
        if skillProgressionInterface == nil
            or type(skillProgressionInterface.addSkillUsedHandler) ~= 'function' then
            return false
        end

        return api.registerExternalSkillGainHandler(skillProgressionInterface.addSkillUsedHandler)
    end

    return api
end

return M
