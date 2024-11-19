local self = require('openmw.self')

local mTools = require('scripts.FairCare.tools')
local mAi = require('scripts.FairCare.ai')

local module = {}

local actorId = mTools.actorId(self)

local function newFollowState()
    return {
        following = nil,
        followers = {},
        followerTeam = {},
    }
end
module.newFollowState = newFollowState

local function clearFollowBounds(state)
    if state.follow.following then
        state.follow.following:sendEvent("fairCare_clearFollower", self)
    end
    for _, follower in pairs(state.follow.followers) do
        follower:sendEvent("fairCare_clearFollowing", self)
    end
end
module.clearFollowBounds = clearFollowBounds

local function checkActorReferences(state)
    if state.follow.following and mTools.isObjectInvalid(state.follow.following) then
        mTools.debugPrint(string.format("Clearing %s invalid following actor %s", actorId, state.follow.following))
        state.follow.following = nil
    end
    local validFollowers = {}
    for _, follower in pairs(state.follow.followers) do
        if mTools.isObjectInvalid(follower) then
            mTools.debugPrint(string.format("Clearing %s invalid follower actor %s", actorId, follower))
        else
            table.insert(validFollowers, follower)
        end
    end
    state.follow.followers = validFollowers
    local validTeamFollowers = {}
    for _, follower in pairs(state.follow.followerTeam) do
        if mTools.isObjectInvalid(follower) then
            mTools.debugPrint(string.format("Clearing %s invalid team follower actor %s", actorId, follower))
        else
            table.insert(validTeamFollowers, follower)
        end
    end
    state.follow.followerTeam = validTeamFollowers
end
module.checkActorReferences = checkActorReferences

local function updateFollowBounds(state)
    local following = mAi.getActiveFollowing()
    if not mTools.areObjectEquals(state.follow.following, following) then
        state.follow.followerTeam = {}
        if state.follow.following then
            state.follow.following:sendEvent("fairCare_clearFollower", self)
        elseif following then
            following:sendEvent("fairCare_addFollower", self)
        end
    end
    state.follow.following = following
end
module.updateFollowBounds = updateFollowBounds

local function clearFollowing(state, following)
    if state.follow.following.id == following.id then
        mTools.debugPrint(string.format("%s lost his following %s", actorId, mTools.actorId(following)))
        state.follow.following = nil
        state.follow.followerTeam = nil
    end
end
module.clearFollowing = clearFollowing

local function addFollower(state, follower)
    mTools.debugPrint(string.format("%s has a new follower %s", actorId, mTools.actorId(follower)))
    state.follow.followers[follower.id] = follower
    for _, fw in pairs(state.follow.followers) do
        fw:sendEvent("fairCare_setFollowerTeam", state.follow.followers)
    end
end
module.addFollower = addFollower

local function clearFollower(state, follower)
    if state.follow.followers[follower.id] then
        mTools.debugPrint(string.format("%s lost his follower %s", actorId, mTools.actorId(follower)))
        state.follow.followers[follower.id] = nil
        for _, fw in pairs(state.follow.followers) do
            fw:sendEvent("fairCare_setFollowerTeam", state.follow.followers)
        end
    end
end
module.clearFollower = clearFollower

local function setFollowerTeam(state, followerTeam)
    mTools.debugPrint(string.format("%s is in a team of followers", actorId))
    state.follow.followerTeam = followerTeam
end
module.setFollowerTeam = setFollowerTeam

return module