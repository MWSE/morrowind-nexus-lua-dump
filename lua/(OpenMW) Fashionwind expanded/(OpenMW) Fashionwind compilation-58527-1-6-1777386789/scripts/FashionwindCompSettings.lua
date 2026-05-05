local I     = require('openmw.interfaces')
local input = require('openmw.input')
local ui = require('openmw.ui')
local async = require('openmw.async')

I.Settings.registerPage({
    key         = 'FASHIONWINDCOMP',
    l10n        = 'Fashionwind',
    name        = 'Fashionwind Compilation',
    description = 'Settings to toggle and change glasses, masks, scarves and backpacks',
})

input.registerAction {
    key          = 'GLShow',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
    name         = 'Toggle glasses',
    description  = 'Key to toggle glasses',
    defaultValue = false,
}

input.registerAction {
    key          = 'GLChange',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
    name         = 'Change glasses',
    description  = 'Key to select glasses',
    defaultValue = false,
}

input.registerAction {
    key          = 'MAShow',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
    name         = 'toggle masks',
    description  = 'enables or disables masks',
    defaultValue = false,
}

input.registerAction {
    key          = 'MAChange',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
    name         = 'choose masks',
    description  = 'key to select masks',
    defaultValue = false,
}

input.registerAction {
    key          = 'SCShow',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
    name         = 'toggle scarves key',
    description  = 'key to enable/disable scarves',
    defaultValue = false,
}

input.registerAction {
    key          = 'SCChange',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
    name         = 'change scarves key',
    description  = 'key to choose scarves',
    defaultValue = false,
}

input.registerAction {
    key          = 'HGShow',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
    name         = 'toggle Circlets key',
    description  = 'key to enable/disable Circlets',
    defaultValue = false,
}

input.registerAction {
    key          = 'HGChange',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
    name         = 'change Circlets key',
    description  = 'key to choose Circlets',
    defaultValue = false,
}

input.registerAction {
    key          = 'HORShow',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
    name         = "toggle Horns key",
    description  = "key to enable/disable Horns",
    defaultValue = false,
}

input.registerAction {
    key          = 'HORChange',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
    name         = "change Horns key",
    description  = "key to choose Horns",
    defaultValue = false,
}

input.registerAction {
    key          = 'EARShow',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
    name         = "toggle Earrings key",
    description  = "key to enable/disable Earrings",
    defaultValue = false,
}

input.registerAction {
    key          = 'EARChange',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
    name         = "change Earrings key",
    description  = "key to choose Earrings",
    defaultValue = false,
}

input.registerAction {
    key          = 'BPShow',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'Fashionwind',
	name 		 = "toggle backpack key",
	description  = "Toggle Backpack",
    defaultValue = false,
}

I.Settings.registerGroup({
    key              = 'Settings_tt_FashionGl',   
    page             = 'FASHIONWINDCOMP',             
    l10n             = 'Fashionwind',
    name             = 'Goggles settings',
    permanentStorage = true,
    settings = {
        {
            key         = 'GLShow',
            renderer    = 'inputBinding',
            name        = 'toggle goggles key',
            description = 'enables or disables goggles',
            default     = 'Q',
            argument    = { type = 'action', key = 'GLShow' },
        },
        {
            key         = 'GLChange',
            renderer    = 'inputBinding',
            name        = 'choose goggles key',
            description = 'key to select goggles',
            default     = 'W',
            argument    = { type = 'action', key = 'GLChange' },
        },
    },
})

I.Settings.registerGroup({
   key = "Settings_tt_FashionMA",
   page = "FASHIONWINDCOMP",
   l10n = "Fashionwind",
   name = "Masks settings",
   permanentStorage = true,
   settings = {
		{
		key = "MASKBUFFS",
		name = "Enable mask buffs",
		default = false,
		renderer = "checkbox",
		},
        {
            key         = 'MAShow',
            renderer    = 'inputBinding',
			name         = 'toggle masks',
			description  = 'enables or disables masks',
            default     = 'E',
            argument    = { type = 'action', key = 'MAShow' },
        },
        {
            key         = 'MAChange',
            renderer    = 'inputBinding',
			name         = 'choose masks',
			description  = 'key to select masks',
            default     = 'R',
            argument    = { type = 'action', key = 'MAChange' },
        },
    },
})

