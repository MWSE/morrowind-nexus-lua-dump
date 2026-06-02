---@omw-context local
local I                 = require('openmw.interfaces')
local attackController  = require('scripts.ngarde.controllers.attack')
local SettingsConstants = require('scripts.ngarde.helpers.settings_constants')
local storage           = require('openmw.storage')
local types             = require("openmw.types")
local self              = require('openmw.self')
local anim              = require('openmw.animation')
local core              = require('openmw.core')
local async             = require('openmw.async')
local logging           = require('scripts.ngarde.helpers.logger').new()
local Constants         = require('scripts.ngarde.helpers.constants')
local parrySettings     = storage.globalSection(SettingsConstants.parrySettingsGroupKey)
local allAttacksHit     = SettingsConstants.allAttacksHitDefault
local random            = math.random
local isDead            = types.Actor.isDead
local getStance         = types.Actor.getStance

local isStaggered       = false
local releaseActor      = false

I.Combat.addOnHitHandler(function(attack)
    if allAttacksHit then
        if not releaseActor then
            local isH2HAttack, isThrown, attackerIsCreature, attackerIsWeaponUser, _ = attackController.getAttackDetails(
                attack)
            if not attack.successful then
                attack = attackController.processFumble(self, attack, isH2HAttack, isThrown, attackerIsCreature,
                    attackerIsWeaponUser)
            end
        end
    end
end)

local function readSettings(groupname, key)
    if key == nil or key == SettingsConstants.allAttacksHitKey then
        allAttacksHit = SettingsConstants.readSetting(parrySettings,
            SettingsConstants.allAttacksHitKey)
    end
end

parrySettings:subscribe(async:callback(function(groupname, key)readSettings(groupname, key)end))


local function onLoad()
    readSettings()
end

local function onInit()
    readSettings()
end

local function onPerfectParry()
    isStaggered = true
    local hitIndex = "hit" .. tostring(random(1, 5))
    logging:debug(tostring(self) .. "playing:" .. hitIndex)
    I.AnimationController.playBlendedAnimation(hitIndex, {
        startKey = 'start',
        stopKey = 'stop',
        priority = {
            [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted,
            [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted,
            [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted,
            [anim.BONE_GROUP.LowerBody] = anim.PRIORITY.Scripted
        },
        autoDisable = true,
        blendMask = anim.BLEND_MASK.LeftArm +
            anim.BLEND_MASK.RightArm +
            anim.BLEND_MASK.Torso +
            anim.BLEND_MASK.LowerBody,
        speed = 1

    })
end


local function checkStaggerState()
    if (getStance(self) == types.Actor.STANCE.Weapon) then
        for _, animation in ipairs(Constants.staggerAnimations) do
            if anim.isPlaying(self, animation) then
                isStaggered = true
                return
            end
        end
    end
    isStaggered = false
end

local function onUpdate()
    if core.isWorldPaused() or
        isDead(self) or
        I.AI.isFleeing() or
        releaseActor then
        if isStaggered then
            isStaggered = false
        end
        return
    end
    checkStaggerState()

    if isStaggered then
        self.controls.use = 0
    end
end

local function onScriptAttached(eventData)
    logging:debug(tostring(self) .. " got creature script attached.")
    logging:debug(tostring(self) .. " in combat with:" .. tostring(eventData.targets[1]))
    releaseActor = false
end

local function onStopProcessing()
    releaseActor = true
    isStaggered = false
end

local function onResumeProcessing()
    releaseActor = false
end


local function detachCleanup()
    local cleanupEventData = { actor = self, fencer = false }
    releaseActor = true
    isStaggered = false
    core.sendGlobalEvent("ngarde_actorCleanedUp", cleanupEventData)
end


local function onScriptDetached()
    detachCleanup()
end

local function onInactive()
    detachCleanup()
end





return {
    engineHandlers = {
        onLoad = onLoad,
        onInit = onInit,
        onUpdate = onUpdate,
        onInactive = onInactive,
    },
    eventHandlers = {
        ngarde_perfectParry = onPerfectParry,
        ngarde_scriptAttached = onScriptAttached,
        ngarde_prepareDetach = onScriptDetached,
        ngarde_stopProcessing = onStopProcessing,
        ngarde_resumeProcessing = onResumeProcessing,
    }
}
