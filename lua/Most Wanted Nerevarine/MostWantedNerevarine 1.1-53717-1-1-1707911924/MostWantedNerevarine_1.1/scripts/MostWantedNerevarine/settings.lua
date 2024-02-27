local storage = require('openmw.storage')
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


I.Settings.registerPage({
   key = 'MostWantedNerevarine',
   l10n = 'MostWantedNerevarine',
   name = 'page_name',
   description = 'page_description',
})

I.Settings.registerGroup({
   key = 'SettingsMostWantedNerevarine',
   page = 'MostWantedNerevarine',
   l10n = 'MostWantedNerevarine',
   name = "ui_settings_group",
   permanentStorage = false,
   settings = {
      {
         key = 'hideNoBounty',
         name = "hideNoBounty_name",
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'hideInMenu',
         name = "hideInMenu_name",
         default = false,
         renderer = 'checkbox',
      },
      {
         key = 'hideDetails',
         name = 'hideDetails_name',
         default = false,
         renderer = 'checkbox',
      },
      {
         key = 'iconSize',
         name = 'iconSize_name',
         description = 'iconSize_description',
         default = 48,
         renderer = 'number',
         argument = {
            integer = true,
            min = 1,
         },
      },
      {
         key = 'screenPosition',
         name = 'screenPosition_name',
         default = util.vector2(0, 0),
         renderer = 'MostWantedNerevarine_ScreenPosition',
      },
      {
         key = 'verticalHud',
         name = 'verticalHud_name',
         default = false,
         renderer = 'checkbox',
      },
      {
         key = 'bountyLevelSound',
         name = 'bountyLevelSound_name',
         default = true,
         renderer = 'checkbox',
      },
   },
})

local section = storage.playerSection('SettingsMostWantedNerevarine')

return section
