-- scripts/speechcraft_bribe/settings.lua
-- Defaults + helpers to read current values from Settings UI (OpenMW 0.49)
-- Preset C: "Heroic Fantasy" — specialists are gods; everyone else pays dearly.

local storage = require('openmw.storage')

local M = {}

-- Mod namespace / l10n context
M.mod  = "speechcraft_bribe"
M.l10n = "SpeechcraftBribery"

-- Records / constants
M.goldRecordId = "gold_001"

-- Input
M.hotkeyName       = "speechcraft_bribe_open"
-- These are l10n KEYS used by input.registerTrigger and the settings page.
M.hotkeyName_L10N  = "hotkey_bribe_open_name"
M.hotkeyDesc_L10N  = "hotkey_bribe_open_desc"

-- === DEFAULTS (used if player hasn't changed them in Options) ================
-- Tries & cooldown
M.triesMax       = 3
M.cooldownHours  = 24

-- Inflation (configurable)
-- Multiplicative factor starts at inflationStart and is capped at inflationCap.
-- Each accepted bribe adds to inflation by the *_Add* values (fractions, e.g. 0.10 = +10%).
M.inflationStart        = 1.0
M.inflationCap          = 3.0
M.inflationAddSuccess   = 0.09
M.inflationAddCritical  = 0.18
M.inflationAddOverpay   = 0.36
M.inflationDecayPerDay  = 1.0    -- units/day toward 1.0

-- Reaction thresholds (offer/required ratio)
M.thresholds = {
  insulting = 0.25,  -- way under
  low       = 0.75,  -- under
  close     = 0.95,  -- almost there
  success   = 1.05,  -- fair offer
  critical  = 1.35,  -- excellent
}

-- Dynamic band widening/shrinking by stat differences  (PRESET C)
M.speechcraftRangeScale   = 0.018
M.personalityRangeScale   = 0.006
M.rangeScaleMin           = 0.45
M.rangeScaleMax           = 2.20

-- Requirement (price) tuning                          (PRESET C)
M.mercantileDeltaScale    = 0.03
M.mercantileMultMin       = 0.35
M.mercantileMultMax       = 1.80

-- Resistance (added gold when outclassed)             (PRESET C)
M.resistSpeechWeight      = 0.70
M.resistPersonalityWeight = 0.30
M.resistWeight            = 1.20

-- Try consumption rule for the 'close' zone           (PRESET C)
M.closeNoTry = true

-- Disposition deltas (keeping your current tough values)
M.disposition = {
  insulting = -10,
  low       = -5,
  close     = -1,
  success   = 10,
  critical  = 15,
  overpay   = 15,
}

-- XP scaling for accepted bribes (applies equally to Speechcraft & Mercantile)
M.xpScaleSuccess  = 1.0
M.xpScaleCritical = 2.0
M.xpScaleOverpay  = 1.5

-- UI behaviour
M.showMsgInDialogue = true

-- ---- Runtime overlay from Settings UI --------------------------------------
local groupTuning = "Settings" .. M.mod .. "_tuning"

--- Apply values saved by the Settings UI over our defaults.
function M.refreshFromStorage()
  local ok, sec = pcall(storage.playerSection, groupTuning)
  if not ok or not sec then return end

  -- Numbers
  M.triesMax       = tonumber(sec:get('tries_max'))            or M.triesMax
  M.cooldownHours  = tonumber(sec:get('cooldown_hours'))       or M.cooldownHours

  -- Inflation tuning
  M.inflationStart        = tonumber(sec:get('inflation_start'))         or M.inflationStart
  M.inflationCap          = tonumber(sec:get('inflation_cap'))           or M.inflationCap
  M.inflationAddSuccess   = tonumber(sec:get('inflation_add_success'))   or M.inflationAddSuccess
  M.inflationAddCritical  = tonumber(sec:get('inflation_add_critical'))  or M.inflationAddCritical
  M.inflationAddOverpay   = tonumber(sec:get('inflation_add_overpay'))   or M.inflationAddOverpay
  M.inflationDecayPerDay  = tonumber(sec:get('inflation_decay_per_day')) or M.inflationDecayPerDay

  -- Difficulty knobs
  M.baseFloor               = tonumber(sec:get('base_floor'))                or M.baseFloor
  M.mercantileDeltaScale    = tonumber(sec:get('mercantile_delta_scale'))    or M.mercantileDeltaScale
  M.speechcraftRangeScale   = tonumber(sec:get('speechcraft_range_scale'))   or M.speechcraftRangeScale
  M.personalityRangeScale   = tonumber(sec:get('personality_range_scale'))   or M.personalityRangeScale
  M.rangeScaleMin           = tonumber(sec:get('range_scale_min'))           or M.rangeScaleMin
  M.rangeScaleMax           = tonumber(sec:get('range_scale_max'))           or M.rangeScaleMax
  M.resistWeight            = tonumber(sec:get('resist_weight'))             or M.resistWeight

  -- Try consumption rule
  local cnt = sec:get('close_no_try')
  if cnt ~= nil then M.closeNoTry = (cnt and true or false) end

  -- Disposition tweaks
  if type(M.disposition) ~= 'table' then M.disposition = {} end
  local function num(key, default)
    local v = tonumber(sec:get(key))
    return v ~= nil and v or default
  end
  M.disposition.insulting = num('disp_insulting', M.disposition.insulting)
  M.disposition.low       = num('disp_low',       M.disposition.low)
  M.disposition.close     = num('disp_close',     M.disposition.close)
  M.disposition.success   = num('disp_success',   M.disposition.success)
  M.disposition.critical  = num('disp_critical',  M.disposition.critical)
  M.disposition.overpay   = num('disp_overpay',   M.disposition.overpay)

  -- UI behavior
  local smd = sec:get('show_msg_dialogue')
  if smd ~= nil then M.showMsgInDialogue = (smd and true or false) end

  -- XP scaling
  M.xpScaleSuccess  = tonumber(sec:get('xp_scale_success'))  or M.xpScaleSuccess
  M.xpScaleCritical = tonumber(sec:get('xp_scale_critical')) or M.xpScaleCritical
  M.xpScaleOverpay  = tonumber(sec:get('xp_scale_overpay'))  or M.xpScaleOverpay
end

return M
