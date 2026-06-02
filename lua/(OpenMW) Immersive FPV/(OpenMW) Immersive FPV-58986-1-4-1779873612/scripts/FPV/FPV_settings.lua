local I     = require("openmw.interfaces")
local input = require('openmw.input')
local ui = require('openmw.ui')
local async = require('openmw.async')

I.Settings.registerPage {
  key         = "tt_FPV_Body",
  l10n        = "FPVBody",
  name        = "FPVBody",
  description = "Settings to toggle FPVBody",
}

input.registerAction {
   key          = 'togglefpv',
   type         = input.ACTION_TYPE.Boolean,
   l10n         = 'FPVBody',
   name         = 'Toggle FPV',
   description  = 'Key for toggle FPV',
   defaultValue = false,
}

input.registerAction {
   key          = 'AlwaysRun',
   type         = input.ACTION_TYPE.Boolean,
   l10n         = 'FPVBody',
   name         = 'Toggle AlwaysRun',
   description  = 'assign your usual AlwaysRun Key',
   defaultValue = false,
}

input.registerAction {
   key          = 'Autorun',
   type         = input.ACTION_TYPE.Boolean,
   l10n         = 'FPVBody',
   name         = 'Toggle Autorun',
   description  = 'assign your usual Autorun Key',
   defaultValue = false,
}

I.Settings.registerGroup({
  key              = "Settings_tt_FPVBody",
  page             = "tt_FPV_Body",
  l10n             = "FPVBody",
  name             = "FPVBody settings",
  permanentStorage = true,
  settings = {
       {
           key         = 'togglefpv',
           renderer    = 'inputBinding',
           name        = 'Toggle FPV',
           description = 'Key for toggle FPV',
           default     = 'Z',
           argument    = { type = 'action', key = 'togglefpv' },
       },
	   {
		   key = "ToggleHeadBob",
		   name = "Head bobbing",
		   description = 'Toggle head bobbing on/off',
		   default = false,
           renderer = "checkbox",
       },
	   {
           key         = 'AlwaysRun',
           renderer    = 'inputBinding',
           name        = 'Toggle AlwaysRun',
           description = 'assign your usual AlwaysRun Key',
           default     = 'Caps lock',
           argument    = { type = 'action', key = 'AlwaysRun' },
       },
	   {
           key         = 'Autorun',
           renderer    = 'inputBinding',
           name        = 'Toggle Autorun',
           description = 'assign your usual Autorun Key',
           default     = 'Q',
           argument    = { type = 'action', key = 'Autorun' },
       },
      {
         key = "ChooseRace",
         name = "Select your race",
         default = "Dark Elf",
         renderer = "select",
         argument = { disabled = false,
         l10n = "FPVBody", 
         items = { "Argonian", "Breton", "Dark Elf", "High Elf", "Imperial", "Khajiit", "Nord", "Orc", "Redguard", "Wood Elf" }
         },
      },	
	  {
         key = "ChooseSensitivity",
         name = "Select camera sensitivity",
         default = "Vanilla",
         renderer = "select",
         argument = { disabled = false,
         l10n = "FPVBody", 
         items = { "Vanilla", "Medium", "Sensitive" }
         },
      },
	  {
         key = "ChooseCombatEyePos",
         name = "Select combat and magic camera position",
         default = "Eyes",
         renderer = "select",
         argument = { disabled = false,
         l10n = "FPVBody", 
         items = { "Hands", "Eyes" }
         },
      },	  
	  {
         key = "ChooseFOV",
         name = "Field of view",
         default = "90",
         renderer = "select",
         argument = { disabled = false,
         l10n = "FPVBody", 
         items = { "60", "70", "80", "90", "100", "110" }
         },
      },
	  {
         key = "VerticalInversion",
         name = "Vertical mouse inversion",
         default = "normal",
         renderer = "select",
         argument = { disabled = false,
         l10n = "FPVBody", 
         items = { "normal", "inverted" }
         },
      },
	  {
         key = "ShowHead",
         name = "Show head",
         default = "Yes",
         renderer = "select",
         argument = { disabled = false,
         l10n = "FPVBody", 
         items = { "Yes", "No" }
         },
      },		  
  },
})

return