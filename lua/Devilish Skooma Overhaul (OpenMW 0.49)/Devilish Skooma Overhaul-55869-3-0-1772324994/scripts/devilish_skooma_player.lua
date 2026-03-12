-- scripts/devilish_skooma_player.lua
-- Local player: psychedelic shader + time slow + pipe animation/VFX on smoke + camera roll tilt.
-- NO ESP. Pipe smoke is triggered via global ItemUsage handler.

local self    = require('openmw.self')
local types   = require('openmw.types')
local core    = require('openmw.core')
local anim    = require('openmw.animation')
local pp      = require('openmw.postprocessing')
local ambient = require('openmw.ambient')
local camera  = require('openmw.camera')

local shader = pp.load('epo_detd_skooma')

-- =============================================================
-- UPDATE RATES
-- =============================================================
local HEAVY_HZ = 10.0
local HEAVY_DT = 1.0 / HEAVY_HZ

-- =============================================================
-- Timing + stages (GAME HOURS based; matches your MWScript pacing)
-- =============================================================
local STAGE1_H = 3.0
local STAGE2_H = 6.0
local STAGE3_H = 8.0

-- "wait 1 game hour to reach max of the current stage"
local STAGE_RAMP_H = 1.0

-- When all doses end, fade out over this many game hours
local FADE_OUT_H = 1.0

-- Pipe dose length in GAME HOURS (so waiting/resting advances it)
local PIPE_DOSE_H = 2.0

-- =============================================================
-- Pipe visuals
-- =============================================================
local PIPE_ANIM_ID  = 'skoomapipe'
local PIPE_VFX_NIF  = 'meshes/spipe_vfx.nif'
local PIPE_VFX_BONE = 'Shield Bone'
local PIPE_VFX_ID   = 'detdSkoomaPipeFx'
local PIPE_FX_REAL_SEC = 7.0

-- =============================================================
-- Shader uniforms
-- =============================================================
local UNIF = {
  'drugged_distortion_amount',
  'drugged_doublevision_amount',
  'drugged_fractals_size',
  'drugged_fractals_amount',
}

local BASE_F1, BASE_F2 = 3.33, 0.16
local BASE_F3, BASE_F4 = 0.66, 0.23

local STAGE_MULT = {
  [1] = 1.00,
  [2] = 1.50,
  [3] = 1.75,
}

local function doseMultiplier(doseCount)
  if doseCount <= 1 then return 1.00 end
  if doseCount == 2 then return 1.10 end
  if doseCount == 3 then return 1.20 end
  if doseCount == 4 then return 1.30 end
  return 1.35
end

local function slowMoCurve(d)
  if d <= 0.0 then return 1.0 end
  if d <= 3.33  then return 1.0  - d/3.33  * 0.15 end
  if d <= 4.995 then return 0.85 - (d-3.33)/1.665 * 0.15 end
  local v = 0.70 - (d-4.995)/0.8325 * 0.20
  if v < 0.50 then v = 0.50 end
  return v
end

-- =============================================================
-- Helpers
-- =============================================================
local function nowGameH()
  return core.getGameTime() / 3600.0
end

local function clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

local function smoothstep(t)
  t = clamp(t, 0.0, 1.0)
  return t * t * (3.0 - 2.0 * t)
end

-- =============================================================
-- Pipe FX (real-time duration)
-- =============================================================
local pipeFxActive = false
local pipeFxUntilReal = -1e9

local function startPipeFX(soundFile)
  pcall(function()
    anim.playBlended(self, PIPE_ANIM_ID, { priority = anim.PRIORITY.Scripted })
  end)
  pcall(function()
    anim.addVfx(self, PIPE_VFX_NIF, { boneName = PIPE_VFX_BONE, loop = true, vfxId = PIPE_VFX_ID })
  end)

  if soundFile and soundFile ~= '' then
    ambient.playSoundFile(soundFile, { volume = 1.0, pitch = 1.0, scale = true })
  end

  pipeFxActive = true
  pipeFxUntilReal = core.getRealTime() + PIPE_FX_REAL_SEC
end

local function updatePipeFX()
  if not pipeFxActive then return end
  if core.getRealTime() >= pipeFxUntilReal then
    pipeFxActive = false
    pcall(function() anim.removeVfx(self, PIPE_VFX_ID) end)
  end
end

-- =============================================================
-- Dose tracking
-- =============================================================
local pipeDoseExpiries = {}

local function addPipeDose()
  table.insert(pipeDoseExpiries, nowGameH() + PIPE_DOSE_H)
end

local function countActivePipeDoses()
  local h = nowGameH()
  for i = #pipeDoseExpiries, 1, -1 do
    if pipeDoseExpiries[i] <= h then
      table.remove(pipeDoseExpiries, i)
    end
  end
  return #pipeDoseExpiries
end

local function countActivePotionSkooma()
  local spells = types.Actor.activeSpells(self)
  local n = 0
  for _, s in pairs(spells) do
    local rid = s.id and s.id:lower() or nil
    if rid == 'potion_skooma_01' or s.name == 'Skooma' then
      n = n + 1
    end
  end
  return n
end

-- =============================================================
-- Stage progression model (slow rise; 1h to max per stage)
-- =============================================================
local sessionStartH = nil
local fadeStartH    = nil

local lastStage = 0
local stageEnteredH = nil

local function currentStage(elapsedH)
  if elapsedH >= STAGE2_H then return 3 end
  if elapsedH >= STAGE1_H then return 2 end
  return 1
end

