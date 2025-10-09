-- scripts/speechcraft_bribe/settings_ui.lua
-- OpenMW 0.49 – Options page for Speechcraft Bribe
-- Preset C defaults are taken from scripts/speechcraft_bribe/settings.lua (S.*)

local I       = require('openmw.interfaces')
local input   = require('openmw.input')
local storage = require('openmw.storage')
local S       = require('scripts.speechcraft_bribe.settings')

local pageKey       = S.mod .. ".page"
local groupControls = "Settings" .. S.mod .. "_controls"  -- must start with "Settings"
local groupTuning   = "Settings" .. S.mod .. "_tuning"

-- Ensure our trigger exists so inputBinding can bind to it
if not input.triggers[S.hotkeyName] then
  input.registerTrigger{
    key = S.hotkeyName,
    l10n = S.l10n,
    name = 'blank_label',
    description = 'blank_label',
  }
end

-- Page
I.Settings.registerPage{
  key = pageKey,
  l10n = S.l10n,
  name = 'page_name',
  description = 'page_desc',
}

-- Controls group (global across saves)
I.Settings.registerGroup{
  key = groupControls,
  page = pageKey,
  l10n = S.l10n,
  name = 'group_controls_name',
  description = 'group_controls_desc',
  permanentStorage = true,
  settings = {
    {
      key = 'bribe_hotkey',
      name = 'hotkey_bribe_open_name',
      default = "",       -- inputBinding needs a *string* default
      renderer = 'inputBinding',
      argument = {
        type = 'trigger',
        key = S.hotkeyName,
        name = 'blank_label',
        description = 'blank_label',
      },
    },
  },
}

