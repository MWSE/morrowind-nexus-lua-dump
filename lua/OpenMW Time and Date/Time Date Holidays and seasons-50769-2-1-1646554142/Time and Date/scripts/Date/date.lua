local ui = require('openmw.ui')
local async = require('openmw.async')
local util = require('openmw.util')
local input = require('openmw.input')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')

local templates = require('scripts.Date.template')

Seas = {"Mid Winter", "Late Winter", "Early Spring", "Mid Spring", "Late Spring","Early Summer", "Mid Summer", "Late Summer", "Early Autumn", "Mid Autumn", "Late Autumn", "Early Winter"}

local function FindS()
  local t = calendar.formatGameTime('*t')
  
  if t.month == 1 then S = 1
  return S
  elseif t.month == 2 then S = 2
  return S
  elseif t.month == 3 then S = 3
  return S
  elseif t.month == 4 then S = 4
  return S
  elseif t.month == 5 then S = 5
  return S
  elseif t.month == 6 then S = 6
  return S
  elseif t.month == 7 then S = 7
  return S
  elseif t.month == 8 then S = 8
  return S
  elseif t.month == 9 then S = 9
  return S
  elseif t.month == 10 then S = 10
  return S
  elseif t.month == 11 then S = 11
  return S
  elseif t.month == 12 then S = 12
  return S
  else S = 0
  return S
  end
end

S = FindS()



local v2 = util.vector2

local layout = {
  layer = 'Windows',
  type = ui.TYPE.Window,
  template = templates.clockWindow,
  props = {                
    position = v2(0, 0),
    relativePosition = v2(.115, .835),
    anchor = v2(1, 0),
    size = v2(163, 63),    
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
        text = Seas[S]..calendar.formatGameTime('\n%I:%M %p %A, \n %d %B 3E%Y'),           
      },    
    },  
  }
}

local element = ui.create(layout)

local textWidget = layout.content.text

local function updateTime()
  if not element then return end
  textWidget.props.text = Seas[S]..calendar.formatGameTime('\n%I:%M %p %A, \n %d %B 3E%Y')
  element:update()
end

local timer = nil
local timer2 = nil
local function startUpdating()
  timer = time.runRepeatedly(updateTime, 1 * time.minute, { type = time.GameTime }) 
  timer2 = time.runRepeatedly(FindS, 1 * time.second, { type = time.GameTime })   
end

local function stopUpdating()
  if timer then
    timer()
    timer = nil
  end
end

FindS()
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






