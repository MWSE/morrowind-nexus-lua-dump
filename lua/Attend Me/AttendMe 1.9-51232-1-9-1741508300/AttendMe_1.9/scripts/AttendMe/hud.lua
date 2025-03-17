local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local auxUtil = require('openmw_aux.util')

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

local magicIcon = ui.texture({
   path = 'textures/menu_icon_magic.dds',
   offset = util.vector2(0, 0),
   size = util.vector2(42, 42),
})
local h2hIcon = ui.texture({ path = 'icons/k/stealth_handtohand.dds' })
local iconCache = {}
local function getEffectIcon(id)
   local effect = core.magic.effects.records[id]
   local path = effect.icon:gsub('^(.*[/\\])(.*)$', '%1b_%2')

   if not iconCache[path] then
      iconCache[path] = ui.texture({ path = path })
   end
   return iconCache[path]
end

local function renderEquipmentIcon(icon, magic, tint)
   local box = {
      props = {
         size = util.vector2(32, 32),
      },
      content = ui.content({}),
   }

   if magic then
      box.content:add({
         type = ui.TYPE.Image,
         props = {
            resource = magicIcon,
            position = util.vector2(-5, -5),
            size = util.vector2(1, 1) * 40,
         },
      })
   end

   box.content:add({
      type = ui.TYPE.Image,
      props = {
         resource = icon,
         size = util.vector2(32, 32),
         color = tint,
      },
   })

   return {
      template = I.MWUI.templates.boxTransparent,
      content = ui.content({ box }),
   }
end

local function renderDisease(spellType)
   local icon
   if spellType == core.magic.SPELL_TYPE.Blight then
      icon = getEffectIcon(core.magic.EFFECT_TYPE.CureBlightDisease)
   else
      icon = getEffectIcon(core.magic.EFFECT_TYPE.CureCommonDisease)
   end
   return renderEquipmentIcon(icon, false, util.color.rgba(1.0, 0.15, 0.15, 1.0))
end

local function getSpellIcon(spell)
   local effect = spell.effects[1]
   if effect then
      return getEffectIcon(effect.effect.id)
   else
      return nil
   end
end

local function getItemIcon(item)
   local itemRecord = (item.type).record(item)
   local path = itemRecord.icon
   if path then
      local isMagical = itemRecord.enchant ~= nil and itemRecord.enchant ~= ''
      if not iconCache[path] then
         iconCache[path] = ui.texture({ path = path })
      end
      return iconCache[path], isMagical
   end
   return h2hIcon
end

local STANCE = types.Actor.STANCE
local EQUIPMENT_SLOT = types.Actor.EQUIPMENT_SLOT

local function renderCombat(actor)
   local icon
   local magic = false

   local actorType = types.Actor
   local stance = actorType.getStance(actor)
   if stance == STANCE.Spell then
      local spell = types.Actor.getSelectedSpell(actor)
      local enchantedItem = types.Actor.getSelectedEnchantedItem(actor)
      icon = spell and getSpellIcon(spell) or (enchantedItem and getItemIcon(enchantedItem)) or magicIcon
      magic = true
   elseif stance == STANCE.Weapon then
      local weapon = actorType.getEquipment(actor, EQUIPMENT_SLOT.CarriedRight)
      if weapon then
         icon, magic = getItemIcon(weapon)
      else
         icon = h2hIcon
         magic = false
      end
   end

   return renderEquipmentIcon(icon, magic)
end

local function getDebuff(actor)
   local disease
   for _, spell in pairs(types.Actor.spells(actor)) do
      if spell.type == core.magic.SPELL_TYPE.Blight then
         disease = spell
         break
      elseif spell.type == core.magic.SPELL_TYPE.Disease then
         disease = spell
      end
   end

   if disease then
      return disease, nil
   end

   local effect
   for _, active in pairs(types.Actor.activeEffects(actor)) do
      if active.id == core.magic.EFFECT_TYPE.DamageAttribute then
         effect = active
         break
      elseif active.id == core.magic.EFFECT_TYPE.DamageSkill then
         effect = active
      end
   end

   return nil, effect
end

local function renderDebuff(disease, effect)
   if disease then
      return renderDisease(disease.type)
   elseif effect then
      return renderEquipmentIcon(getEffectIcon(effect.id), false)
   else
      return renderEquipmentIcon(nil, false)
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
   local iconsContainer = {
      type = ui.TYPE.Flex,
      props = {
         horizontal = false,
      },
      content = ui.content({}),
   }

   if hudSettings:get('showCombatMode') then
      if
not hudSettings:get('minimizeCombatMode') or
         types.Actor.getStance(actor) ~= types.Actor.STANCE.Nothing then

         iconsContainer.content:add(renderCombat(actor))
      end
   end

   if hudSettings:get('showDebuff') then
      local disease, effect = getDebuff(actor)
      if disease or effect or not hudSettings:get('minimizeDebuff') then
         if #iconsContainer.content > 0 then
            iconsContainer.content:add(interval)
         end
         iconsContainer.content:add(renderDebuff(disease, effect))
      end
   end

   if #iconsContainer.content > 0 then
      bodyLayout.content:add(interval)
      bodyLayout.content:add(iconsContainer)
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

local function forceUpdate(followers)
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
   local paddingLayout = followerLayout.content['padding']
   paddingLayout.template = minimal and containerTemplate or I.MWUI.templates.padding

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

local lastFollowers = {}
hudSettings:subscribe(async:callback(function() forceUpdate(lastFollowers) end))

local frameCounter = math.floor(math.random() * math.max(1, hudSettings:get('updateEvery')))
local function update(followers)
   lastFollowers = followers
   if frameCounter == 0 then
      forceUpdate(followers)
   end
   frameCounter = frameCounter + 1
   if frameCounter >= math.max(1, hudSettings:get('updateEvery')) then
      frameCounter = 0
   end
end

return {
   forceUpdate = forceUpdate,
   update = update,
}
