local I     = require("openmw.interfaces")
local input = require('openmw.input')
local ui = require('openmw.ui')
local async = require('openmw.async')


I.Settings.registerRenderer("CloakKeyBox", function(v, set)
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

I.Settings.registerRenderer("hiddenCloakKey", function() return {content = ui.content {}} end)


I.Settings.registerPage {
  key         = "tt_VisibleCloaks",
  l10n        = "VisibleCloaks",
  name        = "Animated cloaks",
  description = "Settings to toggle and change cloaks",
}

I.Settings.registerGroup({
  key              = "Settings_tt_visiblecloaks",
  page             = "tt_VisibleCloaks",
  l10n             = "VisibleCloaks",
  name             = "Cloaks settings",
  permanentStorage = true,
  settings = {
     {
   	 key = "CLOAKNPC",
   	 name = "Enable cloaks for NPC",
   	 default = true,
   	 renderer = "checkbox",
     },
     {
   	 key = "CLOAKBUFF",
   	 name = "Enable cloak buff",
   	 default = false,
   	 renderer = "checkbox",
     },
     {
        key         = "ShowCloak",
   	 default     = input.KEY.Z,
        renderer    = 'CloakKeyBox',
        name        = "toggle cloak key",
        description = "key to enable/disable cloaks",
     },
     {
        key         = "ChangeCloak",
   	 default     = input.KEY.X,
        renderer    = 'CloakKeyBox',
        name        = "change cloak key",
        description = "key to choose cloak",
     },
  },
})

return