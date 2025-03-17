local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local markTexture = ui.texture({ path = 'textures/menu_map_smark.dds' })

I.Settings.registerRenderer('AttendMeScreenPosition', function(value, set)
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
                           resource = markTexture,
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

I.Settings.registerRenderer('AttendMeList', function(input, set)
   local l10n = core.l10n('AttendMe')

   local value = {}
   for i = 1, #input do
      table.insert(value, input[i])
   end

   local header = {
      type = ui.TYPE.Flex,
      props = {
         horizontal = true,
      },
      content = ui.content({}),
      external = {
         stretch = 1,
      },
   }
   local inputText = ''
   header.content:add({
      template = I.MWUI.templates.box,
      content = ui.content({
         {
            template = I.MWUI.templates.textEditLine,
            events = {
               textChanged = async:callback(function(text)
                  inputText = text:lower()
               end),
            },
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
      template = I.MWUI.templates.box,
      content = ui.content({
         {
            template = I.MWUI.templates.textNormal,
            props = {
               text = l10n('button_add'),
            },
            events = {
               mouseClick = async:callback(function()

                  table.insert(value, inputText)
                  set(value)
               end),
            },
         },
      }),
   })

   local body = {
      type = ui.TYPE.Flex,
      content = ui.content({}),
   }

   local function remove(text)
      for i, v in ipairs(value) do
         if v == text then
            table.remove(value, i)
         end
         return
      end
   end

   for _, text in ipairs(value) do
      body.content:add({
         template = I.MWUI.templates.padding,
      })
      body.content:add({
         type = ui.TYPE.Flex,
         props = {
            horizontal = true,
         },
         content = ui.content({
            {
               template = I.MWUI.templates.textNormal,
               props = { text = text },
            },
            {
               template = I.MWUI.templates.padding,
            },
            {
               template = I.MWUI.templates.box,
               content = ui.content({
                  {
                     template = I.MWUI.templates.textNormal,
                     props = { text = l10n('button_remove') },
                     events = {
                        mouseClick = async:callback(function()
                           remove(text)
                           set(value)
                        end),
                     },
                  },
               }),
            },
         }),
      })
   end

   return {
      type = ui.TYPE.Flex,
      content = ui.content({
         header,
         body,
      }),
   }
end)

I.Settings.registerPage({
   key = 'AttendMe',
   l10n = 'AttendMe',
   name = 'page_name',
   description = 'page_description',
})

I.Settings.registerGroup({
   key = 'SettingsAttendMeHUD',
   page = 'AttendMe',
   l10n = 'AttendMe_HudSettings',
   name = 'group_name',
   permanentStorage = true,
   settings = {
      {
         key = 'enable',
         name = 'enable_name',
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'position',
         name = 'position_name',
         default = util.vector2(0, 0),
         renderer = 'AttendMeScreenPosition',
      },
      {
         key = 'horizontal',
         name = 'horizontal_name',
         default = false,
         renderer = 'checkbox',
      },
      {
         key = 'minimal',
         name = 'minimal_name',
         description = 'minimal_description',
         default = false,
         renderer = 'checkbox',
      },
      {
         key = 'showHealthBar',
         name = 'showHealthBar_name',
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'showMagickaBar',
         name = 'showMagickaBar_name',
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'showFatigueBar',
         name = 'showFatigueBar_name',
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'showBarLabel',
         name = 'showBarLabel_name',
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'showCombatMode',
         name = 'showCombatMode_name',
         description = 'showCombatMode_description',
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'minimizeCombatMode',
         name = 'minimizeCombatMode_name',
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'showDebuff',
         name = 'showDebuff_name',
         description = 'showDebuff_description',
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'minimizeDebuff',
         name = 'minimizeDebuff_name',
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'updateEvery',
         name = 'updateEvery_name',
         description = 'updateEvery_description',
         default = 1,
         renderer = 'number',
         argument = {
            min = 1,
            integer = true,
         },
      },
   },
})
