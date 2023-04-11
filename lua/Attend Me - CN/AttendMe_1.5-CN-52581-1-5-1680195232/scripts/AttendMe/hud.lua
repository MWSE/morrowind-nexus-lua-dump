local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local auxUtil = require('openmw_aux.util')

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

local hudSettings = storage.playerSection('SettingsAttendMeHUD')

local interval = { template = I.MWUI.templates.interval }

local function insertBetween(list, item)
   local result = {}
   if #list > 0 then
      result[1] = list[1]
   end
   for i = 2, #list do
      table.insert(result, item)
      table.insert(result, list[i])
   end
   return result
end







local renderStat
do
   local bit8 = 255
   local statColors = {
      fatigue = util.color.rgb(0 / bit8, 150 / bit8, 60 / bit8),
      health = util.color.rgb(200 / bit8, 60 / bit8, 30 / bit8),
      magicka = util.color.rgb(53 / bit8, 69 / bit8, 159 / bit8),
   }
   local statTexture = ui.texture({ path = 'textures/menu_bar_gray.dds' })
   local statSize = util.vector2(65, 13)
   local dynamicStats = types.Actor.stats.dynamic

   renderStat = function(actor, key)
      local stat = dynamicStats[key](actor)
      local ratio = stat.current / stat.base

      local label
      if hudSettings:get('showBarLabel') then
         label = {
            type = ui.TYPE.Text,
            props = {
               relativePosition = util.vector2(0.5, 0.5),
               anchor = util.vector2(0.5, 0.5),
               text = ('%i/%i'):format(math.floor(stat.current), math.floor(stat.base)),
               textColor = util.color.rgb(1, 1, 1),
               textSize = statSize.y,
            },
         }
      end
      return {
         template = I.MWUI.templates.boxTransparent,
         content = ui.content({
            {
               props = {
                  size = statSize,
               },
               content = ui.content({
                  {
                     name = 'image',
                     type = ui.TYPE.Image,
                     props = {
                        size = statSize:emul(util.vector2(ratio, 1)),
                        resource = statTexture,
                        color = statColors[key],
                     },
                  },
                  label,
               }),
            },
         }),
      }
   end
end

local renderCombat
do
   local iconCache = {}
   local magicIcon = ui.texture({ path = 'textures/menu_icon_magic_mini.dds' })
   local h2hIcon = ui.texture({ path = 'icons/k/stealth_handtohand.dds' })

   local STANCE = types.Actor.STANCE
   local EQUIPMENT_SLOT = types.Actor.EQUIPMENT_SLOT

   renderCombat = function(actor)
      local icon
      local actorType = types.Actor
      local stance = actorType.stance(actor)
      if stance == STANCE.Spell then
         icon = magicIcon
      elseif stance == STANCE.Weapon then
         local weapon = actorType.equipment(actor, EQUIPMENT_SLOT.CarriedRight)
         if weapon and weapon.type == types.Weapon then
            local weaponIcon = types.Weapon.record(weapon).icon
            iconCache[weaponIcon] = iconCache[weaponIcon] or ui.texture({ path = weaponIcon })
            icon = iconCache[weaponIcon]
         else
            icon = h2hIcon
         end
      end

      return {
         template = I.MWUI.templates.boxTransparent,
         content = ui.content({
            {
               type = ui.TYPE.Image,
               props = {
                  resource = icon,
                  size = util.vector2(36, 36),
               },
            },
         }),
      }
   end
end

local function renderFollower(actor)
   local stats = {}
   if hudSettings:get('showHealthBar') then
      table.insert(stats, renderStat(actor, 'health'))
   end
   if hudSettings:get('showMagickaBar') then
      table.insert(stats, renderStat(actor, 'magicka'))
   end
   if hudSettings:get('showFatigueBar') then
      table.insert(stats, renderStat(actor, 'fatigue'))
   end
   stats = insertBetween(stats, interval)
   local name = (actor.type).record(actor).name
   local shouldRenderCombat = hudSettings:get('showCombatMode') and (
   not hudSettings:get('minimizeCombatMode') or
   types.Actor.stance(actor) ~= types.Actor.STANCE.Nothing)

   local bodyLayout = {
      type = ui.TYPE.Flex,
      props = {
         horizontal = true,
         arrange = ui.ALIGNMENT.Center,
      },
      content = ui.content({
         {
            type = ui.TYPE.Flex,
            content = ui.content(stats),
         },
      }),
   }
   if shouldRenderCombat then
      bodyLayout.content:add(interval)
      bodyLayout.content:add(renderCombat(actor))
   end
   return {
      type = ui.TYPE.Flex,
      props = {
         arrange = ui.ALIGNMENT.Center,
      },
      content = ui.content({
         {
            template = I.MWUI.templates.textHeader,
            props = {
               text = name,
            },
         },
         interval,
         bodyLayout,
      }),
   }
end

local containerTemplate = { type = ui.TYPE.Container }
local followerList = {
   type = ui.TYPE.Flex,
   props = {
      horizontal = hudSettings:get('horizontal'),
      arrange = ui.ALIGNMENT.Center,
   },
}
local followerLayout = {
   layer = 'HUD',
   name = 'RootFollowers',
   template = I.MWUI.templates.boxTransparent,
   props = {},
   content = ui.content({
      {
         name = 'padding',
         template = I.MWUI.templates.padding,
         content = ui.content({
            followerList,
         }),
      },
   }),
}
local followerElement






local separatorLayouts = {}
do
   local function separator(lineTemplate)
      return {
         external = {
            stretch = 1.0,
         },
         props = {
            size = util.vector2(1, 1) * 10,
         },
         content = ui.content({
            {
               template = I.MWUI.templates[lineTemplate],
               props = {
                  relativePosition = util.vector2(0.5, 0.5),
                  anchor = util.vector2(0.5, 0.5),
               },
            },
         }),
      }
   end
   separatorLayouts[true] = separator('verticalLine')
   separatorLayouts[false] = separator('horizontalLine')
end





return function(followers)
   local function updateFollowerList()
      local validFollowers = auxUtil.mapFilter(followers, function(v)
         return v:isValid() and v.count > 0
      end)
      if not hudSettings:get('enable') or #validFollowers == 0 then
         if followerElement then followerElement:destroy() end
         followerElement = nil
         return
      end

      local minimal = hudSettings:get('minimal')
      followerLayout.template = minimal and containerTemplate or I.MWUI.templates.boxTransparent
      followerLayout.content['padding'].template = minimal and containerTemplate or I.MWUI.templates.padding

      local hudPosition = hudSettings:get('position')
      followerLayout.props.relativePosition = hudPosition
      followerLayout.props.anchor = hudPosition
      followerLayout.props.position = (util.vector2(1, 1) - hudPosition * 2):emul(util.vector2(13, 13))

      local horizontal = hudSettings:get('horizontal')
      followerList.props.horizontal = horizontal
      local separator = separatorLayouts[horizontal]

      local content = {}
      for _, follower in ipairs(validFollowers) do
         table.insert(content, renderFollower(follower))
      end
      if not minimal then
         content = insertBetween(content, separator)
      end
      followerList.content = ui.content(content)
      if followerElement then
         followerElement:update()
      else
         followerElement = ui.create(followerLayout)
      end
   end

   hudSettings:subscribe(async:callback(updateFollowerList))

   return {
      updateFollowerList = updateFollowerList,
   }
end
