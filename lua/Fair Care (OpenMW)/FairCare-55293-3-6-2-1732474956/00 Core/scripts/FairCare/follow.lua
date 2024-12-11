local self = require('openmw.self')

local mTools = require('scripts.FairCare.tools')
local mAi = require('scripts.FairCare.ai')

local module = {}
local followTeam = {}
local followTeamRemainingRequests = 1

local actorId = mTools.actorId(self)

local function newFollowState()
    return {
        following = nil,
        followers = {},
    }
end
module.newFollowState = newFollowState

local function addFollowTeamMembers(data)
    table.insert(followTeam, data.teamMember)
    local followerCount = 0
    for _, follower in pairs(data.followers) do
        followerCount = followerCount + 1
        follower:sendEvent("fairCare_gatherFollowers", data)
    end
    followTeamRemainingRequests = followTeamRemainingRequests - 1 + followerCount
    if followTeamRemainingRequests == 0 then
        mTools.debugPrint(string.format("%s follower team is %s", actorId, mTools.actorIds(followTeam)))
        self:sendEvent(data.event, followTeam)
    end
end
module.addFollowTeamMembers = addFollowTeamMembers

local function gatherFollowers(state, data)
    data.teamMember = self
    data.followers = state.follow.followers
    if self.id == data.actor.id then
        addFollowTeamMembers(data)
    else
        data.actor:sendEvent("fairCare_addFollowTeamMembers", data)
    end
end
module.gatherFollowers = gatherFollowers

local function getFollowRoot(state, data)
    if state.follow.following then
        state.follow.following:sendEvent("fairCare_getFollowRoot", data)
    else
        gatherFollowers(state, data)
    end
end
module.getFollowRoot = getFollowRoot

local function getFollowTeam(state, data)
    followTeam = {}
    followTeamRemainingRequests = 1
    getFollowRoot(state, data)
end
module.getFollowTeam = getFollowTeam

local function clearFollowBounds(state)
    if state.follow.following then
        state.follow.following:sendEvent("fairCare_clearFollower", self)
    end
    for _, follower in pairs(state.follow.followers) do
        follower:sendEvent("fairCare_clearFollowing", self)
    end
    state.follow = newFollowState()
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
end
module.checkActorReferences = checkActorReferences

local function updateFollowBounds(state)
    local following = mAi.getActiveFollowing()
    if not mTools.areObjectEquals(state.follow.following, following) then
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
    if mTools.areObjectEquals(following, state.follow.following) then
        mTools.debugPrint(string.format("%s lost his following %s", actorId, mTools.actorId(following)))
        state.follow.following = nil
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

return module