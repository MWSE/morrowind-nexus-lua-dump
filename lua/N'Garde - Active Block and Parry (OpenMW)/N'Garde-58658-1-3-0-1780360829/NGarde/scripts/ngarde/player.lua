---@omw-context player
local modInfo              = require('scripts.ngarde.modinfo')
local core                 = require('openmw.core')
local I                    = require('openmw.interfaces')
local input                = require('openmw.input')
local self                 = require('openmw.self')
local types                = require('openmw.types')
local ambient              = require('openmw.ambient')
local ui                   = require('openmw.ui')
local async                = require('openmw.async')
local util                 = require('openmw.util')
local storage              = require('openmw.storage')
local SC                   = require('scripts.ngarde.helpers.settings_constants')
local logging              = require('scripts.ngarde.helpers.logger').new()
local targetRaycast        = require('scripts.ngarde.helpers.target_raycast').new()
local parryController      = require('scripts.ngarde.controllers.parry').new()
local Constants            = require('scripts.ngarde.helpers.constants')
local menuSettings         = storage.playerSection(SC.generalSettingsStorageKey)
local l10n                 = core.l10n(modInfo.l10n)
local getStance            = types.Actor.getStance
local isDead               = types.Actor.isDead
local clamp                = util.clamp
local frameStanceIsWeapon  = false
local frameControlsUse     = 0
local settings             = {
    controllerTrigger = SC.controllerTriggerDefault,
    triggerSensitivity = clamp(SC.triggerSensitivityDefault, 1, 99) / 100
}
local settingsGroups       = {
    [SC.generalSettingsStorageKey] = storage.playerSection(SC.generalSettingsStorageKey)
}
local previousTriggerValue = 0
local onHitHandler         = function(attack)
    attack = parryController:onHitHandler(attack)
end

local triggerToAxis        = {
    [SC.controllerTriggerValues[SC.controller_triggers.off]] = nil,
    [SC.controllerTriggerValues[SC.controller_triggers.lt]] = input.CONTROLLER_AXIS.TriggerLeft,
    [SC.controllerTriggerValues[SC.controller_triggers.rt]] = input.CONTROLLER_AXIS.TriggerRight,
}


local function readMenuSettings()
    settings.controllerTrigger = SC.readSetting(menuSettings, SC.controllerTriggerKey)
    settings.triggerSensitivity = clamp(SC.readSetting(menuSettings, SC.triggerSensitivityKey), 1, 99) / 100
end

local function readUpdatedSetting(groupName, changedKey)
    local settingGroup = settingsGroups[groupName]
    if changedKey ~= nil then
        if changedKey == SC.triggerSensitivityKey then
            settings[SC.keyToLocal(changedKey)] = clamp(SC.readSetting(settingGroup, changedKey), 1, 99) / 100
        else
            settings[SC.keyToLocal(changedKey)] = SC.readSetting(settingGroup, changedKey)
        end
    else
        readMenuSettings()
    end
end


menuSettings:subscribe(async:callback(function(groupName, changedKey) readUpdatedSetting(groupName, changedKey) end))

local function onEnemyPerfectParry()
    parryController:onEnemyPerfectParry()
end

local skillLevelUpHandler = function(skillID, source, options)
    -- skill is not yet incremented during handler, so all comparisons are made against n-1 values
    if skillID == "handtohand" and parryController.currentStats[skillID].base == parryController.ironPalmThreshold - 1 then
        ui.showMessage(l10n("iron_palm_threshold_level_up_message"))
    end
    if Helpers.arrayContains(Constants.meleeWeaponSkillIds, skillID) then
        if parryController.currentStats[skillID].base == parryController.perfectParryThreshold - 1 then
            ui.showMessage(l10n("perfect_parry_threshold_level_up_message", { skill = Constants.skillIdToName[skillID] }))
        end
    end
end

local function registerHandlers()
    ---@diagnostic disable-next-line undefined-field
    if I.SkillEvolution and I.SkillEvolution.addOnHitHandler then
        logging:debug("registering SE onHitHandler")
        ---@diagnostic disable-next-line undefined-field
        I.SkillEvolution.addOnHitHandler(onHitHandler)
    else
        logging:debug("registering regular onHitHandler")
        I.Combat.addOnHitHandler(onHitHandler)
    end
    I.SkillProgression.addSkillLevelUpHandler(skillLevelUpHandler)
end

registerHandlers()


local function processTriggerInputs()
    if settings.controllerTrigger and settings.controllerTrigger:lower() ~= "none" then
        local targetAxis = triggerToAxis[settings.controllerTrigger]
        if targetAxis then
            local inputValue = 0
            inputValue = input.getAxisValue(targetAxis)
            if inputValue > 0 then
                local wasPressed = previousTriggerValue >= settings.triggerSensitivity
                local isPressed = inputValue >= settings.triggerSensitivity
                previousTriggerValue = inputValue
                if isPressed then
                    return true
                end
                if not isPressed and wasPressed then
                    return false
                end
            end
            return false
        end
        return false
    else
        previousTriggerValue = 0
    end
    return false
end

local function castToTarget()
    local result = targetRaycast:castToCursor(self)
    -- logging:debug(result.hitObject)
    if result.hitTypeName == "NPC" or result.hitTypeName == "Creature" then
        local targetId = result.hitObject.id
        if not isDead(result.hitObject) and parryController.targets[targetId] == nil then
            parryController.primaryTarget = result.hitObject
            parryController.targets[targetId] = result.hitObject
        end
    end
