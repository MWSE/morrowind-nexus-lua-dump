-- scripts/devilish_skooma_player.lua
-- Local player: psychedelic shader + stronger time distortion + pipe animation/VFX + camera roll + separate vignette shader.
-- Behavior:
--   * Effect state is persistent and does NOT depend on active dose count to remain alive
--   * New dose preserves current live distortion exactly
--   * New dose raises the peak and climbs to it over 6 in-game hours
--   * Then fades out over the next 6 in-game hours
--   * Vignette is controlled by a separate shader
--   * Vignette rises with the current skooma visual ratio
--   * Vignette now fades back down naturally with distortion during the comedown
--   * Vignette resets fully when the effect ends

local self    = require('openmw.self')
local types   = require('openmw.types')
local core    = require('openmw.core')
local anim    = require('openmw.animation')
local pp      = require('openmw.postprocessing')
local ambient = require('openmw.ambient')
local camera  = require('openmw.camera')

local skoomaShader   = pp.load('epo_detd_skooma')
local vignetteShader = pp.load('epo_detd_vignette')

-- =============================================================
-- UPDATE RATES
-- =============================================================
local HEAVY_HZ = 10.0
local HEAVY_DT = 1.0 / HEAVY_HZ

-- =============================================================
-- TIMING (in-game hours)
-- =============================================================
local RISE_H = 6.0
local FALL_H = 6.0
local TOTAL_H = RISE_H + FALL_H

-- =============================================================
-- PIPE VISUALS
-- =============================================================
local PIPE_ANIM_ID     = 'skoomapipe'
local PIPE_VFX_NIF     = 'meshes/spipe_vfx.nif'
local PIPE_VFX_BONE    = 'Shield Bone'
local PIPE_VFX_ID      = 'detdSkoomaPipeFx'
local PIPE_FX_REAL_SEC = 7.0

-- =============================================================
-- SHADER UNIFORMS
-- =============================================================
local SKOOMA_UNIF = {
  distortion    = 'drugged_distortion_amount',
  doublevision  = 'drugged_doublevision_amount',
  fractalSize   = 'drugged_fractals_size',
  fractalAmount = 'drugged_fractals_amount',
}

local VIGNETTE_UNIF = {
  amount    = 'drugged_vignette_amount',
  midpoint  = 'drugged_vignette_midpoint',
  roundness = 'drugged_vignette_roundness',
  feather   = 'drugged_vignette_feather',
}

-- =============================================================
-- BASE VISUAL CURVE
-- =============================================================
local BASE_F1, BASE_F2 = 3.33, 0.16
local BASE_F3, BASE_F4 = 0.66, 0.23

-- =============================================================
-- VIGNETTE TUNING
-- =============================================================
local VIGNETTE_MAX_AMOUNT = 0.929
local VIGNETTE_BASE_MID   = 1.0
local VIGNETTE_MIN_MID    = 0.344

local VIGNETTE_BASE_ROUND   = 0.55
local VIGNETTE_PEAK_ROUND   = 0.82
local VIGNETTE_BASE_FEATHER = 0.42
local VIGNETTE_PEAK_FEATHER = 0.74

-- 1.0 = original level-1 peak distortion
local VIGNETTE_FULL_AT_RATIO = 1.0

local function clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function smoothstep(t)
  t = clamp(t, 0.0, 1.0)
  return t * t * (3.0 - 2.0 * t)
end

local function nowGameH()
  return core.getGameTime() / 3600.0
end

-- =============================================================
-- PEAK CURVE
-- =============================================================
local function peakMultiplierForLevel(level)
  if level <= 1 then return 1.00 end
  if level == 2 then return 1.45 end
  if level == 3 then return 1.95 end
  if level == 4 then return 2.45 end
  if level == 5 then return 2.95 end
  return 2.95 + (level - 5) * 0.35
end

local function peakDistortionForLevel(level)
  return BASE_F1 * peakMultiplierForLevel(level)
end

local function timeScaleForDistortion(dist)
  if dist <= 0.0 then
    return 1.0
  end

  local n = dist / BASE_F1

  if n <= 1.0 then
    return 1.0 - 0.45 * n
  elseif n <= 2.0 then
    return 0.55 - 0.20 * (n - 1.0)
  elseif n <= 3.0 then
    return 0.35 - 0.10 * (n - 2.0)
  else
    local v = 0.25 - 0.03 * (n - 3.0)
    if v < 0.12 then v = 0.12 end
    return v
  end
end

-- =============================================================
-- PIPE FX
-- =============================================================
local pipeFxActive = false
local pipeFxUntilReal = -1e9

