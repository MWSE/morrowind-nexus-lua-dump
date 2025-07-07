local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')

local l10n = core.l10n('Keytar')
local versionString = "1.2.0"

local luaxp = require('scripts.Keytar.util.luaxp')

-- inputKeySelection by Pharis
I.Settings.registerRenderer('Keytar/inputKeySelection', function(value, set)
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
								if e.code == input.KEY.Escape then return end
								set(e.code)
							end),
						},
					},
				},
			},
		},
	}
end)

--[[ Valid args:
number:			bool
numMin:			number
numMax:			number
numPrecision:	number
callbackGroup:	string
callbackSetting:string
]]
I.Settings.registerRenderer('Keytar/betterTextInput', function(value, set, arg)
	local argCallback = nil
	if arg.callbackGroup and arg.callbackSetting then
		argCallback = function(args)
			core.sendGlobalEvent('UpdateGlobalSettingArg', { groupKey = arg.callbackGroup, settingKey = arg.callbackSetting, args = args })
		end
	end

	local strval
	local argc = {}
	for k, v in pairs(arg) do
		argc[k] = v
	end

	if arg.numFull == nil and argCallback then
		argc.numFull = false
		argCallback(argc)
	end

	if value then
		if arg.number and arg.numPrecision and not arg.numFull then
			local formatString = "%." .. tostring(arg.numPrecision) .. "f"
			strval = string.format(formatString, value)
		else
			strval = tostring(value)
		end
	end
	
	local function update(layout, focusLost)
		if arg.number then
			--local num = tonumber(layout.props.text)
			local parsedExp, err = luaxp.compile(layout.props.text)
			if parsedExp == nil then return
			else
				local num, rerr = luaxp.run(parsedExp)
				if num == nil or type(num) ~= "number" then return
				else
					if arg.numMin and num < arg.numMin then return end
					if arg.numMax and num > arg.numMax then return end
					if focusLost and arg.numPrecision and argCallback then
						argc.numFull = false
						argCallback(argc)
					end
					if num ~= value then set(num) end
				end
			end
		else
			if layout.props.text ~= value then set(layout.props.text) end
		end
	end

	local content = ui.content({
	{
		template = I.MWUI.templates.textEditLine,
		props = {
			text = strval or '',
			autoSize = true
		},
		events = {
			textChanged = async:callback(function(e, layout)
				layout.props.text = e
			end),
			focusGain = async:callback(function()
				-- If number, display with total precision while focused
				if arg.number and arg.numPrecision and argCallback then
					argc.numFull = true
					argCallback(argc)
				end
			end),
			focusLoss = async:callback(function(_, layout)
				update(layout, true)
			end),
			keyPress = async:callback(function(e, layout)
				if e.code == input.KEY.Enter then
					update(layout, false)
				end
			end),
		},
	},
	})
	return { 
		template = I.MWUI.templates.box,
		content = content 
	}
end)

I.Settings.registerRenderer('Keytar/autoDetectButton', function(value, set, arg)
	local wrapper = {
		type = ui.TYPE.Flex,
		content = ui.content({}),
		props = {
			grow = 1,
			size = util.vector2(500, 0),
			arrange = ui.ALIGNMENT.Center,
		}
	}
	local header = {
	   type = ui.TYPE.Flex,
	   content = ui.content({}),
	   props = {
		horizontal = true,
		--grow = 1,
	   }
	}
	header.content:add({
	   template = I.MWUI.templates.boxThick,
	   content = ui.content({
		  {
			template = I.MWUI.templates.padding,
			content = ui.content(
			{
				{
					template = I.MWUI.templates.textNormal,
					props = {
						text = l10n('ButtonAutoDetect'),
					},
					events = {
						mouseClick = async:callback(function()
							core.sendGlobalEvent('DetectBPMStart')
						end),
					},
				}
			})
		  },
	   }),
	})
	header.content:add({
	   template = I.MWUI.templates.padding,
	   external = {
		  grow = 1,
	   },
	})
	header.content:add({
	   template = I.MWUI.templates.boxThick,
	   content = ui.content({
		{
		  template = I.MWUI.templates.padding,
		  content = ui.content(
		  {
			  {
				  template = I.MWUI.templates.textNormal,
				  props = {
					  text = ' ? ',
				  },
				  events = {
					  mouseClick = async:callback(function()
						  set(not value)
					  end),
				  },
			  }
		  })
		},
	 }),
	})

	wrapper.content:add(header)
	if value then
		wrapper.content:add({
			template = I.MWUI.templates.textParagraph,
			props = {
				text = l10n('AutoDetectHelp'),
				size = util.vector2(500, 0),
				anchor = util.vector2(1, 0),
			},
		})
	end
 
	return {
	   type = ui.TYPE.Flex,
	   content = ui.content({
		  wrapper
	   }),
	}
 end)

-- Settings page
I.Settings.registerPage {
    key = 'Keytar',
    l10n = 'Keytar',
    name = 'ConfigTitle',
    description = l10n('ConfigSummary'):gsub('%%{version}', versionString),
}
I.Settings.registerGroup {
    key = 'Settings/Keytar/1_Keybinds',
    page = 'Keytar',
    l10n = 'Keytar',
    name = 'ConfigCategoryKeybinds',
    permanentStorage = true,
    settings = {
        {
            key = 'toggleKeytar',
            renderer = 'Keytar/inputKeySelection',
            name = 'ToggleKeytar',
            default = input.KEY.V
        }
    },
}