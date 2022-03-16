local ui = require('openmw.ui')
local async = require('openmw.async')
local util = require('openmw.util')
local input = require('openmw.input')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')
  

local templates = require('scripts.Date.template')

local v2 = util.vector2

local layout = {
  layer = 'Windows',
  type = ui.TYPE.Window,
  template = templates.clockWindow,
  props = {                
    position = v2(0, 0),
    relativePosition = v2(.948, .905),
    anchor = v2(1, 0),
    size = v2(160, 50),    
  },
  events = {           
      windowDrag = async:callback(function(coord, layout)
      local p = layout.props
      -- keep user's changes to window position
      p.position = coord.position
      p.anchor = nil
      p.relativePosition = nil
    end),
  },
  content = ui.content {
    {
      type = ui.TYPE.Text,
      name = "text",      
      template = templates.clockText,
      props = { 	
        multiline = true,
        relativePosition = v2(0.5, 0.5),
        anchor = v2(0.5, 0.5),
        text = calendar.formatGameTime('    %I:%M %p %A, \n %d %B 3E%Y'),        
      },    
    },  
  }
}

local element = ui.create(layout)

local textWidget = layout.content.text

local function updateTime()
  if not element then return end
  textWidget.props.text = calendar.formatGameTime('    %I:%M %p %A, \n %d %B 3E%Y')
  element:update()
end

local timer = nil
local function startUpdating()
  timer = time.runRepeatedly(updateTime, 1 * time.minute, { type = time.GameTime })
end
local function stopUpdating()
  if timer then
    timer()
    timer = nil
  end
end

startUpdating()

return {
  engineHandlers = {
    onKeyPress = function(key)
      if key.code == input.KEY.M then
        if element then
          element:destroy()
          element = nil
          stopUpdating()
        else
          element = ui.create(layout)
          startUpdating()
        end
      end
    end,
  }
}