local function startPipeFX(soundFile)
  pcall(function()
    anim.playBlended(self, PIPE_ANIM_ID, { priority = anim.PRIORITY.Scripted })
  end)

  pcall(function()
    anim.addVfx(self, PIPE_VFX_NIF, {
      boneName = PIPE_VFX_BONE,
      loop = true,
      vfxId = PIPE_VFX_ID
    })
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
-- PERSISTENT EFFECT STATE
-- =============================================================
local effect = {
  level = 0,
  active = false,
  startH = 0.0,
  startDist = 0.0,
  peakDist = 0.0,
}

local function resetEffect(reason)
  if effect.active or effect.level > 0 then
   -- print(string.format(
    --  'debugmsg [skooma] resetEffect reason=%s level=%d',
   --   tostring(reason or 'unknown'),
   --   effect.level
   -- ))
  end

  effect.level = 0
  effect.active = false
  effect.startH = 0.0
  effect.startDist = 0.0
  effect.peakDist = 0.0
end

local function currentDistortionAt(gameH)
  if not effect.active or effect.level <= 0 then
    return 0.0, false, 0.0
  end

  local elapsed = gameH - effect.startH
  if elapsed < 0.0 then elapsed = 0.0 end

  if elapsed >= TOTAL_H then
    return 0.0, false, TOTAL_H
  end

  if elapsed <= RISE_H then
    local t = smoothstep(elapsed / RISE_H)
    return lerp(effect.startDist, effect.peakDist, t), true, elapsed
  else
    local t = smoothstep((elapsed - RISE_H) / FALL_H)
    return lerp(effect.peakDist, 0.0, t), true, elapsed
  end
end

local function addDose(sourceName, amount)
  amount = amount or 1
  if amount < 1 then return end

  local gameH = nowGameH()
  local liveDist = 0.0
  local oldLevel = effect.level

  if effect.active and effect.level > 0 then
    local d, stillActive = currentDistortionAt(gameH)
    if stillActive then
      liveDist = d
    end
  end

  effect.level = effect.level + amount
  effect.active = true
  effect.startH = gameH
  effect.startDist = liveDist
  effect.peakDist = peakDistortionForLevel(effect.level)

  --print(string.format(
  --  'debugmsg [skooma] addDose source=%s amount=%d oldLevel=%d newLevel=%d startDist=%.3f peakDist=%.3f rise=%.2fh fall=%.2fh',
  --  tostring(sourceName or 'unknown'),
   -- amount,
   -- oldLevel,
   -- effect.level,
  --  effect.startDist,
  --  effect.peakDist,
  --  RISE_H,
  --  FALL_H
  --))
end

-- =============================================================
-- POTION SKOOMA DETECTION
-- =============================================================
local lastPotionCount = 0

local function countPotionSkooma()
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

local function detectNewPotionDose()
  local n = countPotionSkooma()

  if n > lastPotionCount then
    addDose('skooma_potion', n - lastPotionCount)
  end

  lastPotionCount = n
end

-- =============================================================
-- SHADER CACHE
-- =============================================================
local skoomaEnabled = false
local vignetteEnabled = false

local s = {
  distortion = 0.0,
  doublevision = 0.0,
  fractalSize = 0.0,
  fractalAmount = 0.0,
}

local lastS = {
  distortion = nil,
  doublevision = nil,
  fractalSize = nil,
  fractalAmount = nil,
}

local v = {
  amount = 0.0,
  midpoint = VIGNETTE_BASE_MID,
  roundness = VIGNETTE_BASE_ROUND,
  feather = VIGNETTE_BASE_FEATHER,
}

local lastV = {
  amount = nil,
  midpoint = nil,
  roundness = nil,
  feather = nil,
}

local function setSkoomaEnabled(on)
  if on == skoomaEnabled then return end
  skoomaEnabled = on
  if on then
    skoomaShader:enable()
  else
    skoomaShader:disable()
  end
end

local function setVignetteEnabled(on)
  if on == vignetteEnabled then return end
  vignetteEnabled = on
  if on then
    vignetteShader:enable()
  else
    vignetteShader:disable()
  end
end

local function setSkoomaFloatIfChanged(key, uniformName)
  if s[key] ~= lastS[key] then
    lastS[key] = s[key]
    skoomaShader:setFloat(uniformName, s[key])
  end
end

local function setVignetteFloatIfChanged(key, uniformName)
  if v[key] ~= lastV[key] then
    lastV[key] = v[key]
    vignetteShader:setFloat(uniformName, v[key])
  end
end

local function pushSkoomaShader()
  setSkoomaFloatIfChanged('distortion',    SKOOMA_UNIF.distortion)
  setSkoomaFloatIfChanged('doublevision',  SKOOMA_UNIF.doublevision)
  setSkoomaFloatIfChanged('fractalSize',   SKOOMA_UNIF.fractalSize)
  setSkoomaFloatIfChanged('fractalAmount', SKOOMA_UNIF.fractalAmount)
end

local function pushVignetteShader()
  setVignetteFloatIfChanged('amount',    VIGNETTE_UNIF.amount)
  setVignetteFloatIfChanged('midpoint',  VIGNETTE_UNIF.midpoint)
  setVignetteFloatIfChanged('roundness', VIGNETTE_UNIF.roundness)
  setVignetteFloatIfChanged('feather',   VIGNETTE_UNIF.feather)
end

local function clearAllVisuals()
  setSkoomaEnabled(false)
  setVignetteEnabled(false)

  s.distortion = 0.0
  s.doublevision = 0.0
  s.fractalSize = 0.0
  s.fractalAmount = 0.0

  v.amount = 0.0
  v.midpoint = VIGNETTE_BASE_MID
  v.roundness = VIGNETTE_BASE_ROUND
  v.feather = VIGNETTE_BASE_FEATHER

  pushSkoomaShader()
  pushVignetteShader()

  core.sendGlobalEvent('skoomaSetTimeScale', 1.0)
end

-- =============================================================
-- CAMERA ROLL
-- =============================================================
local rollPhase = 0.0
local rollStrength = 0.0
local cachedDistortion = 0.0

local ROLL_MAX_RAD   = 0.5
local PERIOD_MIN_SEC = 9.0
local PERIOD_MAX_SEC = 24.0

local function applyCameraTilt(dt)
  local norm = clamp(cachedDistortion / (BASE_F1 * 3.0), 0.0, 1.0)

  local target = norm ^ 1.5
  if cachedDistortion > 0.05 then
    target = math.max(target, 0.06)
  end

  rollStrength = rollStrength + (target - rollStrength) * 0.035

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
-- DEBUG OUTPUT
-- =============================================================
local lastDebugBucket = nil
local lastDebugLevel = -1
local lastDebugDist = -999.0
local lastDebugScale = -999.0

local function debugState(elapsedH, timeScale)
  if not effect.active or effect.level <= 0 then
    if lastDebugLevel ~= 0 then
      lastDebugLevel = 0
      lastDebugBucket = nil
      lastDebugDist = 0.0
      lastDebugScale = 1.0
    end
    return
  end

  local bucket = math.floor(elapsedH * 4.0)
  if bucket == lastDebugBucket
    and lastDebugLevel == effect.level
    and math.abs(s.distortion - lastDebugDist) < 0.08
    and math.abs(timeScale - lastDebugScale) < 0.02 then
    return
  end

  lastDebugBucket = bucket
  lastDebugLevel = effect.level
  lastDebugDist = s.distortion
  lastDebugScale = timeScale

  --print(string.format(
  --  'debugmsg [skooma] level=%d elapsed=%.2fh startDist=%.3f peakDist=%.3f currentDist=%.3f double=%.3f fractalSize=%.3f fractalAmt=%.3f vignetteAmt=%.3f midpoint=%.3f round=%.3f feather=%.3f timeScale=%.3f',
  --  effect.level,
  --  elapsedH,
  --  effect.startDist,
  --  effect.peakDist,
  --  s.distortion,
  --  s.doublevision,
  --  s.fractalSize,
  --  s.fractalAmount,
  --  v.amount,
  --  v.midpoint,
  --  v.roundness,
  --  v.feather,
  --  timeScale
  --))
end

-- =============================================================
-- EVENT FROM GLOBAL: PIPE SMOKED
-- =============================================================
local function onPipeSmoked(data)
  startPipeFX(data and data.soundFile or nil)
  addDose('moon_sugar_pipe', 1)
end

-- =============================================================
-- ENGINE LOOP
-- =============================================================
local acc = 0.0

return {
  eventHandlers = {
    DETD_SkoomaPipeSmoked = onPipeSmoked
  },

  engineHandlers = {
    onUpdate = function(dt)
      updatePipeFX()

      acc = acc + dt
      if acc >= HEAVY_DT then
        acc = acc - HEAVY_DT

        detectNewPotionDose()

        local gameH = nowGameH()
        local dist, activeNow, elapsedH = currentDistortionAt(gameH)

        if not activeNow then
          if effect.active then
            resetEffect('cycle_finished')
          end

          clearAllVisuals()
          cachedDistortion = 0.0
          rollStrength = 0.0
          camera.setRoll(0.0)
          debugState(0.0, 1.0)
        else
          setSkoomaEnabled(true)
          setVignetteEnabled(true)

          local ratio = dist / BASE_F1

          -- Main skooma shader values
          s.distortion    = dist
          s.doublevision  = BASE_F2 * ratio
          s.fractalSize   = BASE_F3 * ratio
          s.fractalAmount = BASE_F4 * ratio

          -- Vignette follows current live distortion.
          -- Because current distortion is preserved on re-dose,
          -- this will not suddenly drop when another dose is taken.
          -- And because it is not latched, it will fade back down during comedown.
          local vignetteProgress = clamp(ratio / VIGNETTE_FULL_AT_RATIO, 0.0, 1.0)
          vignetteProgress = vignetteProgress ^ 0.72

          v.amount    = VIGNETTE_MAX_AMOUNT * vignetteProgress
          v.midpoint  = lerp(VIGNETTE_BASE_MID,   VIGNETTE_MIN_MID,    vignetteProgress)
          v.roundness = lerp(VIGNETTE_BASE_ROUND, VIGNETTE_PEAK_ROUND, vignetteProgress)
          v.feather   = lerp(VIGNETTE_BASE_FEATHER, VIGNETTE_PEAK_FEATHER, vignetteProgress)

          pushSkoomaShader()
          pushVignetteShader()

          local tscale = timeScaleForDistortion(s.distortion)
          core.sendGlobalEvent('skoomaSetTimeScale', tscale)

          cachedDistortion = s.distortion
          debugState(elapsedH, tscale)
        end
      end

      applyCameraTilt(dt)
    end
  }
}