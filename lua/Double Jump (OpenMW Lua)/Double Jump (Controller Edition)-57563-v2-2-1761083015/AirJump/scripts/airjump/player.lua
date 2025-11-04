-- Air Jump (PLAYER, OpenMW 0.49) – controller build (listens to built-in Jump)

local core    = require('openmw.core')
local input   = require('openmw.input')
local self    = require('openmw.self')
local types   = require('openmw.types')
local storage = require('openmw.storage')
local async   = require('openmw.async')
local I       = require('openmw.interfaces')

-- ========= Tunables (contact smoothing) =========
local PAD_HALF_THICK          = 6
local FEET_OVERLAP            = 0.0
local REAL_GROUND_RESET_S     = 0.12
local TRACK_BEFORE_CONTACT_S  = 1.20
local REARM_LOCK_S            = 0.20

local PRIME_RELEASE_FRAMES    = 1
local PRESS_HOLD_FRAMES       = 16
local PRESS_TIMEOUT_S         = 1.0

local BACK_LEAD_S             = 0.04
local TRAIL_RADIUS_FRACTION   = 0.30
local SPEED_HIGH              = 300.0
local MAX_XY_STEP             = 200.0

-- ========= State =========
local prevJumpDown            = false
local airborneTicks           = 0
local groundedStableS         = 0

local chargesMax              = 1
local chargesRemaining        = 1

local padPhase                = 0
local trackTimerS             = 0
local ignoreGroundResetS      = 0
local pendingConsume          = false
local rearmLockS              = 0

local primeReleaseFrames      = 0
local pressHoldFrames         = 0
local pressElapsedS           = 0
local overrideActive          = false

local prevPos                 = nil

-- ========= Helpers =========
local function isGrounded()
  return types.Actor.isOnGround(self) and not types.Actor.isSwimming(self)
end

local function readJumpPressed()
  local ok, val = pcall(input.getBooleanActionValue, 'Jump')
  if ok then return val == true end
  local ok2, val2 = pcall(function() return input.isActionPressed(input.ACTION.Jump) end)
  return ok2 and (val2 == true) or false
end

local function feetBottomZ()
  local bb = self:getBoundingBox()
  return bb.center.z - bb.halfSize.z
end

local function clampStep(cur, target, maxStep)
  local d = target - cur
  if d >  maxStep then return cur + maxStep end
  if d < -maxStep then return cur - maxStep end
  return target
end

local function targetFeetAndXY(dt)
  local pos = self.position
  local fz  = feetBottomZ()

  local vx, vy = 0, 0
  if prevPos and dt and dt > 0 then
    vx = (pos.x - prevPos.x) / dt
    vy = (pos.y - prevPos.y) / dt
  end
  local hspd = math.sqrt(vx*vx + vy*vy)

  local bb = self:getBoundingBox()
  local radius = bb.halfSize.x

  local px, py = pos.x, pos.y
  if hspd < SPEED_HIGH then
    if hspd > 0.001 then
      local trail = math.min(hspd * BACK_LEAD_S, radius * TRAIL_RADIUS_FRACTION)
      local inv   = 1.0 / hspd
      px = px - vx * inv * trail
      py = py - vy * inv * trail
    end
  else
    px, py = pos.x, pos.y
  end

  px = clampStep(pos.x, px, MAX_XY_STEP)
  py = clampStep(pos.y, py, MAX_XY_STEP)

  return fz, px, py
end

local function padCenterFromFeet(feetZ)
  local topZ = (feetZ or feetBottomZ()) + FEET_OVERLAP
  return topZ - PAD_HALF_THICK
end

local function sendPadUpdate(dt)
  if padPhase ~= 1 then return end
  local feetZ, px, py = targetFeetAndXY(dt)
  core.sendGlobalEvent('AJ_UpdatePadCenter', { x = px, y = py, z = padCenterFromFeet(feetZ) })
end

local function spawnPadNow(dt)
  local feetZ, px, py = targetFeetAndXY(dt)
  core.sendGlobalEvent('AJ_SpawnPad', { x = px, y = py, z = padCenterFromFeet(feetZ) })
  padPhase           = 1
  trackTimerS        = TRACK_BEFORE_CONTACT_S
  ignoreGroundResetS = math.max(ignoreGroundResetS, TRACK_BEFORE_CONTACT_S + 0.10)
  pendingConsume     = false
  primeReleaseFrames = 0
  pressHoldFrames    = 0
  pressElapsedS      = 0
  overrideActive     = false
end

local function endOverride()
  if overrideActive and I and I.Controls and I.Controls.overrideMovementControls then
    I.Controls.overrideMovementControls(false)
  end
  overrideActive = false
end

local function despawnPad()
  core.sendGlobalEvent('AJ_DespawnPad', {})
  padPhase           = 0
  trackTimerS        = 0
  pendingConsume     = false
  primeReleaseFrames = 0
  pressHoldFrames    = 0
  pressElapsedS      = 0
  endOverride()
