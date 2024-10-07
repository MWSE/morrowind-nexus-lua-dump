local self = require('openmw.self')

local mUtil = require('scripts.FairCare.util')
local mAi = require('scripts.FairCare.ai')

local module = {}

local actorRId = mUtil.getRecord(self).id

local function clearFollowBounds(state)
    if state.following then
        state.following:sendEvent("fc_clearFollower", self)
        state.following = nil
    end
    for _, follower in ipairs(state.followers) do
        follower:sendEvent("fc_clearFollowing", self)
    end
end
module.clearFollowBounds = clearFollowBounds

local function updateFollowBounds(state)
    local following = mAi.getActiveFollowing()
    if not mUtil.areObjectEquals(state.following, following) then
        if state.following then
            state.following:sendEvent("fc_clearFollower", self)
        elseif following then
            following:sendEvent("fc_addFollower", self)
        end
    end
    state.following = following
end
module.updateFollowBounds = updateFollowBounds

local function addFollower(state, follower)
    mUtil.debugPrint(string.format("\"%s\" has a new follower \"%s\"", actorRId, mUtil.getRecord(follower).id))
    state.followers[follower.id] = follower
end
module.addFollower = addFollower

local function clearFollower(state, follower)
    mUtil.debugPrint(string.format("\"%s\" lost his follower \"%s\"", actorRId, mUtil.getRecord(follower).id))
    state.followers[follower.id] = nil
end
module.clearFollower = clearFollower

local function clearFollowing(state, following)
    mUtil.debugPrint(string.format("\"%s\" lost his following \"%s\"", actorRId, mUtil.getRecord(following).id))
    if state.following and following.id == state.following.id then
        state.following = nil
    end
end
module.clearFollowing = clearFollowing

return module

