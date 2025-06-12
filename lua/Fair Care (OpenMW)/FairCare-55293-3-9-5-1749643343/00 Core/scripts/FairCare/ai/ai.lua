local I = require("openmw.interfaces")
local T = require('openmw.types')
local self = require('openmw.self')

local mDef = require('scripts.FairCare.config.definition')
local mCfg = require('scripts.FairCare.config.config')
local mTypes = require('scripts.FairCare.config.types')
local mTools = require('scripts.FairCare.util.tools')
local log = require('scripts.FairCare.util.log')

local module = {}

local actorId = mTools.objectId(self)

local function newAiState()
    return {
        checkAiPackageTime = 0,
        prevAiPackageType = "",
        prevAiPackageKey = "",
        enemies = nil,
    }
end
module.newAiState = newAiState

local function noPlayerAi(func)
    return self.type ~= T.Player and func or function() end
end

local function clearState(state)
    state.ai = newAiState()
end
module.clearState = clearState

local function getAiPackageKey(package)
    if not package then return "" end
    return package.type .. (package.target and package.target.id or "")
end

local function isActive(state)
    return state.aiMode == mTypes.aiModes.Default or state.aiMode == mTypes.aiModes.Healing
end
module.isActive = isActive

local function checkAiPackage(state, deltaTime)
    if deltaTime then
        state.ai.checkAiPackageTime = state.ai.checkAiPackageTime + deltaTime
        if state.ai.checkAiPackageTime <= mCfg.checkAiPackageRefreshTime then return end
    end
    state.ai.checkAiPackageTime = 0

    local package = I.AI.getActivePackage()
    state.ai.enemies = (package and package.type == "Combat") and I.AI.getTargets("Combat") or nil
    local aiPackageKey = getAiPackageKey(package)
    if package and package.type ~= state.ai.prevAiPackageType and package.type == "Combat" then
        self:sendEvent(mDef.events.onCombatStart)
    end
    if aiPackageKey ~= state.ai.prevAiPackageKey then
        self:sendEvent(mDef.events.updateFollowBounds)
    end
    state.ai.prevAiPackageType = package and package.type or ""
    state.ai.prevAiPackageKey = aiPackageKey
end
module.checkAiPackage = noPlayerAi(checkAiPackage)

local function getActiveFollowing(state)
    local followings = I.AI.getTargets("Follow")
    for _, following in ipairs(followings) do
        if not state.ai.enemies then
            return following
        end
        for _, enemy in ipairs(state.ai.enemies) do
            if not mTools.areObjectEquals(following, enemy) then
                return following
            end
        end
    end
    return nil
end
module.getActiveFollowing = noPlayerAi(getActiveFollowing)

local function follow(following)
    log(string.format("%s follows %s", actorId, mTools.objectId(following)))
    I.AI.startPackage({ type = "Follow", target = following, cancelOther = false })
end
module.follow = self.type ~= T.Player and follow or function() end

local function clearFollowing(following)
    I.AI.filterPackages(function(package)
        if package.type == "Follow" and package.target.id == following.id then
            log(string.format("%s removes AI Follow target %s", actorId, mTools.objectId(following)))
            return false
        end
        return true
    end)
end
module.clearFollowing = noPlayerAi(clearFollowing)

local function areOtherAiModsProcessing(state)
    return state.ai.enemies and (I.MercyCAO or I.TakeCover and I.TakeCover.isHidden())
end
module.areOtherAiModsProcessing = areOtherAiModsProcessing

local function isActorHidden()
    return I.TakeCover and I.TakeCover.isHidden()
end
module.isActorHidden = isActorHidden

local function setEnableOtherAiMods(enable)
    if I.MercyCAO then
        log(string.format("%s Mercy CAO control for %s", enable and "Enabling" or "Disabling", actorId))
        I.MercyCAO.setEnabled(enable)
    end
    if I.TakeCover then
        log(string.format("%s Take Cover hiding for %s", enable and "Enabling" or "Disabling", actorId))
        I.TakeCover.enableHiding(enable)
    end
end
module.setEnableOtherAiMods = setEnableOtherAiMods

local function newControls(actor)
    return {
        run = false,
        jump = false,
        sneak = false,
        movement = 0,
        sideMovement = 0,
        yawChange = 0,
        pitchChange = 0,
        use = actor.ATTACK_TYPE.NoAttack,
    }
end
module.newControls = newControls

local function applyControls(controls)
    --log(string.format("Applying controls: run=%s, jump=%s, sneak=%s, movement=%s, sideMovements=%s, yawChange=%s, pitchChange=%s, use=%s",
    --        controls.run, controls.jump, controls.sneak, controls.movement, controls.sideMovement, controls.yawChange, controls.pitchChange, controls.use))
    self.controls.run = controls.run
    self.controls.jump = controls.jump
    self.controls.sneak = controls.sneak
    self.controls.movement = controls.movement
    self.controls.sideMovement = controls.sideMovement
    self.controls.yawChange = controls.yawChange
    self.controls.pitchChange = controls.pitchChange
    self.controls.use = controls.use
end
module.applyControls = noPlayerAi(applyControls)

return module