local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local postprocessing = require('openmw.postprocessing')
local ambient = require('openmw.ambient')
local camera = require('openmw.camera')

-- ============================================================
-- Postprocessing shader (keep enabled; toggle via uEnabled)
-- ============================================================
local shader = postprocessing.load('epo_detd_drunk')
shader:enable()

-- ============================================================
-- Alcohol units table (keys MUST match ActiveSpell.id recordId)
-- Use lowercase keys; we lower() incoming ids.
-- ============================================================
local ALCOHOL_UNITS = {
  -- Vanilla
  potion_local_brew_01      = 1.5,
  potion_comberry_brandy_01 = 2.0,
  potion_comberry_wine_01   = 1.5,
  potion_local_liquor_01    = 2.0,
  potion_cyro_whiskey_01    = 2.0,
  potion_cyro_brandy_01     = 2.0,
  p_vintagecomberrybrandy1  = 2.0,
  potion_ancient_brandy     = 3.0,
  potion_nord_mead          = 1.5,

  -- TD / Tamriel Data
  t_imp_drink_wineplallovin_01      = 1.5,
  t_imp_drink_winefreeestat_01      = 1.5,
  t_imp_drink_winesurilie_01        = 1.5,
  t_imp_drink_winetamikaclr_01      = 1.5,
  t_imp_drink_winesour              = 1.5,
  t_imp_drink_winesweet             = 1.5,
  t_imp_drink_winetwinmoon_01       = 1.5,
  t_imp_drink_winewolfsbl_01        = 1.5,
  t_imp_drink_wineblackhill_01      = 1.5,
  t_imp_drink_winerufinoclr_01      = 1.5,
  t_rga_drink_winesutchgonogro_01    = 1.5,
  t_rga_drink_winesutchtalan_01     = 1.5,
  t_nor_drink_winereach_01          = 1.5,
  t_bre_drink_winewayrest_01        = 1.5,
  t_imp_drink_winebattle_01         = 1.5,
  t_we_drink_wine_01                = 1.5,

  t_imp_drink_aleakul_01            = 1.5,
  t_nor_drink_snowberryaleveig_01   = 1.5,
  t_we_drink_pigmilkbeerjagga_01    = 1.5,
  t_nor_drink_beerlight_01          = 1.5,
  t_nor_drink_beer_01               = 1.5,
  t_nor_drink_bodja_01              = 1.5,
  t_nor_drink_fyrg_01               = 1.5,
  t_nor_drink_gjeche_01             = 1.5,
  t_nor_drink_gjulve_01             = 1.5,
  t_nor_drink_risla_01              = 1.5,

  t_imp_drink_cherrybrandy_01       = 2.5,
  t_we_drink_meatjuicerotmeth_01    = 2.5,
  t_nor_drink_strmead_01            = 3.5,

  t_imp_drink_cideraliyew_01        = 1.5,
  t_orc_drink_liquorungorth_02      = 2.0,
  t_pi_drink_palmwine               = 1.5,
  t_rea_drink_liquoraeli_01         = 2.0,
  t_rea_drink_teagyrrg_01           = 0.0,
  t_rga_drink_sift                  = 1.5,
  t_yne_drink_pudjing               = 1.5,
  t_rga_drink_aibe_01               = 1.5,

  t_de_drink_bourbongoya_01         = 2.0,

  -- Other mods (as you set them)
  lfl_br_morrowind = 1.5,
  jw_beer1         = 1.5,
  lfl_wn_corkbulb  = 1.5,

  nom_beer_04      = 1.5,
  nom_wine_02      = 1.5,
  nom_wine_03      = 1.5,
  nom_wine_08      = 1.5,
  nom_wine_09      = 1.5,

  ab_dri_musa    = 1.5,
  ab_dri_sillapi = 1.5,
  ab_dri_yamuz   = 1.5,

  sw_spice            = 1.0,
  sw_spilledalchohol  = 1.0,
  sw_strongspice      = 1.0,
  sw_adrenalstimulant = 1.0,

  sw_bluebooze            = 2.0,
  sw_booze                = 2.0,
  sw_oldbooze             = 2.0,
  swe_oldbooze            = 2.0,
  sw_boozecuring          = 2.0,
  sw_boozecuringquest     = 2.0,
  sw_boozefatigue         = 2.0,
  sw_boozefatiguequest    = 2.0,
  sw_boozejungle          = 2.0,
  sw_boozemedicine        = 2.0,
  sw_boozesensitive       = 2.0,
  sw_boozesensitivequest  = 2.0,

  t_com_potion_daedricichor_e = 2.0,
  t_kha_drink_sugarrum        = 2.0,

  t_qyc_cimoa = 1.5,
  t_qyk_ngopta = 1.5,
  t_cnq_ngopta = 1.5,

  t_bre_drink_aperitifbevonche_01 = 1.5,
  t_bre_drink_beer_01             = 1.5,
  t_bre_drink_brandychallegoux_01 = 2.5,
  t_bre_drink_ciderpommon_01      = 1.5,
  t_bre_drink_digestifeillevon_01 = 2.0,
  t_bre_drink_duxpom              = 1.5,
  t_bre_drink_jinevere            = 1.5,
  t_bre_drink_liquorbreque_01     = 2.0,
  t_bre_drink_winebalfiera_01     = 1.5,
  t_bre_drink_wineheartplum_01    = 1.5,
  t_bre_drink_winemarivon_01      = 1.5,

  t_de_drink_liquorllotham_01     = 2.0,
  t_de_drink_punavitjug           = 2.0,
  t_de_drink_punavitresin_01      = 1.0,
  t_de_drink_shakhal_01           = 1.5,
  t_de_drink_sweetbarrel_wine_01  = 1.5,

  t_imp_drink_ricebeermori_01     = 1.5,
  t_imp_drink_winesuriliebr_01    = 1.5,

  t_esr_drink_pudjing             = 1.5,
  t_he_drink_beerhautoma          = 1.5,
  t_he_drink_wineathelin          = 1.5,
  t_he_drink_wineisquel           = 1.5,
  t_he_drink_winerosado           = 1.5,
  t_he_drink_winesolicichi        = 1.5,

  t_rga_drink_abeceanrum_01        = 2.0,
  t_rga_drink_beer_01              = 1.5,
  t_rga_drink_bogru_01             = 1.5,
  t_rga_drink_cactuswine_01        = 1.5,
  t_rga_drink_kaay_01              = 1.5,
  t_rga_drink_soge_01              = 1.5,

  t_yne_drink_tsokni = 1.5,
}

