local core = require('openmw.core')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local async = require('openmw.async')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local Events = require('scripts.AttendMe.events')

I.Settings.registerPage({
   key = 'AttendMe',
   l10n = 'AttendMe',
   name = 'page_name',
   description = 'page_description',
})

local followers = {}
local followersToTeleport = {}

local function cleanFollowers()
   local index = 1
   while index <= #followers do
      local follower = followers[index]
      if follower:isValid() and follower.count > 0 then
         index = index + 1
      else
         table.remove(followers, index)
      end
   end
end

local hud = require('scripts.AttendMe.hud')(followers)

local hudSettings = storage.playerSection('SettingsAttendMeHUD')

local function isFollower(actor)
   for _, follower in ipairs(followers) do
      if follower == actor then
         return true
      end
   end
   return false
end

local function filterfollowersToTeleport()
   local filtered = {}
   for _, actor in ipairs(followersToTeleport) do
      if isFollower(actor) then
         table.insert(filtered, actor)
      end
   end
   followersToTeleport = filtered
end

local function shuffle(t)
   for i = #t, 2, -1 do
      local j = math.random(i)
      t[i], t[j] = t[j], t[i]
   end
end

local maxTeleportDistance = 200
local teleportPadding = 60

local unit = util.vector3(1, 0, 0)
local verticalAxis = util.vector3(0, 0, 1)

local waistOffset = verticalAxis * teleportPadding

local function findTarget(playerPosition, direction)
   local targetPosition = playerPosition + direction * maxTeleportDistance

   local navmeshPosition = nearby.castNavigationRay(playerPosition, targetPosition, {
      includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.UsePathgrid,
   })
   if not navmeshPosition then return end

   local physicsPosition = nearby.castRay(

   playerPosition + waistOffset,
   navmeshPosition + waistOffset,
   { ignore = self.object }).
   hitPos
   if not physicsPosition then return navmeshPosition end

   local physicsDirection, physicsDistance = (physicsPosition - playerPosition):normalize()
   if physicsDistance < teleportPadding then
      return nil
   end

   local offsetDirection = physicsDirection * (physicsDistance - teleportPadding)
   return playerPosition + offsetDirection
end

local function teleportFollowers()
   filterfollowersToTeleport()
   if #followersToTeleport == 0 then return end
   local playerPosition = self.object.position
   local foundTargets = {}


   local searchFactor = 2
   while searchFactor <= 32 do
      for offset = 1, searchFactor do
         if offset % 2 == 1 or searchFactor == 2 then
            local angle = offset * math.pi / searchFactor
            local rotatedUnit = util.transform.rotate(angle, verticalAxis) * unit
            local target = findTarget(playerPosition, rotatedUnit)
            if target then
               table.insert(foundTargets, target)
               if #foundTargets >= #followersToTeleport then break end
            end
         end
      end
      if #foundTargets >= #followersToTeleport then break end
      searchFactor = searchFactor * 2
   end

   shuffle(followersToTeleport)
   for i, follower in ipairs(followersToTeleport) do
      local target = foundTargets[i] or self.object.position
      core.sendGlobalEvent('AttendMeTeleport', {
         actor = follower,
         cellName = self.object.cell.name,
         position = target,
      })
   end

   followersToTeleport = {}
end

local followerAwayCallback = async:registerTimerCallback('AttendMe_followerAway', function(actor)
   table.insert(followersToTeleport, actor)
end)

local frameCounter = math.floor(math.random() * math.max(1, hudSettings:get('updateEvery')))

return {
   eventHandlers = {
      AttendMeFollowerStatus = function(e)
         local index
         for i, follower in ipairs(followers) do
            if follower == e.actor then
               index = i
               break
            end
         end
         if e.status and not index then
            table.insert(followers, e.actor)
         end
         if not e.status and index then
            table.remove(followers, index)
         end
         hud.updateFollowerList()
      end,
      AttendMeFollowerAway = function(e)
         async:newSimulationTimer(0.1, followerAwayCallback, e.actor)
      end,
   },
   engineHandlers = {
      onUpdate = function()
         cleanFollowers()

         if frameCounter == 0 then
            hud.updateFollowerList()
         end
         frameCounter = frameCounter + 1
         if frameCounter >= math.max(1, hudSettings:get('updateEvery')) then
            frameCounter = 0
         end

         teleportFollowers()
      end,
   },
}
