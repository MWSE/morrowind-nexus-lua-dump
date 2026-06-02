local omw_self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local I = require("openmw.interfaces")

---@class State
---@field actor any|nil
---@field leader any|nil
---@field superLeader any|nil
---@field followsPlayer boolean
local State = {}
State.__index = State

---@param leader any
---@return State
function State:new(leader)
    self = setmetatable({}, State)
    self.actor = omw_self
    self:setLeader(leader)
    return self
end

function State:__tostring()
    local lines = {
        "State(",
        "  actor         = " .. tostring(self.actor),
        "  followsPlayer = " .. tostring(self.followsPlayer),
        "  leader        = " .. tostring(self.leader),
        "  superLeader   = " .. tostring(self.superLeader),
        ")",
    }
    return table.concat(lines, "\n")
end

local function eqId(x)
    return x and x.id or nil
end

function State:__eq(a, b)
    return eqId(a.actor)       == eqId(b.actor)
       and eqId(a.leader)      == eqId(b.leader)
       and eqId(a.superLeader) == eqId(b.superLeader)
       and a.followsPlayer     == b.followsPlayer
end

function State:updateFollowerList()
    core.sendGlobalEvent("FDU_UpdateFollowerList", {
        state = self
    })
end

---@param leader any
function State:setLeader(leader)
    if leader == self.leader then return end

    self.leader = leader
    self.followsPlayer = leader and leader.type == types.Player or false

    if leader then
        self.setSuperLeader(self)
    end

    self.updateFollowerList(self)
end

function State:setSuperLeader()
    -- skip first update to initialize the script first
    if not I.FollowerDetectionUtil then
        self.leader = nil
        return
    end

    local followerList = I.FollowerDetectionUtil.getFollowerList()
    local leaderState = followerList[self.leader.id]

    if not (leaderState and leaderState.leader) then
        self.superLeader = nil
        return
    end

    self.superLeader = leaderState.leader
    self.followsPlayer = leaderState.leader.type == types.Player
end

return State