-- ============================================================
-- Thresholds + shader “factors”
-- ============================================================
local THRESH = { tipsy = 1, drunk = 2, blind = 4, wasted = 6, comatose = 8 }

local PRESET = {
  sober    = { enabled=false, swipe=0.02,  offset=0.01  },
  tipsy    = { enabled=true,  swipe=0.003, offset=-0.01 },
  drunk    = { enabled=true,  swipe=0.012, offset=0.008 },
  blind    = { enabled=true,  swipe=0.012, offset=0.008 },
  wasted   = { enabled=true,  swipe=0.012, offset=0.008 },
  comatose = { enabled=true,  swipe=0.012, offset=0.008  },
}

local function presetFor(level)
  if level > THRESH.comatose then return PRESET.comatose, "comatose" end
  if level > THRESH.wasted   then return PRESET.wasted,   "wasted"   end
  if level > THRESH.blind    then return PRESET.blind,    "blind"    end
  if level > THRESH.drunk    then return PRESET.drunk,    "drunk"    end
  if level > THRESH.tipsy    then return PRESET.tipsy,    "tipsy"    end
  return PRESET.sober, "sober"
end

-- Cache uniform writes (prevents spamming)
local lastEnabled, lastSwipe, lastOffset = nil, nil, nil
local function pushUniforms(p)
  if p.enabled ~= lastEnabled then
    lastEnabled = p.enabled
    shader:setBool('uEnabled', p.enabled)
  end
  if p.swipe ~= lastSwipe then
    lastSwipe = p.swipe
    shader:setFloat('uSwipeAmount', p.swipe)
  end
  if p.offset ~= lastOffset then
    lastOffset = p.offset
    shader:setFloat('uOffsetStrength', p.offset)
  end
end

-- ============================================================
-- Sounds
-- ============================================================
local SND = {
  hiccup   = "Sound\\alcohol\\hiccup.wav",
  hiccup2  = "Sound\\alcohol\\hiccup2.wav",
  hiccup_f = "Sound\\alcohol\\hiccup_f.wav",
  headache = "Sound\\alcohol\\headache.wav",
}

local function isMalePlayer()
  local rec = types.NPC.record(self)
  return rec and rec.isMale
end

local function playHiccup()
  if isMalePlayer() == false then
    ambient.playSoundFile(SND.hiccup_f, { volume=1.0, pitch=1.0, scale=true })
  else
    if math.random(0,1) == 0 then
      ambient.playSoundFile(SND.hiccup,  { volume=1.0, pitch=1.0, scale=true })
    else
      ambient.playSoundFile(SND.hiccup2, { volume=1.0, pitch=1.0, scale=true })
    end
  end
end

