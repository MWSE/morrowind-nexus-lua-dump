local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local selfToSettings = {
    [types.Player]   = storage.globalSection('SettingsFriendlierFire_followersToPlayer'),
    [types.NPC]      = storage.globalSection('SettingsFriendlierFire_playerToFollowers'),
    [types.Creature] = storage.globalSection('SettingsFriendlierFire_playerToFollowers'),
}

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

    local attackFilter = selfToAttackFilter[self.type]
    if attackFilter(attack) then return end

    local settings = selfToSettings[self.type]

    attack.damage.health = (attack.damage.health or 0) * settings:get("hpDamageMultiplier")
    attack.damage.fatigue = (attack.damage.fatigue or 0) * settings:get("fatDamageMultiplier")
    attack.damage.magicka = (attack.damage.magicka or 0) * settings:get("magDamageMultiplier")
end
