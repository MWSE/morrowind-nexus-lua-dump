-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/settings.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local storage = require("openmw.storage")
local I = require("openmw.interfaces")

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

I.Settings.registerPage {
   key = "BasicNeeds",
   l10n = "BasicNeeds",
   name = "name_Page",
   description = "desc_Page",
}

local function enabled(key, default)
   return {
      key = key,
      renderer = "checkbox",
      name = "name_" .. key,
      description = "desc_" .. key,
      default = default,
   }
end

local function rate(key, default)
   return {
      key = key,
      renderer = "number",
      name = "name_" .. key,
      description = "desc_" .. key,
      min = 1,
      default = default,
   }
end

I.Settings.registerGroup {
   page = "BasicNeeds",
   key = "SettingsPlayerBasicNeeds",
   l10n = "BasicNeeds",
   name = "name_Group",
   description = "desc_Group",
   permanentStorage = false,
   settings = {
      enabled(SETTING.EnableDeath, true),
      enabled(SETTING.EnableThirst, true),
      rate(SETTING.ThirstRate, 40),
      enabled(SETTING.EnableHunger, true),
      rate(SETTING.HungerRate, 35),
      enabled(SETTING.EnableExhaustion, true),
      rate(SETTING.ExhaustionRate, 30),
      rate(SETTING.ExhaustionRecoveryRate, 60),
   },
}

return {
   SETTING = SETTING,
   group = storage.playerSection("SettingsPlayerBasicNeeds")
}
