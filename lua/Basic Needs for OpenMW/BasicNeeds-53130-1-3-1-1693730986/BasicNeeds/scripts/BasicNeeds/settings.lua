-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/settings.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local hour = require("openmw_aux.time").hour

local SETTING = {
   EnableDeath = "EnableDeath",
   EnableThirst = "EnableThirst",
   ThirstRate = "ThirstRate",
   EnableHunger = "EnableHunger",
   HungerRate = "HungerRate",
   EnableExhaustion = "EnableExhaustion",
   ExhaustionRate = "ExhaustionRate",
   ExhaustionRecoveryRate = "ExhaustionRecoveryRate",
}

local function checkbox(fields)
   return {
      key = fields.key,
      renderer = "checkbox",
      name = "name_" .. fields.key,
      description = "desc_" .. fields.key,
      default = fields.default,
      disabled = fields.disabled or false,
      l10n = fields.l10n or "Interface",
      trueLabel = fields.trueLabel or "Yes",
      falseLabel = fields.falseLabel or "No",
   }
end

local function number(fields)
   return {
      key = fields.key,
      renderer = "number",
      name = "name_" .. fields.key,
      description = "desc_" .. fields.key,
      default = fields.default,
      disabled = fields.disabled or false,
      integer = fields.integer or false,
      min = fields.min or nil,
      max = fields.max or nil,
   }
end

I.Settings.registerPage {
   key = "BasicNeeds",
   l10n = "BasicNeeds",
   name = "name_Page",
   description = "desc_Page",
}

I.Settings.registerGroup {
   page = "BasicNeeds",
   key = "SettingsPlayerBasicNeeds",
   l10n = "BasicNeeds",
   name = "name_Group",
   description = "desc_Group",
   permanentStorage = false,
   settings = {
      checkbox {
         key     = SETTING.EnableDeath,
         default = true,
      },
      checkbox {
         key     = SETTING.EnableThirst,
         default = true,
      },
      number {
         key     = SETTING.ThirstRate,
         default = 40,
      },
      checkbox {
         key     = SETTING.EnableHunger,
         default = true,
      },
      number {
         key     = SETTING.HungerRate,
         default = 35,
      },
      checkbox {
         key     = SETTING.EnableExhaustion,
         default = true,
      },
      number {
         key     = SETTING.ExhaustionRate,
         default = 30,
      },
      number {
         key     = SETTING.ExhaustionRecoveryRate,
         default = 60,
      },
   },
}

local function getValues(group)
   return {
      -- Enable / Disable needs
      enableThirst           = group:get(SETTING.EnableThirst),
      enableHunger           = group:get(SETTING.EnableHunger),
      enableExhaustion       = group:get(SETTING.EnableExhaustion),
      -- If death is disabled, simply limit values to 999
      maxValue               = group:get(SETTING.EnableDeath) and 1000 or 999,
      -- All rates are configured as per hour values, so we first convert them to
      -- per second values
      thirstRate             = group:get(SETTING.ThirstRate) / hour,
      hungerRate             = group:get(SETTING.HungerRate) / hour,
      exhaustionRate         = group:get(SETTING.ExhaustionRate) / hour,
      exhaustionRecoveryRate = -(group:get(SETTING.ExhaustionRecoveryRate) / hour),
   }
end

return {
   group = storage.playerSection("SettingsPlayerBasicNeeds"),
   getValues = getValues,
}
