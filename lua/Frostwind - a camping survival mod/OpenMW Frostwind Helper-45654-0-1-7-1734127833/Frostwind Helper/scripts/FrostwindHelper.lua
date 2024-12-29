local ui = require('openmw.ui')
local async = require('openmw.async')
local util = require('openmw.util')
local input = require('openmw.input')
local types = require('openmw.types')
local self = require('openmw.self')
local Player = require('openmw.types').Player

local templates = require('scripts.FW_template')

strExplosure = {"Comfortable", "Warm", "Chilly", "Cold", "Very cold", "Freezing", "Dead freezing"}
strWetness = {"Dry", "Damp", "Wet", "Soaked"}
strSleep = {"Rested", "Need sleep"}

local v2 = util.vector2

-- handle settings
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerPage({
   key = 'FrostwindHelper',
   l10n = 'FrostwindHelper',
   name = 'name',
   description = 'description',
})

local windowPosX = 0.93
local windowPosY = 0.835

I.Settings.registerGroup({
   key = 'Settings_FrostwindHelper',
   page = 'FrostwindHelper',
   l10n = 'FrostwindHelper',
   name = 'group_name',
   permanentStorage = true,
   settings = {
--  	{
--         key = 'windowPosX',
--         default = windowPosX,
--         renderer = 'number',
--         name = 'windowPosX_name',
--         argument = {
--            min = 0.0,
--            max = 1.0,
--         },
--	},
--	{
--         key = 'windowPosY',
--         default = windowPosY,
--         renderer = 'number',
--         name = 'windowPosY_name',
--         argument = {
--            min = 0.0,
--            max = 1.0,
--         },
--      },
   },
})

local layout = {
  layer = 'Windows',
  type = ui.TYPE.Window,
  template = templates.clockWindow,
  props = {                
    position = v2(0, 0),
--    relativePosition = v2(.115, .835),
    relativePosition = v2(windowPosX, windowPosY),
    anchor = v2(1, 0),
    size = v2(160, 63),    
  },
--  events = {           
--      windowDrag = async:callback(function(coord, layout)
--      local p = layout.props
      -- keep user's changes to window position
--      p.position = coord.position
--      p.anchor = nil
--      p.relativePosition = nil
--    end),
--  },
  content = ui.content {
    {
      type = ui.TYPE.Text,
      name = "text",      
      template = templates.clockText,
      props = {   
        multiline = true,
        relativePosition = v2(0.5, 0.5),
        anchor = v2(0.5, 0.5),
	text = "text",
      },    
    },  
  }
}

local element = ui.create(layout)
local textWidget = layout.content.text

local settingsGroup = storage.playerSection('Settings_FrostwindHelper')
-- update
local function updateSettings()
--	windowPosX = settingsGroup:get('windowPosX')
--	windowPosY = settingsGroup:get('windowPosY')

--	local p = layout.props
--	p.position = v2(windowPosX, windowPosY)
--	p.anchor = nil
--	p.relativePosition = nil
end

local function init()
    updateSettings()
end

settingsGroup:subscribe(async:callback(updateSettings))


local function updateTime()
  if not element then 
	return 
  end

	local playerInventory = types.Actor.inventory(self.object)
	local wetness = playerInventory:countOf("FH_Wetness")
	local exposure = playerInventory:countOf("FH_Exposure")

--  local wetness = types.Actor.inventory(self):countOf("FH_Wetness")
--	local wetness = Player.inventory(self):countOf("FH_Wetness")
--  local exposure = types.Actor.inventory(self):countOf("FH_Exposure")
--	local exposure = Player.inventory(self):countOf("FH_Exposure")

  if wetness > 0 and exposure > 0 then
	textWidget.props.text = strExplosure[exposure].."\n"..strWetness[wetness].."\n"
  else
	textWidget.props.text = ""
  end
  element:update()
end

return {
  engineHandlers = {
	-- init settings
	onActive = init,

	-- enable/disable window
	onKeyPress = function(key)
		if key.code == input.KEY.M then
			if element then
				element:destroy()
				element = nil
			else
				element = ui.create(layout)
			end
		end
	end,
	
	onUpdate = function(dt)
		if element then
			updateTime()
		end
	end,
  }
}
