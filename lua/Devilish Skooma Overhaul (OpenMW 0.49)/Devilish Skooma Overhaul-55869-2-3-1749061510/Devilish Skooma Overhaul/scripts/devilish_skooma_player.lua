-- ==============================================================
--  Devilish Skooma   (LOCAL player / NPC script)
--  Applies psychedelic shader + time-scale based on active spells
-- ==============================================================
local self   = require('openmw.self')
local types  = require('openmw.types')
local time   = require('openmw_aux.time')
local anim   = require('openmw.animation')
local core   = require('openmw.core')
local pp     = require('openmw.postprocessing')

local shader = pp.load('epo_detd_skooma')

-- ───────────────────────────────────────────────────────────────
--  Constants
-- ───────────────────────────────────────────────────────────────
local TICK_SEC      = 0.1
local BASE_DURATION = 150
local INC           = TICK_SEC / BASE_DURATION     -- progress per tick

local BASE_F1, BASE_F2 = 3.33, 0.16
local BASE_F3, BASE_F4 = 0.66, 0.23

local DOSE_MULT = { [2] = 1.5, [3] = 1.75 }

local UNIF = {
  'drugged_distortion_amount',
  'drugged_doublevision_amount',
  'drugged_fractals_size',
  'drugged_fractals_amount',
}

-- distortion 0-5.8 → slow-mo multiplier 1→0.5
local function slowMoCurve(d)
  if d <= 3.33  then return 1    - d/3.33  * 0.15 end -- 1 → 0.85
  if d <= 4.995 then return 0.85 - (d-3.33)/1.665 * 0.15 end -- 0.85 → 0.70
  return              0.70 - (d-4.995)/0.8325 * 0.20         -- 0.70 → 0.50
end

-- ───────────────────────────────────────────────────────────────
--  Runtime state
-- ───────────────────────────────────────────────────────────────
local prog, rev = 0, 0                 -- 0-1 sliders
local f = { 0, 0, 0, 0 }               -- shader factors
local pipeSpawned = false              -- local flag; no engine vars

local function pushShader()
  for i = 1, 4 do shader:setFloat(UNIF[i], f[i]) end
end

-- ───────────────────────────────────────────────────────────────
--  Main ticker (every 0.1 s)
-- ───────────────────────────────────────────────────────────────
time.runRepeatedly(function()

  ----------------------------------------------------------------
  -- 1 · cache spell table once
  ----------------------------------------------------------------
  local spells   = types.Actor.activeSpells(self)
  local has      = function(id) return spells:isSpellActive(id) end

  -- count vanilla “Skooma” effects
  local dosage = 0
  for _, p in pairs(spells) do
    if p.name == 'Skooma' then dosage = dosage + 1 end
  end

  ----------------------------------------------------------------
  -- 2 · ensure helper spell present once
  ----------------------------------------------------------------
  if dosage > 0 and not has('detd_skooma_yes') then
    types.Actor.spells(self):add('detd_skooma_yes')
  end

  ----------------------------------------------------------------
  -- 3 · pipe animation / VFX (spawn once)
  ----------------------------------------------------------------
  if has('detd_pipe_animation') then
    if not pipeSpawned then
      pipeSpawned = true
      anim.playBlended(self, 'skoomapipe',
        { priority = anim.PRIORITY.Scripted })
      anim.addVfx(self, 'meshes/spipe_vfx.nif',
        { boneName = 'Shield Bone', loop = true, vfxId = 'skoomaPipeFx' })
    end
  elseif pipeSpawned then
    pipeSpawned = false
    anim.removeVfx(self, 'skoomaPipeFx')        -- safe even if already gone
  end

  ----------------------------------------------------------------
  -- 4 · determine multiplier & targets
  ----------------------------------------------------------------
  local mult = DOSE_MULT[dosage] or 1
  if has('detd_skooma_dosag3') then mult = DOSE_MULT[3]
  elseif has('detd_skooma_dosag2') then mult = DOSE_MULT[2] end

  local tgt1, tgt2 = BASE_F1*mult, BASE_F2*mult
  local tgt3, tgt4 = BASE_F3*mult, BASE_F4*mult

  ----------------------------------------------------------------
  -- 5 · shader on/off
  ----------------------------------------------------------------
  local up   = has('detd_skooma_yes')
  local down = has('detd_skooma_3')          -- comedown

  if up or down then shader:enable() else shader:disable() end

  ----------------------------------------------------------------
  -- 6 · update factors
  ----------------------------------------------------------------
  if up and not down then                        -- ramp-up
    prog = math.min(prog + INC, 1)
    f[1],f[2],f[3],f[4] = prog*tgt1, prog*tgt2, prog*tgt3, prog*tgt4

  elseif down then                               -- ramp-down
    rev  = math.min(rev + INC, 1)
    local k = 1 - rev
    f[1],f[2],f[3],f[4] = k*tgt1, k*tgt2, k*tgt3, k*tgt4

  elseif has('detd_skooma_2') then               -- fixed state
    f[1],f[2],f[3],f[4] = tgt1, tgt2, tgt3, tgt4

  else                                           -- effect cleared
    prog, rev = 0, 0
    for i = 1,4 do f[i] = 0 end
  end

  pushShader()

  ----------------------------------------------------------------
  -- 7 · send time-scale to global script
  ----------------------------------------------------------------
  core.sendGlobalEvent('skoomaSetTimeScale', slowMoCurve(f[1]))

end, TICK_SEC)

-- This local script only sends events; world-level handling goes in a
-- server/global script.
return {}
