local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local Events = require('scripts.AttendMe.events')

local mechanicSettings = storage.globalSection('SettingsAttendMeMechanics')

local followingPlayers = {}

local function filter(t, callback)
   local result = {}
   for k, v in pairs(t) do
      if callback(k, v) then
         result[k] = v
      end
   end
   return result
end

local function map(t, callback)
   local result = {}
   for k, v in pairs(t) do
      local newK, newV = callback(k, v)
      result[newK] = newV
   end
   return result
end

local function notifyPlayer(player, status)
   local data = {
      actor = self.object,
      status = status,
   }
   player:sendEvent('AttendMeFollowerStatus', data)
end

local function isDead()
   local health = (self.object.type).stats.dynamic.health(self)
   return health.current == 0
end

local function updateFollowedPlayers()
   local playerTargets = map(
   filter(I.AI.getTargets('Follow'), function(_, target)
      return target and target.type == types.Player and target:isValid()
   end),
   function(_, target)
      return tostring(target), target
   end)

   local newPlayers = filter(playerTargets, function(k)
      return not followingPlayers[k]
   end)
   local removedPlayers = filter(followingPlayers, function(k)
      return not playerTargets[k]
   end)
   for _, player in pairs(removedPlayers) do
      followingPlayers[tostring(player)] = nil
      notifyPlayer(player, false)
   end
   for _, player in pairs(newPlayers) do
      followingPlayers[tostring(player)] = player
      notifyPlayer(player, true)
   end
end

local updateTime = math.random() * math.max(0, mechanicSettings:get('checkFollowersEvery'))

return {
   engineHandlers = {
      onInactive = function()
         if not isDead() and mechanicSettings:get('teleportFollowers') then
            for _, player in pairs(followingPlayers) do
               player:sendEvent('AttendMeFollowerAway', {
                  actor = self.object,
               })
            end
         end
      end,
      onUpdate = function(dt)
         updateTime = updateTime + dt
         local checkEvery = math.max(0, mechanicSettings:get('checkFollowersEvery'))
         if updateTime < checkEvery then return end
         if checkEvery == 0 then
            updateTime = 0
         else
            while updateTime > checkEvery do
               updateTime = updateTime - checkEvery
            end
         end

         if isDead() then
            for _, player in pairs(followingPlayers) do
               notifyPlayer(player, false)
            end
            followingPlayers = {}
         else
            updateFollowedPlayers()
         end
      end,
   },
}
