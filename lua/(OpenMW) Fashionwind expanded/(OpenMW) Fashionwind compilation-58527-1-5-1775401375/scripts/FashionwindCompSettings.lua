local I     = require('openmw.interfaces')
local input = require('openmw.input')
local ui = require('openmw.ui')
local async = require('openmw.async')

I.Settings.registerRenderer("MasksKeyBox", function(v, set)
	local name = "none"
	if v then name = input.getKeyName(v) end
	return { template = I.MWUI.templates.box, content = ui.content {
		{ template = I.MWUI.templates.padding, content = ui.content {
			{ template = I.MWUI.templates.textEditLine,
				props = { text = name, },
				events = {
					keyPress = async:callback(function(e)
						if e.code == input.KEY.Escape then return end
						set(e.code)
					end),
					},
			},
		}, },
	}, }
end)

I.Settings.registerRenderer("MhiddenKey", function() return {content = ui.content {}} end)

I.Settings.registerRenderer("ScarfKeyBox", function(v, set)
	local name = "none"
	if v then name = input.getKeyName(v) end
	return { template = I.MWUI.templates.box, content = ui.content {
		{ template = I.MWUI.templates.padding, content = ui.content {
			{ template = I.MWUI.templates.textEditLine,
				props = { text = name, },
				events = {
					keyPress = async:callback(function(e)
						if e.code == input.KEY.Escape then return end
						set(e.code)
					end),
					},
			},
		}, },
	}, }
end)

I.Settings.registerRenderer("hiddenscarfKey", function() return {content = ui.content {}} end)

I.Settings.registerRenderer("BPKeyBox", function(v, set)
	local name = "none"
	if v then name = input.getKeyName(v) end
	return { template = I.MWUI.templates.box, content = ui.content {
		{ template = I.MWUI.templates.padding, content = ui.content {
			{ template = I.MWUI.templates.textEditLine,
				props = { text = name, },
				events = {
					keyPress = async:callback(function(e)
						if e.code == input.KEY.Escape then return end
						set(e.code)
					end),
					},
			},
		}, },
	}, }
end)

I.Settings.registerRenderer("BhiddenKey", function() return {content = ui.content {}} end)

I.Settings.registerRenderer("HGKeyBox", function(v, set)
	local name = "none"
	if v then name = input.getKeyName(v) end
	return { template = I.MWUI.templates.box, content = ui.content {
		{ template = I.MWUI.templates.padding, content = ui.content {
			{ template = I.MWUI.templates.textEditLine,
				props = { text = name, },
				events = {
					keyPress = async:callback(function(e)
						if e.code == input.KEY.Escape then return end
						set(e.code)
					end),
					},
			},
		}, },
	}, }
end)

I.Settings.registerRenderer("HGhiddenKey", function() return {content = ui.content {}} end)

I.Settings.registerRenderer("HORKeyBox", function(v, set)
	local name = "none"
	if v then name = input.getKeyName(v) end
	return { template = I.MWUI.templates.box, content = ui.content {
		{ template = I.MWUI.templates.padding, content = ui.content {
			{ template = I.MWUI.templates.textEditLine,
				props = { text = name, },
				events = {
					keyPress = async:callback(function(e)
						if e.code == input.KEY.Escape then return end
						set(e.code)
					end),
					},
			},
		}, },
	}, }
end)

I.Settings.registerRenderer("HORhiddenKey", function() return {content = ui.content {}} end)

I.Settings.registerRenderer("EARKeyBox", function(v, set)
	local name = "none"
	if v then name = input.getKeyName(v) end
	return { template = I.MWUI.templates.box, content = ui.content {
		{ template = I.MWUI.templates.padding, content = ui.content {
			{ template = I.MWUI.templates.textEditLine,
				props = { text = name, },
				events = {
					keyPress = async:callback(function(e)
						if e.code == input.KEY.Escape then return end
						set(e.code)
					end),
					},
			},
		}, },
	}, }
end)

I.Settings.registerRenderer("EARhiddenKey", function() return {content = ui.content {}} end)

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
            default     = 'X',
            argument    = { type = 'action', key = 'GLShow' },
        },
        {
            key         = 'GLChange',
            renderer    = 'inputBinding',
            name        = 'choose goggles key',
            description = 'key to select goggles',
            default     = 'V',
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

-- Player Settings
	{
	key = "MASKBUFFS",
	name = "Enable mask buffs",
	default = false,
    renderer = "checkbox",
    },
	{key = "MAShow",
	default = input.KEY.C,
	renderer = "MasksKeyBox",
	name = "toggle masks key",
	description = "enables or disables masks",
	},
	{key = "MAChange",
	default = input.KEY.V,
	renderer = "MasksKeyBox",
	name = "choose masks key",
	description = "key to select masks",
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
         key         = "SCShow",
		 default = input.KEY.B,
         renderer    = 'ScarfKeyBox',
         name        = "toggle scarves key",
         description = "key to enable/disable scarves",
      },
      {
         key         = "SCChange",
		 default = input.KEY.N,
         renderer    = 'ScarfKeyBox',
         name        = "change scarves key",
         description = "key to choose scarves",
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
         key         = "HGShow",
		 default = input.KEY.H,
         renderer    = 'HGKeyBox',
         name        = "toggle Circlets key",
         description = "key to enable/disable Circlets",
      },
      {
         key         = "HGChange",
		 default = input.KEY.K,
         renderer    = 'HGKeyBox',
         name        = "change Circlets key",
         description = "key to choose Circlets",
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
         key         = "HORShow",
		 default = input.KEY.H,
         renderer    = 'HORKeyBox',
         name        = "toggle Horns key",
         description = "key to enable/disable Horns",
      },
      {
         key         = "HORChange",
		 default = input.KEY.K,
         renderer    = 'HORKeyBox',
         name        = "change Horns key",
         description = "key to choose Horns",
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
         key         = "EARShow",
		 default = input.KEY.H,
         renderer    = 'EARKeyBox',
         name        = "toggle Earrings key",
         description = "key to enable/disable Earrings",
      },
      {
         key         = "EARChange",
		 default = input.KEY.K,
         renderer    = 'EARKeyBox',
         name        = "change Earrings key",
         description = "key to choose Earrings",
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

-- Player Settings

	{key = "BPShow",
	default = input.KEY.Z,
	renderer = "BPKeyBox",
	name = "toggle backpack key",
	description = "Toggle Backpack",
	},
  },	
})

return