local function computeStageState(gameH, anyDose)
  if anyDose then
    if not sessionStartH then
      sessionStartH = gameH
      stageEnteredH = gameH
      lastStage = 1
    end
    fadeStartH = nil

    local elapsed = gameH - sessionStartH
    if elapsed < 0 then elapsed = 0 end

    local st = currentStage(elapsed)
    if st ~= lastStage then
      lastStage = st
      stageEnteredH = gameH
    end

    local ramp = smoothstep((gameH - (stageEnteredH or gameH)) / STAGE_RAMP_H)
    return st, STAGE_MULT[st], ramp, true
  end

  if not sessionStartH then
    return 0, 0.0, 0.0, false
  end

  if not fadeStartH then fadeStartH = gameH end
  local k = 1.0 - clamp((gameH - fadeStartH) / FADE_OUT_H, 0.0, 1.0)

  if k <= 0.001 then
    sessionStartH = nil
    fadeStartH = nil
    lastStage = 0
    stageEnteredH = nil
    return 0, 0.0, 0.0, false
  end

  local st = (lastStage > 0) and lastStage or 1
  return st, STAGE_MULT[st], k, true
end

-- =============================================================
-- Shader cache
-- =============================================================
local shaderEnabled = false
local f = { 0, 0, 0, 0 }
local lastF = { nil, nil, nil, nil }

local function setShaderEnabled(on)
  if on == shaderEnabled then return end
  shaderEnabled = on
  if on then shader:enable() else shader:disable() end
end

local function pushShader()
  for i = 1, 4 do
    if f[i] ~= lastF[i] then
      lastF[i] = f[i]
      shader:setFloat(UNIF[i], f[i])
    end
  end
end

local function clearAll()
  setShaderEnabled(false)
  f[1], f[2], f[3], f[4] = 0, 0, 0, 0
  pushShader()
  core.sendGlobalEvent('skoomaSetTimeScale', 1.0)
end

-- =============================================================
-- Camera roll (frame-updated)
--  - Always slow (even stage 1)
--  - Slower the higher the distortion
--  - Much smaller amplitude overall
-- =============================================================
local rollPhase = 0.0
local rollStrength = 0.0
local cachedDistortion = 0.0

-- NEW tuning (gentle + slow):
-- stage3 peak should be around "old stage1 max" (but slower)
local ROLL_MAX_RAD    = 0.12   -- ~7° at full strength (gentle)
local PERIOD_MIN_SEC  = 12.0   -- slow even at low distortion
local PERIOD_MAX_SEC  = 28.0   -- very slow at high distortion

local function applyCameraTilt(dt)
  -- Normalize using a higher ceiling so early stages aren't basically zero,
  -- but still remain subtle.
  local norm = clamp(cachedDistortion / 5.0, 0.0, 1.0)

  -- Make early strength much smaller (gentle start), but still nonzero:
  -- Use a curved response and add a tiny baseline when any effect exists.
  local target = norm ^ 1.6
  if cachedDistortion > 0.05 then
    target = math.max(target, 0.06) -- tiny baseline tilt so you can actually see it
  end

  -- Smooth changes slowly (prevents twitch)
  rollStrength = rollStrength + (target - rollStrength) * 0.035

  -- Always slow; higher distortion -> slower (bigger period)
  local period = PERIOD_MIN_SEC + (PERIOD_MAX_SEC - PERIOD_MIN_SEC) * rollStrength
  local phaseSpeed = (2.0 * math.pi) / period
  rollPhase = rollPhase + dt * phaseSpeed

  local roll = math.sin(rollPhase) * (ROLL_MAX_RAD * rollStrength)
  camera.setRoll(roll)

  if rollStrength < 0.01 and cachedDistortion <= 0.01 then
    camera.setRoll(0.0)
  end
end

-- =============================================================
-- Event from global: pipe smoked
-- =============================================================
local function onPipeSmoked(data)
  startPipeFX(data and data.soundFile or nil)
  addPipeDose()
end

-- =============================================================
-- Engine update loop
-- =============================================================
local acc = 0.0

return {
  eventHandlers = {
    DETD_SkoomaPipeSmoked = onPipeSmoked
  },

  engineHandlers = {
    onUpdate = function(dt)
      -- Pipe FX timer/cleanup
      updatePipeFX()

      -- Heavy logic at ~10 Hz
      acc = acc + dt
      if acc >= HEAVY_DT then
        acc = acc - HEAVY_DT

        local pipeCount   = countActivePipeDoses()
        local potionCount = countActivePotionSkooma()
        local totalDoses  = pipeCount + potionCount
        local anyDose     = (totalDoses > 0)

        local gameH = nowGameH()
        local stage, stageMult, stageRamp, active = computeStageState(gameH, anyDose)

        if not active then
          clearAll()
          cachedDistortion = 0.0
          rollStrength = 0.0
          camera.setRoll(0.0)
        else
          setShaderEnabled(true)

          local dMult = doseMultiplier(totalDoses)

          local tgt1 = BASE_F1 * stageMult * dMult
          local tgt2 = BASE_F2 * stageMult * dMult
          local tgt3 = BASE_F3 * stageMult * dMult
          local tgt4 = BASE_F4 * stageMult * dMult

          f[1] = stageRamp * tgt1
          f[2] = stageRamp * tgt2
          f[3] = stageRamp * tgt3
          f[4] = stageRamp * tgt4

          pushShader()
          core.sendGlobalEvent('skoomaSetTimeScale', slowMoCurve(f[1]))

          cachedDistortion = f[1]
        end
      end

      -- Camera sway each frame (after cachedDistortion potentially updated)
      applyCameraTilt(dt)
    end
  }
}