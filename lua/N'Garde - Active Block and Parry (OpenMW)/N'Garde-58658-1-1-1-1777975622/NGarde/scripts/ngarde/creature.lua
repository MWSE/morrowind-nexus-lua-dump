local I                 = require('openmw.interfaces')
local attackController  = require('scripts.ngarde.controllers.attack')
local SettingsConstants = require('scripts.ngarde.helpers.settings_constants')
local storage           = require('openmw.storage')
local types             = require("openmw.types")
local self              = require('openmw.self')
local anim              = require('openmw.animation')
local core              = require('openmw.core')
local async             = require('openmw.async')
local allAttacksHit     = SettingsConstants.allAttacksHitDefault
local logging           = require('scripts.ngarde.helpers.logger').new()
local Constants         = require('scripts.ngarde.helpers.constants')
logging:setLoglevel(logging.LOG_LEVELS.OFF)
local parrySettings = storage.globalSection(SettingsConstants.parrySettingsGroupKey)
local random        = math.random
local isDead        = types.Actor.isDead
local getStance     = types.Actor.getStance

local isStaggered   = false
local releaseActor  = false

I.Combat.addOnHitHandler(function(attack)
    if allAttacksHit then
        local isH2HAttack, isThrown, attackerIsCreature, attackerIsWeaponUser, _ = Helpers.getAttackDetails(attack)
        if not attack.successful then
            attack = attackController.processFumble(attack, isH2HAttack, isThrown, attackerIsCreature, attackerIsWeaponUser)
        end
    end
end)

local function onSettingsChanged()
    allAttacksHit = parrySettings:get(SettingsConstants.allAttacksHitKey)
end

local function onLoad()
    onSettingsChanged()
end

local function onInit()
    onSettingsChanged()
end

local function onPerfectParry()
    isStaggered = true
    local hitIndex = "hit" .. tostring(random(1, 5))
    logging:debug(tostring(self) .. "playing:" .. hitIndex)
    I.AnimationController.playBlendedAnimation(hitIndex, {
        startKey = 'start',
        stopKey = 'stop',
        ---@diagnostic disable-next-line: assign-type-mismatch
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
    logging:debug(tostring(self) .. " got actor script attached.")
    releaseActor = false
end

local function onScriptDetached()
    if not isDead(self) then
        releaseActor = true
    end
end


storage.globalSection(SettingsConstants.parrySettingsGroupKey):subscribe(
    async:callback(onSettingsChanged))


return {
    engineHandlers = {
        onLoad = onLoad,
        onInit = onInit,
        onUpdate = onUpdate,
    },
    eventHandlers = {
        ngarde_perfectParry = onPerfectParry,
        ngarde_onScriptAttached = onScriptAttached,
        ngarde_onScriptDetached = onScriptDetached,
    }
}
