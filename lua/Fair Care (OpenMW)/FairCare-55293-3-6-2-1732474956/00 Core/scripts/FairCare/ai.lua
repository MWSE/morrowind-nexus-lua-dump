local core = require('openmw.core')
local I = require("openmw.interfaces")
local T = require('openmw.types')
local self = require('openmw.self')

local mTools = require('scripts.FairCare.tools')
local mCfg = require('scripts.FairCare.configuration')
local mData = require('scripts.FairCare.data')

local module = {}

local actorId = mTools.actorId(self)

local function newAiState()
    return {
        checkAiPackageTime = 0,
        prevAiPackageType = "",
        prevAiPackageKey = "",
        enemies = nil,
    }
end
module.newAiState = newAiState

local function clearState(state)
    state.ai = newAiState()
end
module.clearState = clearState

local function getAiPackageKey(package)
    if not package then return "" end
    return package.type .. (package.target and package.target.id or "")
end

local function isActive(state)
    return state.aiMode == mData.aiModes.Default or state.aiMode == mData.aiModes.Healing
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
        state.healDelayStartTime = core.getSimulationTime()
    end
    if aiPackageKey ~= state.ai.prevAiPackageKey then
        self:sendEvent("fairCare_updateFollowBounds")
    end
    state.ai.prevAiPackageType = package and package.type or ""
    state.ai.prevAiPackageKey = aiPackageKey
end
module.checkAiPackage = self.type ~= T.Player and checkAiPackage or function() end

local function getActiveFollowing()
    local followings = I.AI.getTargets("Follow")
    if followings and #followings > 0 then
        return followings[1]
    end
    return nil
end
module.getActiveFollowing = self.type ~= T.Player and getActiveFollowing or function() end

local function follow(following)
    mTools.debugPrint(string.format("%s follows %s", actorId, mTools.actorId(following)))
    I.AI.startPackage({ type = "Follow", target = following, cancelOther = false })
end
module.follow = self.type ~= T.Player and follow or function() end

local function clearFollowing(following)
    I.AI.filterPackages(function(package)
        if package.type == "Follow" and package.target.id == following.id then
            mTools.debugPrint(string.format("%s removes AI Follow target %s", actorId, mTools.actorId(following)))
            return false
        end
        return true
    end)
end
module.clearFollowing = self.type ~= T.Player and clearFollowing or function() end

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
        mTools.debugPrint(string.format("%s Mercy CAO control for %s", enable and "Enabling" or "Disabling", actorId))
        I.MercyCAO.setEnabled(enable)
    end
    if I.TakeCover then
        mTools.debugPrint(string.format("%s Take Cover hiding for %s", enable and "Enabling" or "Disabling", actorId))
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
    --mTools.debugPrint(string.format("Applying controls: run=%s, jump=%s, sneak=%s, movement=%s, sideMovements=%s, yawChange=%s, pitchChange=%s, use=%s",
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
module.applyControls = self.type ~= T.Player and applyControls or function() end

return module