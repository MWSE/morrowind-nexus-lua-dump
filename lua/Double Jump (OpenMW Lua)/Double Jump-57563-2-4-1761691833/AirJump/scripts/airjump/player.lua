-- Air Jump (PLAYER, OpenMW 0.49/0.50) – trigger-based hotkey
-- Unique trigger: "GZ_AirJump_Toggle"

local core    = require('openmw.core')
local input   = require('openmw.input')
local self    = require('openmw.self')
local types   = require('openmw.types')
local storage = require('openmw.storage')
local async   = require('openmw.async')
local I       = require('openmw.interfaces')

-- ========= Tunables =========
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

-- ========= Unique trigger id =========
local TRIGGER_KEY = 'GZ_AirJump_Toggle' -- MUST match menu.lua

-- ========= State =========
local pressEventQueued        = false

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

-- ========= Ensure our trigger exists in PLAYER context =========
local function ensureTriggerRegistered()
  pcall(function()
    if not (input.triggers and input.triggers[TRIGGER_KEY]) then
      input.registerTrigger {
        key         = TRIGGER_KEY,
        l10n        = 'AirJump',
        name        = 'AirJump_Hotkey_Name',
        description = 'AirJump_Hotkey_Description',
      }
    end
  end)
end

local handlerHooked = false
local function hookTrigger()
  if handlerHooked then return end
  -- When the trigger fires, just queue a press for the next onUpdate.
  input.registerTriggerHandler(TRIGGER_KEY, async:callback(function()
    pressEventQueued = true
  end))
  handlerHooked = true
end

-- ========= Helpers =========
local function isGrounded()
  return types.Actor.isOnGround(self) and not types.Actor.isSwimming(self)
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
  local bb   = self:getBoundingBox()
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
  padPhase, trackTimerS = 1, TRACK_BEFORE_CONTACT_S
  ignoreGroundResetS = math.max(ignoreGroundResetS, TRACK_BEFORE_CONTACT_S + 0.10)
  pendingConsume, primeReleaseFrames, pressHoldFrames, pressElapsedS, overrideActive = false, 0, 0, 0, false
end

local function endOverride()
  if overrideActive and I and I.Controls and I.Controls.overrideMovementControls then
    I.Controls.overrideMovementControls(false)
  end
  overrideActive = false
end

local function despawnPad()
  core.sendGlobalEvent('AJ_DespawnPad', {})
  padPhase, trackTimerS, pendingConsume, primeReleaseFrames, pressHoldFrames, pressElapsedS = 0, 0, false, 0, 0, 0
  endOverride()
end

-- ========= Settings (global + legacy player fallback) =========
local globalSettings = storage.globalSection('SettingsAirJump')
local playerSettings = storage.playerSection('SettingsAirJump')  -- legacy fallback if present

local function readExtraJumps()
  local v = globalSettings and globalSettings:get('ExtraJumps')
  if v == nil and playerSettings then v = playerSettings:get('ExtraJumps') end
  v = tonumber(v); if not v or v < 0 then v = 1 end      -- CHANGED: default to 1 to match global group
  return math.floor(v)
end

local function applyExtraJumps(n)
  n = tonumber(n) or 1; if n < 0 then n = 0 end; n = math.floor(n)
  chargesMax = n
  if (types.Actor.isOnGround(self) and padPhase == 0) or (chargesRemaining > chargesMax) then
    chargesRemaining = chargesMax
  end
end

local function refreshSettings() applyExtraJumps(readExtraJumps()) end

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
      ensureTriggerRegistered()
      hookTrigger()
      core.sendGlobalEvent('AJ_RequestExtraJumps', {})
      refreshSettings()
      local pos = self.position; prevPos = pos; chargesRemaining = chargesMax
    end,

    onLoad = function()
      -- Make sure the trigger is live after reloadlua AND reapply settings when loading a save
      ensureTriggerRegistered()
      hookTrigger()
      refreshSettings()                                  -- NEW: re-read persistent value
      core.sendGlobalEvent('AJ_RequestExtraJumps', {})   -- also ask global to broadcast (belt & suspenders)
    end,

    onUpdate = function(dt)
      if rearmLockS > 0 then rearmLockS = math.max(0, rearmLockS - dt) end
      if ignoreGroundResetS > 0 then ignoreGroundResetS = math.max(0, ignoreGroundResetS - dt) end
      if trackTimerS > 0 then
        sendPadUpdate(dt)
        trackTimerS = math.max(0, trackTimerS - dt)
        if trackTimerS == 0 and padPhase == 1 then
          despawnPad()
        end
      end

      if types.Actor.isSwimming(self) then
        airborneTicks, groundedStableS, rearmLockS, ignoreGroundResetS = 0, 0, 0, 0
        chargesRemaining = chargesMax; despawnPad()
        prevPos, pressEventQueued = self.position, false
        return
      end

      local grounded = types.Actor.isOnGround(self)
      if grounded then
        groundedStableS, airborneTicks = groundedStableS + dt, 0
        if padPhase == 1 then
          padPhase, trackTimerS = 2, 0
          core.sendGlobalEvent('AJ_FreezePad', {})
          -- prime a brief release to guarantee a clean jump press afterward
          pendingConsume, primeReleaseFrames, pressHoldFrames, pressElapsedS = true, PRIME_RELEASE_FRAMES, PRESS_HOLD_FRAMES, 0
          if I and I.Controls and I.Controls.overrideMovementControls then
            I.Controls.overrideMovementControls(true); overrideActive = true
          end
        end
        if padPhase == 2 then
          if primeReleaseFrames > 0 then
            self.controls.jump = false
            primeReleaseFrames = primeReleaseFrames - 1
          else
            self.controls.jump = true
            if pressHoldFrames > 0 then pressHoldFrames = pressHoldFrames - 1 end
            pressElapsedS = pressElapsedS + dt
            if pressElapsedS >= PRESS_TIMEOUT_S then
              -- timeout for safety
              pendingConsume = false
            end
          end
        end
        if padPhase == 0 and ignoreGroundResetS <= 0 and groundedStableS >= REAL_GROUND_RESET_S then
          chargesRemaining = chargesMax
        end
      else
        groundedStableS, airborneTicks = 0, airborneTicks + 1
        if padPhase == 2 and pendingConsume then
          pendingConsume = false
          if chargesRemaining > 0 then chargesRemaining = chargesRemaining - 1 end
          rearmLockS = REARM_LOCK_S
          despawnPad()
        end
      end

      -- Consume a queued press from the trigger
      local canSpawn = (chargesRemaining > 0) and (padPhase == 0) and (rearmLockS <= 0) and (airborneTicks >= 1)
      if canSpawn and pressEventQueued then
        pressEventQueued = false
        spawnPadNow(dt)
      else
        -- If we cannot spawn yet, keep (or clear) the press so we don't “stick”
        pressEventQueued = false
      end

      prevPos = self.position
    end,
  },

  eventHandlers = {
    AJ_ExtraJumpsChanged = function(data)
      if data and data.value ~= nil then applyExtraJumps(data.value) end
    end,
  },
}
