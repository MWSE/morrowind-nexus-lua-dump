local nearby = require('openmw.nearby')
local types = require('openmw.types')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local storage = require('openmw.storage')
local summons = storage.globalSection('BattleExpSummons')

local wasFollower = I.FollowerDetectionUtil.getState().followsPlayer
local playerFollowers = storage.globalSection('PlayerFollowers')

local H = require('scripts/BattleExp/helpers')
local log = H.log

local settings = storage.globalSection('SettingsBattleExp')
local DEBUG = settings:get('debug')
H.setDebug(DEBUG)

local isThisActorPlayerSummon = false
local lastAttacker = nil

local function findPlayer()
  for _, actor in ipairs(nearby.actors) do
    if types.Player.objectIsInstance(actor) then
      return actor
    end
  end
  return nil
end

local function getPlayerActiveSummonEffects(playerObj)
  local summonEffects = {}
  for _, effect in pairs(types.Actor.activeEffects(playerObj)) do
    if effect.id:find('^summon') then
      summonEffects[(effect.name:gsub('Summon', 'Summoned'))] = true
    end
  end
  return summonEffects
end

local function getActorName(object)
  if types.NPC.objectIsInstance(object) then
    return types.NPC.record(object).name
  elseif types.Creature.objectIsInstance(object) then
    return types.Creature.record(object).name
  end
  return 'Unknown Enemy'
end

local function checkAndCachePlayerSummon()
  local playerObj = findPlayer()
  if not playerObj then
    log('no player found')
    return
  end

  local creatureName = tostring(getActorName(self.object))
  local recordId = self.recordId

  log('new creature has just spawned')
  log('creature (self.recordId): %s', tostring(recordId))
  log('creature name: %s', creatureName)

  if not recordId:find('_summ') then
    log('not a summon creature, skipping')
    return
  end

  local AI = I.AI
  if not AI then return end

  -- At spawn time, before combat, Follow->player should be the active package
  -- during combat, summons positioned close to enemy, will be in combat from the start
  local package = AI.getActivePackage(self.object)
  log(string.format('summon has currently package type: %s', tostring(package and package.type)))

  if package and package.type == 'Combat' then
    -- summon is in combat from the start, but might have been summoned by player during combat
    local playerSummonEffects = getPlayerActiveSummonEffects(playerObj)
    if not next(playerSummonEffects) then
      log('player has no active summon effects, not a player summon')
      return
    end

    for key, value in pairs(playerSummonEffects) do
      log('player has active summon spell: %s', tostring(key))
    end

    if playerSummonEffects[creatureName] then
      log('active effect name matched with creature name (not bulletproof)')
    else
      log('player has currently no summon effects active or summon name did not match')
      return
    end

    log('This summon was probably summoned by the player')
    isThisActorPlayerSummon = true
    core.sendGlobalEvent('RegisterPlayerSummon', self.object)
    return
  end

  if not (package and package.type == 'Follow' and package.target and types.Player.objectIsInstance(package.target)) then
    log('This summon was not summoned by the player!')
    return
  end

  log('This summon is a player\'s summon, caching')
  isThisActorPlayerSummon = true
  core.sendGlobalEvent('RegisterPlayerSummon', self.object)
end

local function isPlayerAlly(actor)
  -- old way
  if summons:get(actor.id) then 
    log('%s is player\'s summon! actor.id: %s', getActorName(actor), tostring(actor.id))
    return true
  end

  local followersAll = playerFollowers:get('all')
  if not followersAll or not H.countTruthyValues(followersAll) then
    log('FDU registers no player followers')
    return false
  end

  log('is %s player\'s follower? %s', getActorName(actor), followersAll and followersAll[actor.id])

  if followersAll[actor.id] then
    log('%s is player\'s follower!', getActorName(actor))
    return true
  end

  if (wasFollower) then
    log('%s was player\'s follower!', getActorName(actor))
    return true
  end

  return false
end

local function updateFollowerStatus(data)
  -- it does not update on death
  local health = types.Actor.stats.dynamic.health(self.object).current
  log('wasFollower updated! %s health: %s', getActorName(self.object), health)

  if health > 0 then
    wasFollower = data.followers[self.id] and data.followers[self.id].followsPlayer or false    
  end
end

I.Combat.addOnHitHandler(function(attack)
  log('addOnHitHandler')
  if attack.attacker then
    log('%s was hit by %s', getActorName(self.object), getActorName(attack.attacker))
    local playerObj = findPlayer()
    if lastAttacker and lastAttacker.id == playerObj.id then 
      log('player or player ally already hit this actor, no need to update')
      return 
    end

    if not isPlayerAlly(attack.attacker) then
      lastAttacker = attack.attacker
      return
    end

    -- our summons or controlled creatures can disappear, 
    -- so we need to transfer credit to player before enemy dies
    log('player ally hit this actor, the credit will go to player')
    lastAttacker = findPlayer() -- player ally credit goes to player
  end
end)

return {
  engineHandlers = {
    onInit = checkAndCachePlayerSummon,
  },
  eventHandlers = {
    FDU_UpdateFollowerList = updateFollowerStatus,
    Died = function()
      local enemyName = getActorName(self.object)
      local enemyLevel = types.Actor.stats.level(self.object).current
      local payload = { level = enemyLevel, name = enemyName }
      log(string.format('"Died" event fired for %s', tostring(enemyName)))

      log('=== All Followers ===')
      local followersAll = playerFollowers:get('all')
      if followersAll then
        for id, isFollower in pairs(followersAll) do
          if isFollower then
            log('Follower ID: %s', tostring(id))
          end
        end
      end
      log('=== End Followers ===')

      if isThisActorPlayerSummon then
        core.sendGlobalEvent('UnregisterPlayerSummon', self.object)
        return
      end

      if isPlayerAlly(self.object) then
        -- we don't grant xp to enemies or player for killing player allies
        log('player ally died! we dont grant xp to anyone')
        return
      end

      if not lastAttacker then
        -- killer is unknown, maybe magic was used?
        for _, actor in ipairs(nearby.actors) do
          if types.Player.objectIsInstance(actor) then
            actor:sendEvent('GrantBattleExpConditionally', payload)
            break
          end
        end
        log('lastAttacker unknown!')
        return
      end
      if not lastAttacker.isValid then
        log('lastAttacker not valid!')
        return
      end
      log(string.format('lastAttacker: %s', tostring(getActorName(lastAttacker))))

      local isKillerPlayerOrAlly = types.Player.objectIsInstance(lastAttacker)
      log(string.format('isKillerPlayerOrAlly: %s', tostring(isKillerPlayerOrAlly)))
      if not isKillerPlayerOrAlly then
        log('Killer is not player or ally, skipping...')
        return
      end

      if isKillerPlayerOrAlly then
        lastAttacker:sendEvent('GrantBattleExp', payload)
      else
        for _, actor in ipairs(nearby.actors) do
          if types.Player.objectIsInstance(actor) then
            actor:sendEvent('GrantBattleExp', payload)
            break
          end
        end
      end
    end
  }
}
