local I = require("openmw.interfaces")
local self = require('openmw.self')
local T = require('openmw.types')

local mUtil = require('scripts.FairCare.util')

local module = {}

local actorRId = mUtil.getRecord(self).id

local aiModes = {
    Dead = 0,
    Inactive = 1,
    Default = 2,
    HealFriend = 3,
}
module.aiModes = aiModes

local function getAiPackageKey(package)
    if not package then return "" end
    return package.type .. (package.target and package.target.id or "")
end

local function checkAiPackage(state)
    local package = I.AI.getActivePackage()
    state.combatTarget = (package and package.type == "Combat") and package.target or nil
    local aiPackageKey = getAiPackageKey(package)
    if aiPackageKey ~= state.prevAiPackageKey then
        self:sendEvent("fc_updateFollowBounds")
    end
    state.prevAiPackageKey = aiPackageKey
end
module.checkAiPackage = self.type ~= T.Player and checkAiPackage or function() end

local function clearAi(state)
    state.prevAiPackageKey = nil
    state.combatTarget = nil
end
module.clearAi = clearAi

local function getActiveFollowing()
    return I.AI.getActiveTarget("Follow")
end
module.getActiveFollowing = self.type ~= T.Player and getActiveFollowing or function() end

local function follow(following)
    mUtil.debugPrint(string.format("\"%s\" follows \"%s\"", actorRId, mUtil.getRecord(following).id))
    I.AI.startPackage({ type = "Follow", target = following, cancelOther = false })
end
module.follow = self.type ~= T.Player and follow or function() end

local function clearFollowing(following)
    I.AI.filterPackages(function(package)
        if package.type == "Follow" and package.target.id == following.id then
            mUtil.debugPrint(string.format("\"%s\" removes AI Follow target \"%s\"", actorRId, mUtil.getRecord(following).id))
            return false
        end
        return true
    end)
end
module.clearFollowing = self.type ~= T.Player and clearFollowing or function() end

return module