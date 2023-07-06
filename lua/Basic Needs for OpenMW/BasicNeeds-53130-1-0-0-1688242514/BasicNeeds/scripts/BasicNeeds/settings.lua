-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/settings.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local storage = require("openmw.storage")
local I = require("openmw.interfaces")

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
      {
         key = "EnableDeath",
         renderer = "checkbox",
         name = "name_EnableDeath",
         description = "desc_EnableDeath",
         default = true,
      },
      {
         key = "ThirstRate",
         renderer = "number",
         name = "name_ThirstRate",
         description = "desc_ThirstRate",
         default = 40,
      },
      {
         key = "HungerRate",
         renderer = "number",
         name = "name_HungerRate",
         description = "desc_HungerRate",
         default = 35,
      },
      {
         key = "ExhaustionRate",
         renderer = "number",
         name = "name_ExhaustionRate",
         description = "desc_ExhaustionRate",
         default = 30,
      },
      {
         key = "ExhaustionRecoveryRate",
         renderer = "number",
         name = "name_ExhaustionRecoveryRate",
         description = "desc_ExhaustionRecoveryRate",
         default = 60,
      },
   },
}

return storage.playerSection("SettingsPlayerBasicNeeds")
