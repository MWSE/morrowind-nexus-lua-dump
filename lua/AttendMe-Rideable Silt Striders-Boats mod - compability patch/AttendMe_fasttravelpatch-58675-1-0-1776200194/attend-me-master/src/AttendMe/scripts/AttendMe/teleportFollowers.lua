local core = require('openmw.core')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local async = require('openmw.async')

-- ============================================================
-- Tuning constants — adjust these to taste
-- ============================================================

local maxTeleportDistance = 200
local teleportPadding     = 60

-- Water detection ————————————————————————————————————————————
local waterCheckRadius = 100
local waterProbeHeight = 50
local waterProbeDepth  = 1500
local waterProbeCount = 2
local waterCacheDuration = 5.0
local waterRetryInterval = waterCacheDuration + 0.1

-- ============================================================
-- Internal state
-- ============================================================

local unit         = util.vector3(1, 0, 0)
local verticalAxis = util.vector3(0, 0, 1)
local waistOffset  = verticalAxis * teleportPadding

local followersToTeleport = {}

local cachedWaterResult = false
local cacheExpiryTime   = -1

-- ============================================================
-- Cell classification
-- ============================================================

local function getCellName()
   local cell = self.object.cell
   if not cell then return '' end
   return string.lower((cell.name or cell.displayName or ''))
end

-- Heuristic: allow dungeon-like interiors, block normal buildings/houses.
-- This is intentionally conservative: if a cell name does not look like a cave/dungeon,
-- teleport stays blocked in interiors.
local function isDungeonLikeInterior()
   local cell = self.object.cell
   if not cell then return false end
   if cell.isExterior then return true end

   local name = getCellName()

   local allowPatterns = {
      'cave',
      'cavern',
      'mine',
      'tomb',
      'crypt',
      'catacomb',
      'ruin',
      'dwemer',
      'sewer',
      'barrow',
      'burial',
      'ash%e?pit',
      'lair',
      'sacellum',
      'crypts?',
      'depot',
      'velothi',   -- some dungeon-like interiors use this style
      'tribunal',  -- harmless if unused; kept for broader dungeon naming
      'shrine',
      
   }

   for _, pattern in ipairs(allowPatterns) do
      if name:find(pattern) then
         return true
      end
   end

   return false
end

-- ============================================================
-- Water detection
-- ============================================================

local function probeWaterAt(x, y)
   local pos  = self.object.position
   local from = util.vector3(x, y, pos.z + waterProbeHeight)
   local to   = util.vector3(x, y, pos.z - waterProbeDepth)

   local waterHit = nearby.castRay(from, to, {
      ignore        = self.object,
      collisionType = nearby.COLLISION_TYPE.Water,
   })
   if not waterHit.hit then return false end

   local solidHit = nearby.castRay(from, to, {
      ignore        = self.object,
      collisionType = nearby.COLLISION_TYPE.Default,
   })
   if solidHit.hit and solidHit.hitPos.z > waterHit.hitPos.z then
      return false
   end

   return true
end

local function isWaterNearby()
   local now = core.getSimulationTime()
   if now < cacheExpiryTime then
      return cachedWaterResult
   end

   local cell = self.object.cell
   if cell and not cell.hasWater then
      cachedWaterResult = false
      cacheExpiryTime   = now + waterCacheDuration
      return false
   end

   local pos    = self.object.position
   local result = false

   if probeWaterAt(pos.x, pos.y) then
      result = true
   else
      for i = 0, waterProbeCount - 1 do
         local angle = i * (2 * math.pi / waterProbeCount)
         if probeWaterAt(
               pos.x + math.cos(angle) * waterCheckRadius,
               pos.y + math.sin(angle) * waterCheckRadius) then
            result = true
            break
         end
      end
   end

   cachedWaterResult = result
   cacheExpiryTime   = now + waterCacheDuration
   return result
end

-- ============================================================
-- Target finding
-- ============================================================

local function findTarget(playerPosition, direction)
   local targetPosition = playerPosition + direction * maxTeleportDistance

   local navmeshPosition = nearby.castNavigationRay(playerPosition, targetPosition, {
      includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.UsePathgrid,
   })
   if not navmeshPosition then return end

   local physicsPosition = nearby.castRay(
      playerPosition + waistOffset,
      navmeshPosition + waistOffset,
      { ignore = self.object }).hitPos

   if not physicsPosition then return navmeshPosition end

   local physicsDirection, physicsDistance =
      (physicsPosition - playerPosition):normalize()
   if physicsDistance < teleportPadding then return nil end

   return playerPosition + physicsDirection * (physicsDistance - teleportPadding)
end

-- ============================================================
-- Helpers
-- ============================================================

local function isFollower(actor, followers)
   for _, follower in ipairs(followers) do
      if follower == actor then return true end
   end
   return false
end

local function filterfollowersToTeleport(followers)
   local filtered = {}
   for _, actor in ipairs(followersToTeleport) do
      if isFollower(actor, followers) then
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

-- ============================================================
-- Teleport logic
-- ============================================================

local doTeleport

local retryCallback = async:registerTimerCallback(
   'AttendMe_waterRetry',
   function(followers)
      filterfollowersToTeleport(followers)
      if #followersToTeleport == 0 then return end
      doTeleport(followers)
   end
)

doTeleport = function(followers)
   -- Block teleport in ordinary interior buildings/houses,
   -- but allow dungeon-like interiors (caves, ruins, mines, tombs, etc.).
   if self.object.cell and not self.object.cell.isExterior and not isDungeonLikeInterior() then
      return
   end

   if isWaterNearby() then
      async:newSimulationTimer(waterRetryInterval, retryCallback, followers)
      return
   end

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
      core.sendGlobalEvent('AttendMeTeleport', {
         actor    = follower,
         cellName = self.object.cell.name,
         position = foundTargets[i] or self.object.position,
      })
   end

   followersToTeleport = {}
end

-- ============================================================
-- Public interface
-- ============================================================

local function update(followers)
   filterfollowersToTeleport(followers)
   if #followersToTeleport == 0 then return end
   doTeleport(followers)
end

local followerAwayCallback = async:registerTimerCallback(
   'AttendMe_followerAway',
   function(actor)
      table.insert(followersToTeleport, actor)
   end
)

local function followerAway(actor)
   async:newSimulationTimer(0.1, followerAwayCallback, actor)
end

return {
   update = update,
   followerAway = followerAway,
}