end



local function onFrame(dt)
    if core.isWorldPaused() then return end
    local realDeltaT = core.getRealFrameDuration()
    --#region timers
    parryController.localTimers.perfectParryTimer:processTimer(realDeltaT)
    parryController.localTimers.staggerCooldownTimer:processTimer(realDeltaT)
    parryController.localTimers.skillGainParryTimer:processTimer(realDeltaT)


    if parryController.myRangedThreat.minReached then
        parryController:prepareOrSendRangedThreat(realDeltaT)
    end
    if parryController.myMeleeThreat.minReached then
        parryController:readMeleeWindup(realDeltaT, self.controls.use)
    end

    local lastFrameStanceIsWeapon = frameStanceIsWeapon
    frameStanceIsWeapon = (getStance(self) == types.Actor.STANCE.Weapon)
    local becameWeaponStance = (not lastFrameStanceIsWeapon and frameStanceIsWeapon)
    local becameNotWeaponStance = (lastFrameStanceIsWeapon and not frameStanceIsWeapon)

    local lastFrameControlsUse = frameControlsUse
    frameControlsUse = self.controls.use
    local releasedAttack = (self.controls.use == self.ATTACK_TYPE.NoAttack and lastFrameControlsUse ~= self.ATTACK_TYPE.NoAttack)

    if releasedAttack then
        for _, target in pairs(parryController.targets) do
            target:sendEvent(
                "ngarde_attackReleased", parryController.myMeleeThreat)
        end
        parryController.myMeleeThreat.minReached = false
    end


    parryController:checkStaggerState()
    if becameNotWeaponStance then
        parryController:forceLowerGuard()
        parryController.isStaggered = false
        parryController.isParrying = false
    end
    if frameStanceIsWeapon then
        parryController:updateEquippedIfChanged()

        local trigger = processTriggerInputs()

        if input.getBooleanActionValue(SC.parryActionKey) == false and not trigger then
            parryController:tryLowerGuard()
        elseif input.getBooleanActionValue(SC.parryActionKey) or trigger then
            if not parryController.isAttacking then
                parryController:tryRaiseGuard()
            end
        end

        if parryController:isAttackForbidden() then
            self.controls.use = self.ATTACK_TYPE.NoAttack
        end
        if parryController.isParrying then
            parryController.localTimers.fatigueDrainTimer:processTimer(realDeltaT)
            parryController:processMoveSpeedPenalty()
        end
        if self.controls.use ~= self.ATTACK_TYPE.NoAttack then
            castToTarget()
            parryController:sendMeleeThreat(self)
        end
    end
end


local function onTeleported()
    parryController.targets = {}
end




--redirecting the event to the global script, so we can attach/detach actor scripts
local function onCombatTargetChanged(eventData)
    if eventData.actor ~= nil then
        local record = eventData.actor.type.record(eventData.actor)
        if (eventData.actor.type == types.NPC or
                (Helpers.arrayContains(Constants.creatureWhiteList, record.id:lower())) or
                (eventData.actor.type == types.Creature and record.canUseWeapons and not Helpers.arrayContains(Constants.creatureBlackList, record.id:lower()))) then
            eventData.fencer = true
        elseif (eventData.actor.type == types.Creature and not record.canUseWeapons) or
            not (Helpers.arrayContains(Constants.creatureWhiteList, record.id:lower())) or
            Helpers.arrayContains(Constants.creatureBlackList, record.id:lower()) then
            eventData.fencer = false
        end
        core.sendGlobalEvent("ngarde_combatTargetChanged", eventData)
    end
end



-- local function onKeyPress(e)
--     if e.code == input.KEY.K then
--         parryController:findDirectionToMove()
--         return
--     end
-- end

local function onEnemyAttackReleased(eventData)
    parryController.enemyAttackData = eventData
end

local function onInit()
    -- readMenuSettings()
    return
end
local function onLoad(data)
    -- readMenuSettings()
    return
end

local function onStopSFX(magicEffect)
    ambient.stopSound(magicEffect.areaSound);
    ambient.stopSound(magicEffect.hitSound);
    ambient.stopSound(magicEffect.boltSound);
end


local NGardePlayer = {}

NGardePlayer.version = modInfo.interfaceVersion
NGardePlayer.isStaggered = function()
    return parryController.isStaggered
end
NGardePlayer.isAttacking = function()
    return parryController.isAttacking
end
NGardePlayer.startedParry = function()
    return parryController.startedParry
end
NGardePlayer.isParrying = function()
    return parryController.isParrying
end
NGardePlayer.isAttackForbidden = function()
    return parryController:isAttackForbidden()
end
NGardePlayer.canParry = function ()
    return parryController:canParry()
end

return {
    interfaceName = "NGardePlayer",
    interface = NGardePlayer,
    engineHandlers = {
        onFrame = onFrame,
        -- onKeyPress = onKeyPress,
        onTeleported = onTeleported,
        onInit = onInit,
        onLoad = onLoad,
    },
    eventHandlers = {
        OMWMusicCombatTargetsChanged = onCombatTargetChanged,
        ngarde_stopSFXPlayer = onStopSFX,
        ngarde_perfectParry = onEnemyPerfectParry,
        ngarde_attackReleased = onEnemyAttackReleased,
    }
}