end

-- ========= Settings (GLOBAL persistent + legacy player fallback) =========
local globalSettings = storage.globalSection('SettingsAirJump')
local playerSettings = storage.playerSection('SettingsAirJump')

local function readExtraJumps()
  local v = globalSettings and globalSettings:get('ExtraJumps')
  if v == nil and playerSettings then v = playerSettings:get('ExtraJumps') end
  v = tonumber(v)
  if not v or v < 0 then v = 0 end
  return math.floor(v)
end

local function applyExtraJumps(n)
  n = tonumber(n) or 0
  if n < 0 then n = 0 end
  n = math.floor(n)
  chargesMax = n
  -- If we're safely on ground and not using a pad, refill now so the change is visible immediately
  if airborneTicks == 0 and padPhase == 0 then
    chargesRemaining = chargesMax
  else
    -- Otherwise just clamp current remaining so we never exceed the new cap
    if chargesRemaining > chargesMax then chargesRemaining = chargesMax end
  end
end

local function refreshSettings()
  applyExtraJumps(readExtraJumps())
end

-- Live updates on storage changes (best effort; also handled via event below)
if globalSettings then
  globalSettings:subscribe(async:callback(function(_, key)
    if (not key) or key == 'ExtraJumps' then refreshSettings() end
  end))
end
if playerSettings then
  playerSettings:subscribe(async:callback(function(_, key)
    if (not key) or key == 'ExtraJumps' then refreshSettings() end
  end))
end

-- ========= Engine + events =========
return {
  engineHandlers = {
    onInit = function()
      -- Ask GLOBAL to broadcast current setting (covers fresh installs & ensures we sync even if storage subscribe misses)
      core.sendGlobalEvent('AJ_RequestExtraJumps', {})
      refreshSettings()
      prevPos          = self.position
      chargesRemaining = chargesMax
    end,

    onUpdate = function(dt)
      if rearmLockS > 0         then rearmLockS         = math.max(0, rearmLockS - dt)         end
      if ignoreGroundResetS > 0 then ignoreGroundResetS = math.max(0, ignoreGroundResetS - dt) end

      if trackTimerS > 0 then
        sendPadUpdate(dt)
        trackTimerS = math.max(0, trackTimerS - dt)
        if trackTimerS == 0 and padPhase == 1 then
          despawnPad()
        end
      end

      if types.Actor.isSwimming(self) then
        airborneTicks      = 0
        groundedStableS    = 0
        rearmLockS         = 0
        chargesRemaining   = chargesMax
        ignoreGroundResetS = 0
        despawnPad()
        prevPos            = self.position
        prevJumpDown       = false
        return
      end

      local grounded = isGrounded()
      if grounded then
        groundedStableS = groundedStableS + dt
        airborneTicks   = 0

        if padPhase == 1 then
          padPhase           = 2
          trackTimerS        = 0
          core.sendGlobalEvent('AJ_FreezePad', {})
          pendingConsume     = true
          primeReleaseFrames = PRIME_RELEASE_FRAMES
          pressHoldFrames    = PRESS_HOLD_FRAMES
          pressElapsedS      = 0
          if I and I.Controls and I.Controls.overrideMovementControls then
            I.Controls.overrideMovementControls(true)
            overrideActive = true
          end
        end

        if padPhase == 2 then
          if primeReleaseFrames > 0 then
            self.controls.jump = false
            primeReleaseFrames = primeReleaseFrames - 1
          else
            self.controls.jump = true
            if pressHoldFrames > 0 then
              pressHoldFrames = pressHoldFrames - 1
            end
            pressElapsedS = pressElapsedS + dt
          end
        end

        if padPhase == 0 and ignoreGroundResetS <= 0 and groundedStableS >= REAL_GROUND_RESET_S then
          chargesRemaining = chargesMax
        end
      else
        groundedStableS = 0
        airborneTicks   = airborneTicks + 1

        if padPhase == 2 and pendingConsume then
          pendingConsume = false
          if chargesRemaining > 0 then
            chargesRemaining = chargesRemaining - 1
          end
          rearmLockS = REARM_LOCK_S
          despawnPad()
        end
      end

      -- Edge-trigger on built-in Jump while airborne to spawn pad
      local jumpDown = readJumpPressed()
      if (not prevJumpDown) and jumpDown and padPhase == 0 and airborneTicks > 0 and rearmLockS <= 0 then
        if chargesRemaining > 0 then
          spawnPadNow(dt)
        end
      end
      prevJumpDown = jumpDown

      prevPos = self.position
    end,
  },

  -- NEW: react to global broadcast so settings changes apply immediately
  eventHandlers = {
    AJ_ExtraJumpsChanged = function(data)
      if data and data.value ~= nil then
        applyExtraJumps(data.value)
      end
    end,
  },
}
