local ui = require('openmw.ui')
local input = require("openmw.input")
local async = require('openmw.async')
local I = require("openmw.interfaces")


I.Settings.registerRenderer("inputKeyBox", function(v, set)
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

I.Settings.registerRenderer("hiddenKey", function() return {content = ui.content {}} end)

return