I.Settings.registerGroup({
   key              = "Settings_tt_fashionwind_scarves_ui",
   page             = "FASHIONWINDCOMP",
   l10n             = "Fashionwind",
   name             = "Scarves settings",
   permanentStorage = true,
   settings = {
	  {
	  key = "SKARFBUFFS",
	  name = "Enable skarf buffs",
	  default = false,
      renderer = "checkbox",
	  },
        {
            key         = 'SCShow',
            renderer    = 'inputBinding',
			name         = 'toggle scarves key',
			description  = 'key to enable/disable scarves',
            default     = 'T',
            argument    = { type = 'action', key = 'SCShow' },
        },
        {
            key         = 'SCChange',
            renderer    = 'inputBinding',
			name         = 'change scarves key',
			description  = 'key to choose scarves',
            default     = 'Y',
            argument    = { type = 'action', key = 'SCChange' },
        },
   },
})

I.Settings.registerGroup({
   key              = "Settings_tt_fashionwindHG",
   page             = "FASHIONWINDCOMP",
   l10n             = "Fashionwind",
   name             = "Circlets settings",
   permanentStorage = true,
   settings = {
	  {
		 key = "HGBUFFS",
		 name = "Enable Circlets buffs",
		 default = false,
		 renderer = "checkbox",
      },
        {
            key         = 'HGShow',
            renderer    = 'inputBinding',
			name         = 'toggle Circlets key',
			description  = 'key to enable/disable Circlets',
            default     = 'U',
            argument    = { type = 'action', key = 'HGShow' },
        },
        {
            key         = 'HGChange',
            renderer    = 'inputBinding',
			name         = 'change Circlets key',
			description  = 'key to choose Circlets',
            default     = 'I',
            argument    = { type = 'action', key = 'HGChange' },
        },
   },
})

I.Settings.registerGroup({
   key              = "Settings_tt_fashionwindANTL",
   page             = "FASHIONWINDCOMP",
   l10n             = "Fashionwind",
   name             = "Horns settings",
   permanentStorage = true,
   settings = {
	  {
		 key = "HORBUFFS",
		 name = "Enable Horns buffs",
		 default = false,
		 renderer = "checkbox",
      },
        {
            key         = 'HORShow',
            renderer    = 'inputBinding',
			name         = "toggle Horns key",
			description  = "key to enable/disable Horns",
            default     = 'O',
            argument    = { type = 'action', key = 'HORShow' },
        },
        {
            key         = 'HORChange',
            renderer    = 'inputBinding',
			name         = "change Horns key",
			description  = "key to choose Horns",
            default     = 'P',
            argument    = { type = 'action', key = 'HORChange' },
        },
   },
})

I.Settings.registerGroup({
   key              = "Settings_tt_fashionwindEAR",
   page             = "FASHIONWINDCOMP",
   l10n             = "Fashionwind",
   name             = "Earrings settings",
   permanentStorage = true,
   settings = {
	  {
		 key = "EARBUFFS",
		 name = "Enable Earrings buffs",
		 default = false,
		 renderer = "checkbox",
      },
        {
            key         = 'EARShow',
            renderer    = 'inputBinding',
			name         = "toggle Earrings key",
			description  = "key to enable/disable Earrings",
            default     = 'A',
            argument    = { type = 'action', key = 'EARShow' },
        },
        {
            key         = 'EARChange',
            renderer    = 'inputBinding',
			name         = "change Earrings key",
			description  = "key to choose Earrings",
            default     = 'S',
            argument    = { type = 'action', key = 'EARChange' },
        },
   },
})

I.Settings.registerGroup({
   key = "Settings_tt_FashionBPC",
   page = "FASHIONWINDCOMP",
   l10n = "Fashionwind",
   name = "Backpacks settings",
   permanentStorage = true,
   settings = {
        {
            key         = 'BPShow',
            renderer    = 'inputBinding',
			name = "toggle backpack key",
			description = "Toggle Backpack",
            default     = 'D',
            argument    = { type = 'action', key = 'BPShow' },
        },
  },	
})

return
