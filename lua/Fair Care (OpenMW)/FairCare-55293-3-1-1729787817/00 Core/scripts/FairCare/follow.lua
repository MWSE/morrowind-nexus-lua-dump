local self = require('openmw.self')

local mSettings = require('scripts.FairCare.settings')
local mUtil = require('scripts.FairCare.tools')
local mActors = require('scripts.FairCare.actors')
local mAi = require('scripts.FairCare.ai')

local module = {}

local actorId = mActors.actorId(self)

local function newFollowState()
    return {
        following = nil,
        followers = {},
        followerTeam = {},
    }
end
module.newFollowState = newFollowState

local function checkFollowBoundValidity(state)
    if mUtil.isObjectInvalid(state.follow.following) then
        mSettings.debugPrint(string.format("Following's object %s is not more valid for follower %s", state.follow.following, actorId))
        state.following = nil
        state.followerTeam = nil
    end
    local change = false
    for id, follower in pairs(state.follow.followers) do
        if mUtil.isObjectInvalid(follower) then
            mSettings.debugPrint(string.format("Follower's object %s is not more valid for following %s", follower, actorId))
            change = true
            state.follow.followers[id] = nil
        end
    end
    if change then
        for _, follower in pairs(state.follow.followers) do
            follower:sendEvent("fc_setFollowerTeam", state.follow.followers)
        end
    end
end
module.checkFollowBoundValidity = checkFollowBoundValidity

local function updateFollowBounds(state)
    local following = mAi.getActiveFollowing()
    if not mUtil.areObjectEquals(state.follow.following, following) then
        state.follow.followerTeam = {}
        if state.follow.following then
            state.follow.following:sendEvent("fc_clearFollower", self)
        elseif following then
            following:sendEvent("fc_addFollower", self)
        end
    end
    state.follow.following = following
end
module.updateFollowBounds = updateFollowBounds

local function addFollower(state, follower)
    mSettings.debugPrint(string.format("%s has a new follower %s", actorId, mActors.actorId(follower)))
    state.follow.followers[follower.id] = follower
    for _, fw in pairs(state.follow.followers) do
        fw:sendEvent("fc_setFollowerTeam", state.follow.followers)
    end
end
module.addFollower = addFollower

local function clearFollower(state, follower)
    mSettings.debugPrint(string.format("%s lost his follower %s", actorId, mActors.actorId(follower)))
    state.follow.followers[follower.id] = nil
    for _, fw in pairs(state.follow.followers) do
        fw:sendEvent("fc_setFollowerTeam", state.follow.followers)
    end
end
module.clearFollower = clearFollower

local function clearFollowing(state, following)
    mSettings.debugPrint(string.format("%s lost his following %s", actorId, mActors.actorId(following)))
    if state.follow.following and following.id == state.follow.following.id then
        state.follow.following = nil
        state.follow.followerTeam = {}
    end
end
module.clearFollowing = clearFollowing

local function setFollowerTeam(state, followerTeam)
    mSettings.debugPrint(string.format("%s is in a team of followers", actorId))
    state.follow.followerTeam = followerTeam
end
module.setFollowerTeam = setFollowerTeam

return module