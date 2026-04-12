local selfType = require('openmw.self').type
local types = require('openmw.types')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local settings = storage.globalSection('SettingsFriendlierFire_settings')

local function playerAttackFilter(attack)
    local followerList = I.FollowerDetectionUtil.getFollowerList()
    return not followerList[attack.attacker.id]
end

local function actorAttackFilter(attack)
    local state = I.FollowerDetectionUtil.getState()
    local followerList = I.FollowerDetectionUtil.getFollowerList()

    local followsPlayer = state.followsPlayer
    local attackedByPlayer = attack.attacker.type == types.Player
    local attackerState = followerList[attack.attacker.id]
    local attackedByFollower = attackerState and attackerState.followsPlayer

    return not (followsPlayer and (attackedByPlayer or attackedByFollower))
end

local selfToAttackFilter = {
    [types.Player]   = playerAttackFilter,
    [types.NPC]      = actorAttackFilter,
    [types.Creature] = actorAttackFilter,
}

function AttackHandler(attack)
    if not attack.successful or not attack.attacker then return end

    local attackFilter = selfToAttackFilter[selfType]
    if attackFilter(attack) then return end

    if settings:get("damageMult") < 0 then return false end

    attack.damage.health = (attack.damage.health or 0) * settings:get("damageMult")
    attack.damage.fatigue = (attack.damage.fatigue or 0) * settings:get("damageMult")
end