local lastHeadacheReal = -1e9
local function playHeadache()
  local nowReal = core.getRealTime()
  if (nowReal - lastHeadacheReal) < 8.0 then return end
  lastHeadacheReal = nowReal
  ambient.playSoundFile(SND.headache, { volume=1.0, pitch=1.0, scale=true })
end

-- ============================================================
-- Intoxication tracking (no ESP required)
-- ============================================================
local drinkLevel = 0.0
local seen = {} -- [activeSpellId] = true
local lastGameTime = nil

local hangoverHours = 0.0
local peakRank = 0
local RANK = { sober=0, tipsy=1, drunk=2, blind=3, wasted=4, comatose=5 }
local prevState = "sober"
local lastHiccupGameH = -1e9

local function gameHours() return core.getGameTime() / 3600.0 end

local function updateConsumption()
  local spells = types.Actor.activeSpells(self)
  for _, s in pairs(spells) do
    local inst = s.activeSpellId
    if inst and not seen[inst] then
      seen[inst] = true

      local rec = s.id
      if rec then
        rec = rec:lower()
        local units = ALCOHOL_UNITS[rec]
        if units then
          drinkLevel = drinkLevel + units
        end
      end
    end
  end
end

local function metabolize()
  local gt = core.getGameTime()
  if not lastGameTime then lastGameTime = gt return 0.0 end

  local dt = gt - lastGameTime
  if dt <= 0 then return 0.0 end
  lastGameTime = gt

  local dtHours = dt / 3600.0
  drinkLevel = math.max(0.0, drinkLevel - dtHours)
  return dtHours
end

local function updateHiccups(stateName)
  if stateName ~= "drunk" and stateName ~= "blind" and stateName ~= "wasted" and stateName ~= "comatose" then
    return
  end
  local nowH = gameHours()
  local intervalH = 0.25
  if stateName == "blind" then intervalH = 0.18 end
  if stateName == "wasted" then intervalH = 0.12 end
  if stateName == "comatose" then intervalH = 0.10 end

  if nowH >= (lastHiccupGameH + intervalH) then
    lastHiccupGameH = nowH
    playHiccup()
  end
end

local function updateHangover(stateName, dtGameH)
  peakRank = math.max(peakRank, RANK[stateName] or 0)

  if prevState ~= "sober" and stateName == "sober" then
    local add = 0.25
    if peakRank >= 4 then add = 1.5
    elseif peakRank >= 3 then add = 1.0
    elseif peakRank >= 2 then add = 0.5
    end
    hangoverHours = math.max(hangoverHours, add)
    peakRank = 0
  end
  prevState = stateName

  if stateName == "sober" and hangoverHours > 0 then
    hangoverHours = math.max(0.0, hangoverHours - dtGameH)
    if math.random() < 0.10 then
      playHeadache()
    end
  elseif stateName ~= "sober" then
    hangoverHours = 0.0
  end
end

-- ============================================================
-- Camera sway (slows down as drunkenness increases)
-- ============================================================
local swayPhase = 0.0
local strength = 0.0

local function strengthForState(stateName)
  if stateName == "tipsy" then return 0.15 end
  if stateName == "drunk" then return 0.35 end
  if stateName == "blind" then return 0.55 end
  if stateName == "wasted" then return 0.80 end
  if stateName == "comatose" then return 2.50 end
  return 0.0
end

local function applyCameraSway(dt, stateName)
  local target = strengthForState(stateName)
  strength = strength + (target - strength) * 0.20

  -- NEW: slower phase advance with more drunkenness
  -- strength=0 -> speed ~1.1x
  -- strength=1 -> speed ~0.35x (much slower roll)
  local slowFactor = 1.0 - 0.75 * (strength ^ 1.25)
  local phaseSpeed = (1.1 * slowFactor)

  swayPhase = swayPhase + dt * phaseSpeed
  local roll = math.sin(swayPhase) * (0.12 * strength)

  camera.setRoll(roll)

  if stateName == "sober" and strength < 0.01 then
    camera.setRoll(0.0)
  end
end

-- ============================================================
-- Update loop
-- ============================================================
local acc = 0.0
local cachedStateName = "sober"

return {
  engineHandlers = {
    onUpdate = function(dt)
      -- Smooth sway every frame
      applyCameraSway(dt, cachedStateName)

      -- Heavy logic 4x/sec
      acc = acc + dt
      if acc < 0.25 then return end
      acc = 0.0

      updateConsumption()
      local dtGameH = metabolize()

      local p, stateName = presetFor(drinkLevel)
      cachedStateName = stateName

      pushUniforms(p)

      updateHiccups(stateName)
      updateHangover(stateName, dtGameH)
    end
  }
}