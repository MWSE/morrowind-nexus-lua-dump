-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/settings.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com> (original author)
-- 2025 -- Modified by DetailDevil for Devilish Needs 
-- -----------------------------------------------------------------------------
local storage = require("openmw.storage")
local I       = require("openmw.interfaces")
local hour    = require("openmw_aux.time").hour
local async   = require("openmw.async")
local ui      = require("openmw.ui")
local debug   = require("openmw.debug")

-- Add new keys for alternative HUD placement and offsets
local SETTING = {
   EnableDeath             = "EnableDeath",
   EnableThirst            = "EnableThirst",
   ThirstRate              = "ThirstRate",
   EnableHunger            = "EnableHunger",
   HungerRate              = "HungerRate",
   EnableExhaustion        = "EnableExhaustion",
   ExhaustionRate          = "ExhaustionRate",
   ExhaustionRecoveryRate  = "ExhaustionRecoveryRate",
   AlternativeHudPosition  = "AlternativeHudPosition",
   HudOffsetX              = "HudOffsetX",
   HudOffsetY              = "HudOffsetY",
}

local function checkbox(fields)
   return {
      key         = fields.key,
      renderer    = "checkbox",
      name        = "name_" .. fields.key,
      description = "desc_" .. fields.key,
      default     = fields.default,
      disabled    = fields.disabled or false,
      l10n        = fields.l10n or "Interface",
      trueLabel   = fields.trueLabel or "Yes",
      falseLabel  = fields.falseLabel or "No",
   }
end

local function number(fields)
   return {
      key         = fields.key,
      renderer    = "number",
      name        = "name_" .. fields.key,
      description = "desc_" .. fields.key,
      default     = fields.default,
      disabled    = fields.disabled or false,
      integer     = fields.integer or false,
      min         = fields.min,
      max         = fields.max,
   }
end

I.Settings.registerPage {
   key         = "BasicNeeds",
   l10n        = "BasicNeeds",
   name        = "name_Page",
   description = "desc_Page",
}

I.Settings.registerGroup {
   page        = "BasicNeeds",
   key         = "SettingsPlayerBasicNeeds",
   l10n        = "BasicNeeds",
   name        = "name_Group",
   description = "desc_Group",
   permanentStorage = false,
   settings = {
      checkbox { key = SETTING.EnableDeath, default = false },
      checkbox { key = SETTING.EnableThirst, default = true },
      number   { key = SETTING.ThirstRate, default = 20 },
      checkbox { key = SETTING.EnableHunger, default = true },
      number   { key = SETTING.HungerRate, default = 10 },
      checkbox { key = SETTING.EnableExhaustion, default = true },
      number   { key = SETTING.ExhaustionRate, default = 20 },
      number   { key = SETTING.ExhaustionRecoveryRate, default = 60 },
      checkbox {  -- HUD alignment
         key         = SETTING.AlternativeHudPosition,
         default     = true,
         name        = "name_AlternativeHudPosition",
         description = "desc_AlternativeHudPosition",
         trueLabel   = "Right Side",
         falseLabel  = "Left Side",
      },
      number {  -- X offset for HUD
         key     = SETTING.HudOffsetX,
         default = 0,
         min     = -50000,
         max     = 50000,
         integer = true,
      },
      number {  -- Y offset for HUD
         key     = SETTING.HudOffsetY,
         default = 0,
         min     = -50000,
         max     = 50000,
         integer = true,
      },
   },
}

-- Create storage section and subscribe to changes
local group = storage.playerSection("SettingsPlayerBasicNeeds")
group:subscribe(async:callback(function(_, key)
   -- Always refresh UI
  -- ui.updateAll()
   -- But when the orientation checkbox flips, do one reload
   if key == SETTING.AlternativeHudPosition then
      debug.reloadLua()
   end
end))

local function getValues(group)
   return {
      -- Enable / Disable needs
      enableThirst           = group:get(SETTING.EnableThirst),
      enableHunger           = group:get(SETTING.EnableHunger),
      enableExhaustion       = group:get(SETTING.EnableExhaustion),
      -- If death is disabled, cap at 999
      maxValue               = group:get(SETTING.EnableDeath) and 1000 or 999,
      -- Convert per-hour rates into per-second
      thirstRate             = group:get(SETTING.ThirstRate) / hour,
      hungerRate             = group:get(SETTING.HungerRate) / hour,
      exhaustionRate         = group:get(SETTING.ExhaustionRate) / hour,
      exhaustionRecoveryRate = -(group:get(SETTING.ExhaustionRecoveryRate) / hour),
      -- HUD alignment and offsets
      alternativeHud         = group:get(SETTING.AlternativeHudPosition),
      hudOffsetX             = group:get(SETTING.HudOffsetX),
      hudOffsetY             = group:get(SETTING.HudOffsetY),
   }
end

return {
   group     = group,
   getValues = getValues,
}
