local async = require('openmw.async')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local ui = require('openmw.ui')

I.Settings.registerRenderer(
	'inputKeySelection',
	function(value, set)
		local name = 'No Key Set'
		if value then
			name = input.getKeyName(value)
		end
		return {
			template = I.MWUI.templates.box,
			content = ui.content {
				{
					template = I.MWUI.templates.padding,
					content = ui.content {
						{
							template = I.MWUI.templates.textEditLine,
							props = {
								text = name,
							},
							events = {
								keyPress = async:callback(function(e)
									if e.code == input.KEY.Escape then 
                                        return
                                    end

									set(e.code)
								end),
							},
						},
					},
				},
			},
		}
	end
)