-- Gameplay tuning (also global; change to false for per-save)
I.Settings.registerGroup{
  key = groupTuning,
  page = pageKey,
  l10n = S.l10n,
  name = 'group_tuning_name',
  description = 'group_tuning_desc',
  permanentStorage = true,
  settings = {
    -- Tries & cooldown
    {
      key = 'tries_max',
      name = 'tries_max_name',
      description = 'tries_max_desc',
      default = S.triesMax or 3,
      renderer = 'number',
      argument = { integer = true, min = 1, max = 10 },
    },
    {
      key = 'cooldown_hours',
      name = 'cooldown_hours_name',
      description = 'cooldown_hours_desc',
      default = S.cooldownHours or 24,
      renderer = 'number',
      argument = { integer = true, min = 1, max = 168 },
    },

    -- Inflation tuning (fractions except start/cap)
    {
      key = 'inflation_start',
      name = 'inflation_start_name',
      description = 'inflation_start_desc',
      default = S.inflationStart or 1.0,
      renderer = 'number',
      argument = { integer = false, min = 1.0, max = 10.0 },
    },
    {
      key = 'inflation_cap',
      name = 'inflation_cap_name',
      description = 'inflation_cap_desc',
      default = S.inflationCap or 3.0,
      renderer = 'number',
      argument = { integer = false, min = 1.0, max = 10.0 },
    },
    {
      key = 'inflation_add_success',
      name = 'inflation_add_success_name',
      description = 'inflation_add_success_desc',
      default = S.inflationAddSuccess or 0.09,
      renderer = 'number',
      argument = { integer = false, min = 0.0, max = 1.0 },
    },
    {
      key = 'inflation_add_critical',
      name = 'inflation_add_critical_name',
      description = 'inflation_add_critical_desc',
      default = S.inflationAddCritical or 0.18,
      renderer = 'number',
      argument = { integer = false, min = 0.0, max = 1.0 },
    },
    {
      key = 'inflation_add_overpay',
      name = 'inflation_add_overpay_name',
      description = 'inflation_add_overpay_desc',
      default = S.inflationAddOverpay or 0.36,
      renderer = 'number',
      argument = { integer = false, min = 0.0, max = 1.0 },
    },
    {
      key = 'inflation_decay_per_day',
      name = 'inflation_decay_name',
      description = 'inflation_decay_desc',
      default = S.inflationDecayPerDay or 1.0,
      renderer = 'number',
      argument = { integer = false, min = 0, max = 5 },
    },

    -- Difficulty knobs (PRESET C defaults)
    {
      key = 'base_floor',
      name = 'base_floor_name',
      description = 'base_floor_desc',
      default = S.baseFloor or 25,
      renderer = 'number',
      argument = { integer = true, min = 1, max = 500 },
    },
    {
      key = 'mercantile_delta_scale',
      name = 'mercantile_delta_scale_name',
      description = 'mercantile_delta_scale_desc',
      default = S.mercantileDeltaScale or 0.03,
      renderer = 'number',
      argument = { integer = false, min = 0.0, max = 0.1 },
    },
    {
      key = 'speechcraft_range_scale',
      name = 'speechcraft_range_scale_name',
      description = 'speechcraft_range_scale_desc',
      default = S.speechcraftRangeScale or 0.018,
      renderer = 'number',
      argument = { integer = false, min = 0.0, max = 0.05 },
    },
    {
      key = 'personality_range_scale',
      name = 'personality_range_scale_name',
      description = 'personality_range_scale_desc',
      default = S.personalityRangeScale or 0.006,
      renderer = 'number',
      argument = { integer = false, min = 0.0, max = 0.02 },
    },
    {
      key = 'range_scale_min',
      name = 'range_scale_min_name',
      description = 'range_scale_min_desc',
      default = S.rangeScaleMin or 0.45,
      renderer = 'number',
      argument = { integer = false, min = 0.1, max = 2.0 },
    },
    {
      key = 'range_scale_max',
      name = 'range_scale_max_name',
      description = 'range_scale_max_desc',
      default = S.rangeScaleMax or 2.2,
      renderer = 'number',
      argument = { integer = false, min = 0.5, max = 3.0 },
    },
    {
      key = 'resist_weight',
      name = 'resist_weight_name',
      description = 'resist_weight_desc',
      default = S.resistWeight or 1.2,
      renderer = 'number',
      argument = { integer = false, min = 0.0, max = 2.0 },
    },
    {
      key = 'close_no_try',
      name = 'close_no_try_name',
      description = 'close_no_try_desc',
      default = (S.closeNoTry and true or false),
      renderer = 'checkbox',
      argument = { l10n = 'Interface' },
    },

    -- Disposition knobs (your current values as defaults)
    {
      key = 'disp_insulting',
      name = 'disp_insulting_name',
      description = 'disp_insulting_desc',
      default = (S.disposition and S.disposition.insulting) or -10,
      renderer = 'number',
      argument = { integer = true, min = -20, max = 0 },
    },
    {
      key = 'disp_low',
      name = 'disp_low_name',
      description = 'disp_low_desc',
      default = (S.disposition and S.disposition.low) or -5,
      renderer = 'number',
      argument = { integer = true, min = -10, max = 10 },
    },
    {
      key = 'disp_close',
      name = 'disp_close_name',
      description = 'disp_close_desc',
      default = (S.disposition and S.disposition.close) or -1,
      renderer = 'number',
      argument = { integer = true, min = -10, max = 10 },
    },
    {
      key = 'disp_success',
      name = 'disp_success_name',
      description = 'disp_success_desc',
      default = (S.disposition and S.disposition.success) or 10,
      renderer = 'number',
      argument = { integer = true, min = -10, max = 20 },
    },
    {
      key = 'disp_critical',
      name = 'disp_critical_name',
      description = 'disp_critical_desc',
      default = (S.disposition and S.disposition.critical) or 15,
      renderer = 'number',
      argument = { integer = true, min = -10, max = 30 },
    },
    {
      key = 'disp_overpay',
      name = 'disp_overpay_name',
      description = 'disp_overpay_desc',
      default = (S.disposition and S.disposition.overpay) or 15,
      renderer = 'number',
      argument = { integer = true, min = -10, max = 30 },
    },

    -- UI behavior
    {
      key = 'show_msg_dialogue',
      name = 'show_msg_dialogue_name',
      description = 'show_msg_dialogue_desc',
      default = (S.showMsgInDialogue ~= false),
      renderer = 'checkbox',
      argument = { l10n = 'Interface' },
    },

    -- XP scaling (accepted bribes only)
    {
      key = 'xp_scale_success',
      name = 'xp_scale_success_name',
      description = 'xp_scale_success_desc',
      default = S.xpScaleSuccess or 1.0,
      renderer = 'number',
      argument = { integer = false, min = 0.0, max = 5.0 },
    },
    {
      key = 'xp_scale_critical',
      name = 'xp_scale_critical_name',
      description = 'xp_scale_critical_desc',
      default = S.xpScaleCritical or 2.0,
      renderer = 'number',
      argument = { integer = false, min = 0.0, max = 5.0 },
    },
    {
      key = 'xp_scale_overpay',
      name = 'xp_scale_overpay_name',
      description = 'xp_scale_overpay_desc',
      default = S.xpScaleOverpay or 1.5,
      renderer = 'number',
      argument = { integer = false, min = 0.0, max = 5.0 },
    },
  },
}
