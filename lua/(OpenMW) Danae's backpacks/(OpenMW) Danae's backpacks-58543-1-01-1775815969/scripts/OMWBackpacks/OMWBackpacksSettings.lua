local I     = require('openmw.interfaces')
local input = require('openmw.input')
local ui = require('openmw.ui')
local async = require('openmw.async')

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

I.Settings.registerPage {
   key = "BACKMOD",
   l10n = "OMWBackpacks",
   name = "Backpacks",
   description = "Settings to toggle Backpacks",
}

I.Settings.registerGroup({
   key = "Settings_tt_FashionBPC",
   page = "BACKMOD",
   l10n = "OMWBackpacks",
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
