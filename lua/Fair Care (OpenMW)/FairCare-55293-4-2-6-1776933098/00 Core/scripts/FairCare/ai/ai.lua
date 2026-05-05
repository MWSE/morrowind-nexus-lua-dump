local I = require("openmw.interfaces")
local T = require('openmw.types')
local self = require('openmw.self')

local log = require('scripts.FairCare.util.log')
local mDef = require('scripts.FairCare.config.definition')
local mCfg = require('scripts.FairCare.config.config')
local mTypes = require('scripts.FairCare.config.types')
local mTools = require('scripts.FairCare.util.tools')

local module = {}

module.newAiState = function()
    return {
        checkAiPackageTime = 0,
        prevAiPackageType = "",
        prevAiPackageKey = "",
        enemies = nil,
    }
end

local function noPlayerAi(func)
    return self.type ~= T.Player and func or function() end
end

module.clearState = function(state)
    state.ai = module.newAiState()
end

local function getAiPackageKey(package)
    if not package then return "" end
    return package.type .. (package.target and package.target.id or "")
end

module.isActive = function(state)
    return state.aiMode == mTypes.aiModes.Default or state.aiMode == mTypes.aiModes.Healing
end

module.onUpdate = noPlayerAi(function(state, deltaTime)
    if deltaTime then
        state.ai.checkAiPackageTime = state.ai.checkAiPackageTime + deltaTime
        if state.ai.checkAiPackageTime < mCfg.checkAiPackageRefreshTime then return end
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
end)

module.getActiveFollowing = noPlayerAi(function(state)
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
end)

module.follow = noPlayerAi(function(following)
    log(string.format("Follows %s", mTools.objectId(following)))
    I.AI.startPackage({ type = "Follow", target = following, cancelOther = false })
end)

module.clearFollowing = noPlayerAi(function(following)
    I.AI.filterPackages(function(package)
        if package.type == "Follow" and package.target.id == following.id then
            log(string.format("Removes AI Follow target %s", mTools.objectId(following)))
            return false
        end
        return true
    end)
end)

module.hasCommonEnemies = function(state, actorEnemies)
    if not actorEnemies or not state.ai.enemies then return false end
    for _, selfEnemy in ipairs(state.ai.enemies) do
        for _, actorEnemy in ipairs(actorEnemies) do
            if selfEnemy.id == actorEnemy.id then return true end
        end
    end
    return false
end

module.areOtherAiModsProcessing = function(state)
    return state.ai.enemies and (I.MercyCAO or I.TakeCover and I.TakeCover.isHidden())
end

module.isActorHidden = function()
    return I.TakeCover and I.TakeCover.isHidden()
end

module.setEnableOtherAiMods = function(enable)
    if I.MercyCAO then
        log(string.format("%s Mercy CAO control", enable and "Enabling" or "Disabling"))
        I.MercyCAO.setEnabled(enable)
    end
    if I.TakeCover then
        log(string.format("%s Take Cover hiding", enable and "Enabling" or "Disabling"))
        I.TakeCover.enableHiding(enable)
    end
end

module.newControls = function(actor)
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

module.applyControls = noPlayerAi(function(controls)
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
end)

return module