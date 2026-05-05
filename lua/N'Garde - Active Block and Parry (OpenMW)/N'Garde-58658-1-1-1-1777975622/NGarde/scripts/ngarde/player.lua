local modInfo           = require('scripts.ngarde.modinfo')
local core              = require('openmw.core')
local I                 = require('openmw.interfaces')
local input             = require('openmw.input')
local self              = require('openmw.self')
local types             = require('openmw.types')
local storage           = require('openmw.storage')
local ambient           = require('openmw.ambient')
local ui                = require('openmw.ui')
local async             = require('openmw.async')
local SettingsConstants = require('scripts.ngarde.helpers.settings_constants')
local logging           = require('scripts.ngarde.helpers.logger').new()
local targetRaycast     = require('scripts.ngarde.helpers.target_raycast').new()
local parryController   = require('scripts.ngarde.controllers.parry').new()
local l10n              = core.l10n(modInfo.l10n)
logging:setLoglevel(logging.LOG_LEVELS.OFF)
local getStance           = types.Actor.getStance
local isDead              = types.Actor.isDead
local getWeaponRecord     = types.Weapon.record
local skills              = types.NPC.stats.skills
local min                 = math.min

local onHitHandler        = function(attack)
    logging:debug("entered PLAYER on hit handler")
    logging:debug(attack)
    attack = parryController:onHitHandler(attack)
end

local skillLevelUpHandler = function(skillID, source, options)
    -- skill is not yet incremented during handler, so all comparisons are made against n-1 values
    if skillID == "handtohand" and skills.handtohand == parryController.ironPalmThreshold - 1 then
        ui.showMessage(l10n("iron_palm_threshold_level_up_message"))
    end
    if Helpers.arrayContains(Constants.meleeWeaponSkillIds, skillID) then
        parryController:statUpdate({ skillID })
        if parryController.currentStats[skillID].value == parryController.perfectParryThreshold - 1 then
            ---@diagnostic disable-next-line redundant-parameter
            ui.showMessage(l10n("perfect_parry_threshold_level_up_message", { skill = Constants.skillIdToName[skillID] }))
        end
    end
end



local function registerHandlers()
    if I.SkillEvolution and I.SkillEvolution.addOnHitHandler then
        logging:status("registering SE onHitHandler")
        I.SkillEvolution.addOnHitHandler(onHitHandler)
    else
        logging:status("registering regular onHitHandler")
        I.Combat.addOnHitHandler(onHitHandler)
    end
    I.SkillProgression.addSkillLevelUpHandler(skillLevelUpHandler)
end

registerHandlers()


local function castToTarget()
    local result = targetRaycast:castToCursor(self)
    logging:debug(result.hitObject)
    if result.hitTypeName == "NPC" or result.hitTypeName == "Creature" then
        local targetId = result.hitObject.id
        if not isDead(result.hitObject) and parryController.targets[targetId] == nil then
            parryController.primaryTarget = result.hitObject
            parryController.targets[targetId] = result.hitObject
        end
        -- elseif isDead(result.hitObject) and parryController.targets[targetId] ~= nil then --resetting target when we look away
        --     parryController.targets[targetId] = nil
        -- end
    end
end



