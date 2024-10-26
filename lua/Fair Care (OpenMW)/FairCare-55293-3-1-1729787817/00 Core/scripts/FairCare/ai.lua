local I = require("openmw.interfaces")
local T = require('openmw.types')
local self = require('openmw.self')

local mSettings = require('scripts.FairCare.settings')
local mCfg = require('scripts.FairCare.configuration')
local mData = require('scripts.FairCare.data')
local mActors = require('scripts.FairCare.actors')

local module = {}

local actorId = mActors.getRecord(self).id

local function newAiState()
    return {
        checkAiPackageTime = 0,
        prevAiPackageKey = "",
        combatTarget = nil,
    }
end
module.newAiState = newAiState

local function getAiPackageKey(package)
    if not package then return "" end
    return package.type .. (package.target and package.target.id or "")
end

local function isActive(state)
    return state.aiMode == mData.aiModes.Default or state.aiModes == mData.aiModes.HealFriend
end
module.isActive = isActive

local function checkAiPackage(state, deltaTime)
    if deltaTime then
        state.ai.checkAiPackageTime = state.ai.checkAiPackageTime + deltaTime
        if state.ai.checkAiPackageTime <= mCfg.checkAiPackageRefreshTime then return end
    end
    state.ai.checkAiPackageTime = 0

    local package = I.AI.getActivePackage()
    state.ai.combatTarget = (package and package.type == "Combat") and package.target or nil
    local aiPackageKey = getAiPackageKey(package)
    if aiPackageKey ~= state.ai.prevAiPackageKey then
        self:sendEvent("fc_updateFollowBounds")
    end
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
    mSettings.debugPrint(string.format("%s follows %s", actorId, mActors.actorId(following)))
    I.AI.startPackage({ type = "Follow", target = following, cancelOther = false })
end
module.follow = self.type ~= T.Player and follow or function() end

local function clearFollowing(following)
    I.AI.filterPackages(function(package)
        if package.type == "Follow" and package.target.id == following.id then
            mSettings.debugPrint(string.format("%s removes AI Follow target %s", actorId, mActors.actorId(following)))
            return false
        end
        return true
    end)
end
module.clearFollowing = self.type ~= T.Player and clearFollowing or function() end

return module