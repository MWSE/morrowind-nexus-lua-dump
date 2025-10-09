-- AirJump (PLAYER) – mid-air pad + buffered jump with strict one-shot trigger.
-- OpenMW 0.49 API.

local core   = require('openmw.core')
local self   = require('openmw.self')
local types  = require('openmw.types')
local input  = require('openmw.input')

-- === Tunables (mesh is 45×45×10 at scale=1) =================================
local ACTION_KEY                   = 'AirJump' -- bind this in Controls → Custom
local FEET_OVERLAP                 = 0.03      -- pad intrudes into feet (world units)
local PAD_SCALE                    = 1.0       -- no runtime scaling
local PAD_LIFE_MS                  = 300       -- fallback lifetime if we never ground
local MIN_AIRBORNE_TICKS           = 2         -- ignore immediate take-off frames
local PAD_HALF_THICK_AT_SCALE1     = 5.0       -- half of pad thickness (10/2)

-- Timing windows
local TRACK_PAD_FRAMES_MAX         = 16        -- follow feet for a shorter window
local JUMP_BUFFER_BEFORE_FRAMES    = 16        -- hold Jump BEFORE first contact
local JUMP_HOLD_AFTER_FRAMES       = 8         -- hold Jump only on the FIRST grounded frames

-- === Input registration ======================================================
-- MENU already registers this so it shows in Controls. We still try here to be robust
-- after in-game script reloads. Wrap in pcall to avoid "already in use" error.
pcall(function()
  input.registerAction{
    key          = ACTION_KEY,
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'AirJump',
    name         = 'Air Jump',
    description  = 'Perform a mid-air jump by dropping a brief invisible pad.',
    defaultValue = false,
  }
end)

-- === State machine ===========================================================
local S_IDLE, S_ARMED, S_TRIGGERED, S_COOLDOWN = 0, 1, 2, 3
local state             = S_IDLE

local prevDown          = false
local airborneTicks     = 0
local usedThisAir       = false

local trackFramesLeft   = 0     -- while ARMED: keep pad under feet
local bufBefore         = 0     -- Jump buffer before contact (only active in ARMED)
local holdAfter         = 0     -- Jump hold after first contact (only active in TRIGGERED)

-- === Helpers ================================================================
local function isGrounded()  return types.Actor.isOnGround(self)  end
local function isSwimming()  return types.Actor.isSwimming(self)  end

-- Player feet (world AABB bottom)
local function feetBottomZ()
  local bb = self:getBoundingBox()
  return bb.center.z - bb.halfSize.z
end

-- Pad center so its TOP = feet + overlap
local function padCenterZ()
  local top = feetBottomZ() + FEET_OVERLAP
  return top - (PAD_HALF_THICK_AT_SCALE1 * PAD_SCALE)
end

local function spawnPad()
  local pos = self.position
  core.sendGlobalEvent('AJ_SpawnPad', {
    x = pos.x, y = pos.y, z = padCenterZ(),
    scale  = PAD_SCALE,
    lifeMs = PAD_LIFE_MS,
  })
end

local function trackPad()
  local pos = self.position
  core.sendGlobalEvent('AJ_UpdatePadCenter', {
    x = pos.x, y = pos.y, z = padCenterZ(),
  })
end

local function clearPad()
  core.sendGlobalEvent('AJ_ClearPad')
end

-- === Main loop ==============================================================
return {
  engineHandlers = {
    onFrame = function(dt)
      -- sample input (rising edge)
      local down        = input.getBooleanActionValue(ACTION_KEY) or false
      local justPressed = down and not prevDown
      prevDown = down

      -- hard reset when swimming
      if isSwimming() then
        state = S_IDLE
        usedThisAir, trackFramesLeft, bufBefore, holdAfter = false, 0, 0, 0
        return
      end

      -- natural grounded handling
      if isGrounded() then
        airborneTicks = 0
        if state == S_COOLDOWN then
          state = S_IDLE
          usedThisAir = false
        end
      else
        airborneTicks = airborneTicks + 1
      end

      -- === STATE: ARMED =====================================================
      if state == S_ARMED then
        -- Keep pad following the feet while waiting for the first contact
        trackPad()

        -- Buffer Jump only in ARMED
        if bufBefore > 0 then
          self.controls.jump = true
          bufBefore = bufBefore - 1
        end

        if isGrounded() then
          -- FIRST contact → immediately clear pad and begin short hold
          clearPad()
          state     = S_TRIGGERED
          holdAfter = JUMP_HOLD_AFTER_FRAMES
        else
          trackFramesLeft = trackFramesLeft - 1
          if trackFramesLeft <= 0 then
            -- timeout without contact: stop tracking; pad auto-despawns via lifetime
            state, bufBefore = S_COOLDOWN, 0
          end
        end

      -- === STATE: TRIGGERED ================================================
      elseif state == S_TRIGGERED then
        -- Only hold Jump WHILE grounded in this state
        if isGrounded() and holdAfter > 0 then
          self.controls.jump = true
          holdAfter = holdAfter - 1
        end
        -- As soon as we leave ground (the jump fired), stop holding and go to cooldown
        if not isGrounded() then
          holdAfter = 0
          state     = S_COOLDOWN
        end
      end

      -- === ARM from airborne =================================================
      if state == S_IDLE and (not isGrounded()) and airborneTicks >= MIN_AIRBORNE_TICKS
         and not usedThisAir and justPressed then
        spawnPad()
        state           = S_ARMED
        usedThisAir     = true
        trackFramesLeft = TRACK_PAD_FRAMES_MAX
        bufBefore       = JUMP_BUFFER_BEFORE_FRAMES
      end
    end,
  },
}