-- local anim = require('openmw.animation')
local function onFrame(dt)
    if core.isWorldPaused() then return end

    -- logging:debug("torso:" .. anim.getActiveGroup(self, anim.BONE_GROUP.Torso))
    -- logging:debug("lower:" .. anim.getActiveGroup(self, anim.BONE_GROUP.LowerBody))
    -- logging:debug("r_arm:" .. anim.getActiveGroup(self, anim.BONE_GROUP.RightArm))
    -- logging:debug("l_arm:" .. anim.getActiveGroup(self, anim.BONE_GROUP.LeftArm))
    local realDeltaT = core.getRealFrameDuration()

    parryController:updateEquippedIfChanged()
    parryController:checkStaggerState()
    parryController:checkAttackState(self.controls.use)
    if input.getBooleanActionValue(SettingsConstants.parryActionKey) == false then
        parryController:tryLowerGuard()
    elseif input.getBooleanActionValue(SettingsConstants.parryActionKey) then
        parryController:tryRaiseGuard()
    end

    if parryController.isStaggered or parryController.isParrying then
        self.controls.use = self.ATTACK_TYPE.NoAttack
        if parryController.isParrying then
            parryController.localTimers.fatigueDrainTimer:processTimer(realDeltaT)
            parryController:processMoveSpeedPenalty()
        end
    end

    if (getStance(self) == types.Actor.STANCE.Weapon) then
        if self.controls.use ~= self.ATTACK_TYPE.NoAttack then
            castToTarget()
            for _, target in pairs(parryController.targets) do
                target:sendEvent(
                    "ngarde_onThreat",
                    {
                        actor = self,
                        threatType = parryController.recordEquippedR.type,
                        threatReach = parryController.recordEquippedR.reach
                    })
            end
        end
    elseif (getStance(self) ~= types.Actor.STANCE.Weapon) then
        if parryController.isParrying then
            parryController:tryLowerGuard()
        end
    end
    --#region timers

    --#region Perfect Parry
    parryController.localTimers.perfectParryTimer:processTimer(realDeltaT)
    parryController.localTimers.staggerCooldownTimer:processTimer(realDeltaT)
    parryController.localTimers.skillGainParryTimer:processTimer(realDeltaT)
    --#endregion
end


local function onTeleported()
    parryController.targets = {}
end




--redirecting the event to the global script, so we can attach/detach actor scripts
local function onCombatTargetChanged(eventData)
    if eventData.actor ~= nil then
        local record
        if eventData.actor.type == types.Creature then
            record = types.Creature.record(eventData.actor)
        end
        if (eventData.actor.type == types.NPC or (eventData.actor.type == types.Creature and record.canUseWeapons and not Helpers.arrayContains(Constants.creatureBlackList, record.id:lower()))) then
            eventData.fencer = true
            core.sendGlobalEvent("ngarde_combatTargetChanged", eventData)
        elseif (eventData.actor.type == types.Creature and not record.canUseWeapons) or Helpers.arrayContains(Constants.creatureBlackList, record.id) then
            eventData.fencer = false
            core.sendGlobalEvent("ngarde_combatTargetChanged", eventData)
        end
    end
end



-- local function onKeyPress(e)
--     if e.code == input.KEY.K then
--         parryController:findDirectionToMove()
--         return
--     end
-- end



local function migrateKeyBind()
    local storageSection = storage.globalSection(SettingsConstants.generalSettingsStorageKey)
    local flag = storageSection:getCopy("settingsMigrated")
    if flag == true then return end
    local oldPrefix      = "Lua Parry"
    local newPrefix      = modInfo.modKey
    --one Input Binding
    local oldInputKey, _ = SettingsConstants.settingsParryKeyBindKey:gsub(newPrefix, oldPrefix)
    local currentKeyBind = storage.playerSection("OMWInputBindings"):get(oldInputKey)
    local writeT         = {}

    if currentKeyBind == nil then
        return
    end
    for k, v in pairs(currentKeyBind) do
        if k == "key" then
            v, _ = v:gsub(oldPrefix, newPrefix)
        end
        writeT[k] = v
    end
    storage.playerSection("OMWInputBindings"):set(SettingsConstants.settingsParryKeyBindKey, writeT)
end

local function onInit()
    migrateKeyBind()
end
local function onLoad(data)
    migrateKeyBind()
end

local function onStopSFX(magicEffect)
    ambient.stopSound(magicEffect.areaSound);
    ambient.stopSound(magicEffect.hitSound);
    ambient.stopSound(magicEffect.boltSound);
end



local function onPerfectParry()
    parryController:onEnemyPerfectParry()
end

return {
    engineHandlers = {
        onFrame = onFrame,
        -- onKeyPress = onKeyPress,
        onTeleported = onTeleported,
        onInit = onInit,
        onLoad = onLoad,
    },
    eventHandlers = {
        OMWMusicCombatTargetsChanged = onCombatTargetChanged,
        ngarde_stopSFXPl = onStopSFX,
        ngarde_perfectParry = onPerfectParry,
    }
}
