local util = require('openmw.util')
local ui = require('openmw.ui')
local async = require('openmw.async')
local I = require('openmw.interfaces')

I.Settings.registerRenderer(
'MostWantedNerevarine_ScreenPosition',
function(value, set)
   local buttonSize = util.vector2(20, 20)
   local containerSize = util.vector2(50, 50)
   local update = async:callback(function(e)
      if e.button ~= 1 then return end
      local relativeOffset = (e.offset - buttonSize / 2):ediv(containerSize)
      local clampedOffset = util.vector2(
      util.clamp(relativeOffset.x, 0, 1),
      util.clamp(relativeOffset.y, 0, 1))

      set(clampedOffset)
   end)
   return {
      template = I.MWUI.templates.box,
      content = ui.content({
         {
            props = {
               size = containerSize + buttonSize,
            },
            content = ui.content({
               {
                  template = I.MWUI.templates.borders,
                  props = {
                     anchor = value,
                     relativePosition = value,
                     size = buttonSize,
                  },
                  content = ui.content({
                     {
                        type = ui.TYPE.Image,
                        props = {
                           resource = ui.texture({ path = 'textures/menu_map_smark.dds' }),
                           relativeSize = util.vector2(1, 1),
                           color = util.color.rgb(202 / 255, 165 / 255, 96 / 255),
                        },
                     },
                  }),
               },
            }),
            events = {
               mouseMove = update,
               mousePress = update,
            },
         },
      }),
   }
end)
