local self = require('openmw.self')

local mDef = require('scripts.FairCare.config.definition')
local mAi = require('scripts.FairCare.ai.ai')
local mTools = require('scripts.FairCare.util.tools')
local log = require('scripts.FairCare.util.log')

local module = {}
local followTeam = {}
local followTeamRemainingRequests = 1

local actorId = mTools.objectId(self)

local function newFollowState()
    return {
        following = nil,
        followers = {},
    }
end
module.newFollowState = newFollowState

local function addFollowTeamMembers(data)
    if followTeam[data.teamMember.id] then return end
    followTeam[data.teamMember.id] = data.teamMember
    local followerCount = 0
    for _, follower in pairs(data.followers) do
        followerCount = followerCount + 1
        follower:sendEvent(mDef.events.gatherFollowers, data)
    end
    followTeamRemainingRequests = followTeamRemainingRequests - 1 + followerCount
    if followTeamRemainingRequests == 0 then
        log(string.format("%s follower team is %s", actorId, mTools.objectsIds(followTeam)))
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
        data.actor:sendEvent(mDef.events.addFollowTeamMembers, data)
    end
end
module.gatherFollowers = gatherFollowers

local function getFollowRoot(state, data)
    if state.follow.following then
        state.follow.following:sendEvent(mDef.events.getFollowRoot, data)
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

local function checkActorsValidity(state)
    if state.follow.following and mTools.isObjectInvalid(state.follow.following) then
        log(string.format("Clearing %s invalid following actor %s", actorId, state.follow.following))
        state.follow.following = nil
    end
    local validFollowers = {}
    for _, follower in pairs(state.follow.followers) do
        if mTools.isObjectInvalid(follower) then
            log(string.format("Clearing %s invalid follower actor %s", actorId, follower))
        else
            validFollowers[follower.id] = follower
        end
    end
    state.follow.followers = validFollowers
end
module.checkActorsValidity = checkActorsValidity

local function clearFollowBounds(state)
    if state.follow.following then
        state.follow.following:sendEvent(mDef.events.clearFollower, self)
    end
    for _, follower in pairs(state.follow.followers) do
        follower:sendEvent(mDef.events.clearFollowing, self)
    end
    state.follow = newFollowState()
end
module.clearFollowBounds = clearFollowBounds

local function updateFollowBounds(state)
    local following = mAi.getActiveFollowing(state)
    if not mTools.areObjectEquals(state.follow.following, following) then
        if state.follow.following then
            state.follow.following:sendEvent(mDef.events.clearFollower, self)
        elseif following then
            following:sendEvent(mDef.events.addFollower, self)
        end
    end
    state.follow.following = following
end
module.updateFollowBounds = updateFollowBounds

local function clearFollowing(state, following)
    if mTools.areObjectEquals(following, state.follow.following) then
        log(string.format("%s lost his following %s", actorId, mTools.objectId(following)))
        state.follow.following = nil
    end
end
module.clearFollowing = clearFollowing

local function addFollower(state, follower)
    log(string.format("%s has a new follower %s", actorId, mTools.objectId(follower)))
    state.follow.followers[follower.id] = follower
end
module.addFollower = addFollower

local function clearFollower(state, follower)
    if state.follow.followers[follower.id] then
        log(string.format("%s lost his follower %s", actorId, mTools.objectId(follower)))
        state.follow.followers[follower.id] = nil
    end
end
module.clearFollower = clearFollower

return module