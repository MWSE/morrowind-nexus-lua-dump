local self = require('openmw.self')

local log = require('scripts.FairCare.util.log')
local mDef = require('scripts.FairCare.config.definition')
local mAi = require('scripts.FairCare.ai.ai')
local mTools = require('scripts.FairCare.util.tools')

local module = {}

local followTeam = {}
local followTeamRemainingRequests = 1

module.newFollowState = function()
    return {
        following = nil,
        followers = {},
    }
end

module.addFollowTeamMembers = function(state, data)
    if not state.ai then return end
    if followTeam[data.teamMember.id] then return end
    followTeam[data.teamMember.id] = data.teamMember
    local followerCount = 0
    for _, follower in pairs(data.followers) do
        followerCount = followerCount + 1
        follower:sendEvent(mDef.events.gatherFollowers, data)
    end
    followTeamRemainingRequests = followTeamRemainingRequests - 1 + followerCount
    if followTeamRemainingRequests == 0 then
        log(string.format("Follower team is %s", mTools.objectsIds(followTeam)))
        self:sendEvent(data.event, followTeam)
    end
end

module.gatherFollowers = function(state, data)
    if not state.ai then return end
    data.teamMember = self
    data.followers = state.follow.followers
    if self.id == data.actor.id then
        module.addFollowTeamMembers(state, data)
    else
        data.actor:sendEvent(mDef.events.addFollowTeamMembers, data)
    end
end

module.getFollowRoot = function(state, data)
    if not state.ai then return end
    if state.follow.following then
        state.follow.following:sendEvent(mDef.events.getFollowRoot, data)
    else
        module.gatherFollowers(state, data)
    end
end

module.getFollowTeam = function(state, data)
    followTeam = {}
    followTeamRemainingRequests = 1
    module.getFollowRoot(state, data)
end

module.checkActorsValidity = function(state)
    if state.follow.following and mTools.isObjectInvalid(state.follow.following) then
        log(string.format("Clearing invalid following %s", mTools.objectId(state.follow.following)))
        state.follow.following = nil
    end
    local validFollowers = {}
    for _, follower in pairs(state.follow.followers) do
        if mTools.isObjectInvalid(follower) then
            log(string.format("Clearing invalid follower %s", mTools.objectId(follower)))
        else
            validFollowers[follower.id] = follower
        end
    end
    state.follow.followers = validFollowers
end

module.clearFollowBounds = function(state)
    if state.follow.following then
        state.follow.following:sendEvent(mDef.events.clearFollower, self)
    end
    for _, follower in pairs(state.follow.followers) do
        follower:sendEvent(mDef.events.clearFollowing, self)
    end
    state.follow = module.newFollowState()
end

module.updateFollowBounds = function(state)
    if not state.ai then return end
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

module.clearFollowing = function(state, following)
    if not state.ai then return end
    if mTools.areObjectEquals(following, state.follow.following) then
        log(string.format("Lost his following %s", mTools.objectId(following)))
        state.follow.following = nil
    end
end

module.addFollower = function(state, follower)
    if not state.ai then return end
    log(string.format("Has a new follower %s", mTools.objectId(follower)))
    state.follow.followers[follower.id] = follower
end

module.clearFollower = function(state, follower)
    if not state.ai then return end
    if state.follow.followers[follower.id] then
        log(string.format("Lost his follower %s", mTools.objectId(follower)))
        state.follow.followers[follower.id] = nil
    end
end

return module