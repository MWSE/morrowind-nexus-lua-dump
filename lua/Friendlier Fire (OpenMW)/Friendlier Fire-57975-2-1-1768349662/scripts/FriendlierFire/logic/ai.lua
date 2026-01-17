local I = require('openmw.interfaces')
local types = require('openmw.types')
local storage = require('openmw.storage')

local sectionOther = storage.globalSection('SettingsFriendlierFire_other')

local function stopAttackingPlayer(data)
    if data.target.type ~= types.Player then return end

    local state = I.FollowerDetectionUtil.getState()
    if not state.followsPlayer then return end

    I.AI.filterPackages(function(pkg)
        return not (pkg.type == "Combat" and pkg.target.type == types.Player)
    end)
end

local function stopAttackingFollower(data)
    local followers = I.FollowerDetectionUtil.getFollowerList()
    local targetState = followers[data.target.id]
    if not (targetState and targetState.followsPlayer) then return end

    I.AI.filterPackages(function(pkg)
        return not (pkg.type == "Combat" and followers[pkg.target.id])
    end)
end

function TargetChanged(data)
    if not sectionOther:get("disableAggro") or not data.target then return end
    stopAttackingPlayer(data)
    stopAttackingFollower(data)
end
