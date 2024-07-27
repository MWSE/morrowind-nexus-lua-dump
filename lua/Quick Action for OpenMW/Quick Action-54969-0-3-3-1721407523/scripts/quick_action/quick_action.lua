local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local async = require('openmw.async')
local aux_util = require('openmw_aux.util')
local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require("openmw.interfaces")
local MWUI = require('openmw.interfaces').MWUI
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local v2 = util.vector2

local Actor = types.Actor
local Armor = types.Armor
local Clothing = types.Clothing
local GameObject = core.GameObject
local Enchantment = core.Enchantment
local Player = types.Player
local Spell = core.Spell
local Weapon = types.Weapon

local l10n = core.l10n('quick_action')

I.Settings.registerPage({
   key = 'QuickActionPage',
   l10n = 'quick_action',
   name = 'setting_quick_action_page',
   description = 'setting_quick_action_page_description',
})

I.Settings.registerGroup({
   key = 'SettingsQuickAction',
   page = 'QuickActionPage',
   l10n = 'quick_action',
   name = 'setting_quick_action_group',
   description = 'setting_quick_action_group_description',
   permanentStorage = false,
   settings = {
      {
         key = 'toggle',
         name = 'setting_toggle',
         description = 'setting_toggle_description',
         renderer = 'textLine',
         default = 'x',
      },
      {
         key = 'addAction',
         name = 'setting_add_action',
         description = 'setting_add_action_description',
         renderer = 'textLine',
         default = 'n',
      },
      {
         key = 'delAction',
         name = 'setting_del_action',
         description = 'setting_del_action_description',
         renderer = 'textLine',
         default = 'delete',
      },
      {
         key = 'moveUpAction',
         name = 'setting_move_action_up',
         description = 'setting_move_action_up_description',
         renderer = 'textLine',
         default = '\\',
      },
      {
         key = 'moveDownAction',
         name = 'setting_move_action_down',
         description = 'setting_move_action_down_description',
         renderer = 'textLine',
         default = ']',
      },
      {
         key = 'addListing',
         name = 'setting_add_listing',
         description = 'setting_add_listing_description',
         renderer = 'textLine',
         default = 'm',
      },
      {
         key = 'nextListing',
         name = 'setting_next_listing',
         description = 'setting_next_listing_description',
         renderer = 'textLine',
         default = 'z',
      },
      {
         key = 'delListing',
         name = 'setting_del_listing',
         description = 'setting_del_listing_description',
         renderer = 'textLine',
         default = 'end',
      },
      {
         key = 'positionX',
         name = 'setting_position_x',
         description = 'setting_position_x_description',
         renderer = 'number',
         default = 0.5,
         argument = {
            min = 0.0,
            max = 1.0,
         },
      },
      {
         key = 'positionY',
         name = 'setting_position_y',
         description = 'setting_position_y_description',
         renderer = 'number',
         default = 0.5,
         argument = {
            min = 0.0,
            max = 1.0,
         },
      },
      {
         key = 'radiusMul',
         name = 'setting_radius_mul',
         description = 'setting_radius_mul_description',
         renderer = 'number',
         default = 0.15,
      },
      {
         key = 'enableInfoBox',
         name = 'setting_enable_info_box',
         description = 'setting_enable_info_box_description',
         renderer = 'checkbox',
         default = true,
      },
      {
         key = 'enableInfoBoxKeys',
         name = 'setting_enable_info_box_keys',
         description = 'setting_enable_info_box_keys_description',
         renderer = 'checkbox',
         default = true,
      },
      {
         key = 'showControllerKeysInInfoBox',
         name = 'setting_show_controller_keys_in_info_box',
         description = 'setting_show_controller_keys_in_info_box_description',
         renderer = 'checkbox',
         default = false,
      },
      {
         key = 'disablePlayerControls',
         name = 'setting_disable_player_controls',
         description = 'setting_disable_player_controls_description',
         renderer = 'checkbox',
         default = true,
      },
      {
         key = 'resetListings',
         name = 'reset_listings',
         description = 'reset_listings_description',
         renderer = 'checkbox',
         default = false,
      },
   },
})

I.Settings.registerGroup({
   key = 'SettingsQuickActionController',
   page = 'QuickActionPage',
   l10n = 'quick_action',
   name = 'setting_quick_action_controller_group',
   description = 'setting_quick_action_controller_group_description',
   permanentStorage = false,
   settings = {
      {
         key = 'show',
         name = 'setting_controller_show',
         description = 'setting_controller_show_description',
         renderer = 'textLine',
         default = 'DPadUp',
      },
      {
         key = 'close',
         name = 'setting_controller_close',
         description = 'setting_controller_close_description',
         renderer = 'textLine',
         default = 'DPadLeft',
      },
      {
         key = 'select',
         name = 'setting_controller_select',
         description = 'setting_controller_select_description',
         renderer = 'textLine',
         default = 'A',
      },
      {
         key = 'addAction',
         name = 'setting_add_action',
         description = 'setting_add_action_description',
         renderer = 'textLine',
         default = 'Y',
      },
      {
         key = 'delAction',
         name = 'setting_del_action',
         description = 'setting_del_action_description',
         renderer = 'textLine',
         default = 'X',
      },
      {
         key = 'moveUpAction',
         name = 'setting_move_action_up',
         description = 'setting_move_action_up_description',
         renderer = 'textLine',
         default = '',
      },
      {
         key = 'moveDownAction',
         name = 'setting_move_action_down',
         description = 'setting_move_action_down_description',
         renderer = 'textLine',
         default = 'RightStick',
      },
      {
         key = 'addListing',
         name = 'setting_add_listing',
         description = 'setting_add_listing_description',
         renderer = 'textLine',
         default = 'LeftStick',
      },
      {
         key = 'nextListing',
         name = 'setting_next_listing',
         description = 'setting_next_listing_description',
         renderer = 'textLine',
         default = 'DPadRight',
      },
      {
         key = 'delListing',
         name = 'setting_del_listing',
         description = 'setting_del_listing_description',
         renderer = 'textLine',
         default = 'Back',
      },
      {
         key = 'switchToNext',
         name = 'setting_controller_switch_to_next',
         description = 'setting_controller_switch_to_next_description',
         renderer = 'textLine',
         default = 'DPadUp',
      },
      {
         key = 'switchToPrev',
         name = 'setting_controller_switch_to_prev',
         description = 'setting_controller_switch_to_prev_description',
         renderer = 'textLine',
         default = 'DPadDown',
      },
   },
})

local settings = storage.playerSection('SettingsQuickAction')

local function checkbox(settingKey)
   return settings:get(settingKey)
end

local function keyBindingNameFor(settingKey)
   return settings:get(settingKey)
end

local controllerSettings = storage.playerSection('SettingsQuickActionController')

local function controllerButtonNameFor(settingKey)
   return controllerSettings:get(settingKey)
end

local function controllerButtonFor(settingKey)
   local button_name = controllerButtonNameFor(settingKey)
   if button_name == '' then return nil end
   return (input.CONTROLLER_BUTTON)[button_name]
end

local function infoBoxHelper()
   local lookupBindingFor = checkbox('showControllerKeysInInfoBox') and controllerButtonNameFor or keyBindingNameFor

   return lookupBindingFor('addAction') .. ': ' .. l10n('add_action') .. '  ' ..
   lookupBindingFor('delAction') .. ': ' .. l10n('del_action') .. '  ' ..
   lookupBindingFor('addListing') .. ': ' .. l10n('add_list') .. '  ' ..
   lookupBindingFor('delListing') .. ': ' .. l10n('del_list') .. '  ' ..
   lookupBindingFor('nextListing') .. ': ' .. l10n('next_list')
end
































local Listing = {}




function Listing:modifiable(items)
   return { isModifiable = true, items = items }
end

function Listing:unmodifiable(items)
   return { isModifiable = false, items = items }
end

local State = {}










function State:new()
   local self = setmetatable({}, { __index = State })
   self.listings = {}
   self.currentId = '1'
   self.listings[self.currentId] = Listing:modifiable({})
   self.listingsTitles = {}
   table.insert(self.listingsTitles, '1')
   self.selectedItemIndex = nil
   return self
end

function State:from(state)
   local self = State:new()
   self.listingsTitles = state.listingsTitles
   self.listings = state.listings
   self.currentId = state.currentId
   self.selectedItemIndex = state.selectedItemIndex
   return self
end

function State:newListing(title, listing)
   self.listings[title] = listing
   if self.listings[title].isModifiable then
      table.insert(self.listingsTitles, title)
   end
end

function State:setListing(id)
   self.currentId = id
   self.selectedItemIndex = #self.listings[id].items == 0 and nil or 1
end

function State:setFirstListing()
   self:setListing(self.listingsTitles[1])
end

function State:newAndSetListing(title, listing)
   self:newListing(title, listing)
   self:setListing(title)
end

function State:addNextListing()
   local nextTitle = tostring(#self.listingsTitles + 1)
   self:newAndSetListing(nextTitle, Listing:modifiable({}))
   return nextTitle
end

function State:nextListing()
   local nextTitle = self.listingsTitles[1]
   for i, title in ipairs(self.listingsTitles) do
      if title == self.currentId and i + 1 <= #self.listingsTitles then
         nextTitle = self.listingsTitles[i + 1]
         break
      end
   end
   self:setListing(nextTitle)
end

function State:delListing()
   if not self.listings[self.currentId].isModifiable or #self.listingsTitles == 1 then return end
   local removedId = self.currentId
   self:nextListing()
   self.listings[removedId] = nil
   for i = 1, #self.listingsTitles do
      if self.listingsTitles[i] == removedId then
         table.remove(self.listingsTitles, i)
         break
      end
   end
end

local Current = {}





function Current:new(title,
   selectedItemIndex,
   listing)

   local self = setmetatable({}, { __index = Current })
   self.title = title
   self.selectedItemIndex = selectedItemIndex
   self.listing = listing
   return self
end

function Current:selectedItem()
   if self.selectedItemIndex == nil or #self.listing.items < self.selectedItemIndex then
      return nil
   else
      return self.listing.items[self.selectedItemIndex]
   end
end

function State:current()
   return Current:new(
   self.currentId,
   self.selectedItemIndex,
   self.listings[self.currentId])

end

function State:select(selectedItemIndex)
   local current = self:current()
   local numItems = #current.listing.items
   if selectedItemIndex ~= nil and (selectedItemIndex < 1 or selectedItemIndex > numItems) then
      error('selectedItemIndex:' .. tostring(selectedItemIndex) ..
      ' is outside the valid range [' .. tostring(1) ..
      ',' .. tostring(numItems) .. '] of listing ' ..
      current.title)
   end
   self.selectedItemIndex = selectedItemIndex
end

function State:addItemTo(title, item)
   local listing = self.listings[title]
   if not listing then
      print('Warn: attempted to add an item to non existing listing ' .. title)
      return
   end
   if not listing.isModifiable then
      print('Warn: attempted to add an item to non modifiable listing ' .. title)
      return
   end
   table.insert(listing.items, item)
end



function State:removeSelected()
   local current = self:current()
   if not current.listing.isModifiable or
      current.selectedItemIndex == nil or
      #current.listing.items < current.selectedItemIndex then
      return nil
   end
   if #current.listing.items < current.selectedItemIndex then
      print(string.format('Warn: trying to remove ' ..
      'selectedItemIndex:%d from current listing which has only %d items',
      current.selectedItemIndex, #current.listing.items))

      return nil
   end
   local removed = current.listing.items[current.selectedItemIndex]
   table.remove(current.listing.items, current.selectedItemIndex)
   if #current.listing.items == 0 then
      self:select(nil)
   elseif #current.listing.items < current.selectedItemIndex then
      self:select(1)
   end
   return removed
end

function State:moveCurrentUp()
   if self.selectedItemIndex == nil or not self.listings[self.currentId].isModifiable then return end
   local oldPosition = self.selectedItemIndex
   local removed = self:removeSelected()
   if removed == nil then return end

   local position = oldPosition - 1
   if position <= 0 then
      position = #self.listings[self.currentId].items + 1
   end
   table.insert(self.listings[self.currentId].items, position, removed)

   self:select(position)
end

function State:moveCurrentDown()
   if self.selectedItemIndex == nil or not self.listings[self.currentId].isModifiable then return end
   local oldPosition = self.selectedItemIndex
   local removed = self:removeSelected()
   if removed == nil then return end

   local position = oldPosition + 1
   if position > #self.listings[self.currentId].items + 1 then
      position = 1
   end
   table.insert(self.listings[self.currentId].items, position, removed)

   self:select(position)
end





local textSize = MWUI.templates.textNormal.props.textSize
local iconSize = textSize * 2

local state = State:new()

local inputWidget = nil


local function resetListingsIfRequested()
   if checkbox('resetListings') then
      inputWidget = nil
      state = State:new()
      settings:set('resetListings', false)
   end
end

input.bindAction('Zoom3rdPerson', async:callback(function(_, scroll)
   if inputWidget then return 0 else return scroll end
end), {})

input.bindAction('Use', async:callback(function(_, use)
   if inputWidget then return false else return use end
end), {})

local function disablePlayerControl()
   if checkbox('disablePlayerControls') then
      Player.setControlSwitch(self, Player.CONTROL_SWITCH.Controls, false)
      Player.setControlSwitch(self, Player.CONTROL_SWITCH.Fighting, false)
      Player.setControlSwitch(self, Player.CONTROL_SWITCH.Jumping, false)
      Player.setControlSwitch(self, Player.CONTROL_SWITCH.Magic, false)
      Player.setControlSwitch(self, Player.CONTROL_SWITCH.ViewMode, false)
   end
end

local function enablePlayerControl()
   Player.setControlSwitch(self, Player.CONTROL_SWITCH.Controls, true)
   Player.setControlSwitch(self, Player.CONTROL_SWITCH.Fighting, true)
   Player.setControlSwitch(self, Player.CONTROL_SWITCH.Jumping, true)
   Player.setControlSwitch(self, Player.CONTROL_SWITCH.Magic, true)
   Player.setControlSwitch(self, Player.CONTROL_SWITCH.ViewMode, true)
end

local function closeQuickAction()
   if inputWidget and not core.isWorldPaused() then
      inputWidget:destroy()
      inputWidget = nil
   end
   enablePlayerControl()
end






local function background(options)
   return {
      type = ui.TYPE.Container,
      content = ui.content({
         {
            type = ui.TYPE.Image,
            props = {
               alpha = options.alpha,
               color = options.color,
               resource = ui.texture({ path = 'white' }),
               relativeSize = v2(1, 1),
               size = v2(1, 1) * 2,
            },
         },
         {
            external = { slot = true },
            props = {
               relativeSize = v2(1, 1),
            },
         },
      }),
   }
end

local function padding(paddingSize)
   return {
      type = ui.TYPE.Container,
      content = ui.content({
         {
            props = {
               size = paddingSize,
            },
         },
         {
            external = { slot = true },
            props = {
               position = paddingSize,
               relativeSize = util.vector2(1, 1),
            },
         },
         {
            props = {
               position = paddingSize,
               relativePosition = util.vector2(1, 1),
               size = paddingSize,
            },
         },
      }),
   }
end

local selectedItemBackgroundColor = MWUI.templates.textHeader.props.textColor
local itemBackgroundColor = util.color.rgb(0, 0, 0)

local function showQuickAction()
   resetListingsIfRequested()

   if core.isWorldPaused() then return end

   closeQuickAction()

   local current = state:current()


   local relativePosition = v2(settings:get('positionX'), settings:get('positionY'))
   local screenSize = ui.layers[ui.layers.indexOf("HUD")].size

   local radius = math.min(screenSize.x, screenSize.y) * settings:get('radiusMul')
   local angle = 2 * math.pi / #current.listing.items
   local content = ui.content({})
   for i = 1, #current.listing.items do
      local iAngle = i * angle - angle / 2

      local boxContent = ui.content({})
      if current.listing.items[i].texturePath then
         boxContent:add({
            type = ui.TYPE.Image,
            props = {
               alpha = 1,
               color = util.color.rgb(1, 1, 1),
               resource = ui.texture({ path = current.listing.items[i].texturePath }),
               size = v2(iconSize, iconSize),
            },
         })
      else
         boxContent:add({
            type = ui.TYPE.Widget,
            props = {
               size = v2(iconSize, iconSize),
            },
         })
      end

      local position = v2(radius * math.cos(iAngle), radius * math.sin(iAngle))
      local backgroundColor = i == current.selectedItemIndex and selectedItemBackgroundColor or itemBackgroundColor
      content:add({
         template = MWUI.templates.boxSolidThick,
         name = tostring(i),
         props = {
            anchor = v2(0.5, 0.5),
            position = position,
            relativePosition = relativePosition,
         },
         content = ui.content({
            {
               template = background({
                  alpha = 0.5,
                  color = backgroundColor,
               }),
               name = 'background',
               content = ui.content({
                  {
                     template = padding(v2(5, 5)),
                     content = boxContent,
                  },
               }),
            },
         }),
      })
   end

   local flexContent = ui.content({})
   flexContent:add({
      template = MWUI.templates.textNormal,
      props = {
         text = current.title,
         textAlignV = ui.ALIGNMENT.Center,
         textAlignH = ui.ALIGNMENT.Center,
      },
   })
   flexContent:add({
      template = MWUI.templates.horizontalLineThick,
   })
   local item = current:selectedItem()
   flexContent:add({
      name = 'text',
      template = MWUI.templates.textHeader,
      props = {
         text = item and item.name or " ",
         textAlignV = ui.ALIGNMENT.Center,
         textAlignH = ui.ALIGNMENT.Center,
      },
   })
   if current.listing.isModifiable and checkbox('enableInfoBoxKeys') then
      flexContent:add({
         template = MWUI.templates.horizontalLineThick,
      })
      flexContent:add({
         template = MWUI.templates.textNormal,
         props = {
            text = infoBoxHelper(),
            textAlignV = ui.ALIGNMENT.Center,
            textAlignH = ui.ALIGNMENT.Center,
         },
      })
   end

   if checkbox('enableInfoBox') then
      content:add({
         template = MWUI.templates.boxTransparentThick,
         name = 'infoBackground',
         props = {
            anchor = v2(0.5, 0.5),
            position = v2(0, radius + iconSize * 3),
            relativePosition = relativePosition,
         },
         content = ui.content({
            {
               template = padding(v2(5, 5)),
               name = 'padding',
               content = ui.content({
                  {
                     type = ui.TYPE.Flex,
                     name = 'info',
                     content = flexContent,
                     props = {
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                     },
                  },
               }),
            },
         }),
      })
   end

   inputWidget = ui.create({
      layer = 'HUD',
      type = ui.TYPE.Widget,
      content = content,
      props = {
         relativeSize = v2(1, 1),
      },
   })

   disablePlayerControl()
end

local function lookupLayout(widget, names)
   local currentWidget = widget.layout
   for _, name in ipairs(names) do
      if not currentWidget then break end
      currentWidget = currentWidget.content[name]
   end
   return currentWidget
end

local function changeSelection(index)
   if not inputWidget then return end
   local current = state:current()
   if #current.listing.items == 0 then return end
   if index > #current.listing.items then
      print(string.format('Cannot change selection to %d ' ..
      'because it is outside the valid range [1,%d]',
      index,
      #current.listing.items))
      return
   end

   if state.selectedItemIndex ~= nil then
      local oldSelectedLayout = lookupLayout(inputWidget, { tostring(state.selectedItemIndex), 'background' })
      oldSelectedLayout.template = background({ alpha = 0.5, color = itemBackgroundColor })
   end

   local selectedLayout = lookupLayout(inputWidget, { tostring(index), 'background' })
   selectedLayout.template = background({ alpha = 0.5, color = selectedItemBackgroundColor })

   state:select(index)
   current = state:current()

   if checkbox('enableInfoBox') then
      local textLayout = lookupLayout(inputWidget, { 'infoBackground', 'padding', 'info', 'text' })
      textLayout.props.text = current.listing.items[current.selectedItemIndex].name
   end

   inputWidget:update()
end

local function toggleQuickAction()
   if inputWidget then
      closeQuickAction()
      state:setFirstListing()
   else
      showQuickAction()
   end
end

local function getWeaponsInSelfInvectory()
   local res = {}
   for _, weapon in ipairs(Actor.inventory(self):getAll(Weapon)) do
      local weapon_type = Weapon.record(weapon).type
      if weapon_type ~= Weapon.TYPE.Arrow and
         weapon_type ~= Weapon.TYPE.Bolt then
         table.insert(res, weapon)
      end
   end
   return res
end

local function listAddEquipWeaponActions(listingTitle)
   local res = {}
   for _, weapon in ipairs(getWeaponsInSelfInvectory()) do
      table.insert(res, {
         name = Weapon.record(weapon).name,
         texturePath = Weapon.record(weapon).icon,
         action = { type = 'ADD_EQUIP_WEAPON_ACTION', args = Weapon.record(weapon).id },
         listingTitle = listingTitle,
      })
   end
   return res
end

local function listAddEquipSpellActions(listingTitle)
   local res = {}
   for _, spell in pairs(Actor.spells(self)) do
      if spell.type == core.magic.SPELL_TYPE.Power or
         spell.type == core.magic.SPELL_TYPE.Spell then
         table.insert(res, {
            name = spell.name,
            texturePath = spell.effects[1].effect.icon,
            action = { type = 'ADD_EQUIP_SPELL_ACTION', args = spell.id },
            listingTitle = listingTitle,
         })
      end
   end
   return res
end







local function itemNameAndEnchant(item)
   if Armor.objectIsInstance(item) and Armor.record(item).enchant ~= "" then
      local armor = Armor.record(item)
      return {
         name = armor.name,
         texturePath = armor.icon,
         enchant = armor.enchant,
      }
   elseif Clothing.objectIsInstance(item) and Clothing.record(item).enchant ~= "" then
      local clothing = Clothing.record(item)
      return {
         name = clothing.name,
         texturePath = clothing.icon,
         enchant = clothing.enchant,
      }
   elseif Weapon.objectIsInstance(item) and Weapon.record(item).enchant ~= "" then
      local weapon = Weapon.record(item)
      return {
         name = weapon.name,
         texturePath = weapon.icon,
         enchant = weapon.enchant,
      }
   else
      return nil
   end
end

local function listAddEquipEnchantedActions(listingTitle)
   local res = {}
   for _, item in ipairs(Actor.inventory(self):getAll()) do
      local name_and_enchant = itemNameAndEnchant(item)
      if name_and_enchant == nil then goto continue end
      name_and_enchant = name_and_enchant
      local enchantment = (core.magic.enchantments.records)[name_and_enchant.enchant]
      if enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then
         table.insert(res, {
            name = '* ' .. name_and_enchant.name,
            texturePath = name_and_enchant.texturePath,
            action = { type = "ADD_EQUIP_ENCHANTED_ACTION", args = item.recordId },
            listingTitle = listingTitle,
         })
      end
      ::continue::
   end
   return res
end

local function listBasicActions(listingTitle)
   return {
      {
         name = 'add equip weapon action',
         texturePath = 'icons/w/tx_iron_longsword.dds',
         action = { type = "SHOW_EQUIP_WEAPON_ACTIONS", args = nil },
         listingTitle = listingTitle,
      },
      {
         name = 'add equip magic action',
         texturePath = 'icons/k/magicka.dds',
         action = { type = "SHOW_EQUIP_SPELL_ACTIONS", args = nil },
         listingTitle = listingTitle,
      },
      {
         name = 'add equip enchanted item action',
         texturePath = 'icons/k/magic_enchant.dds',
         action = { type = "SHOW_EQUIP_ENCHANTED_ACTIONS", args = nil },
         listingTitle = listingTitle,
      },
      {
         name = 'add switch to hand-to-hand',
         texturePath = 'icons/k/stealth_handtohand.dds',
         action = { type = "ADD_SWITCH_TO_HAND2HAND", args = nil },
         listingTitle = listingTitle,
      },
   }
end

local function select()
   if not inputWidget or core.isWorldPaused() then return end

   local current = state:current()
   local selectedItem = current:selectedItem()
   if selectedItem == nil then return end

   if selectedItem.action.type == "SHOW_EQUIP_WEAPON_ACTIONS" then
      local title = 'Select Weapon to add:'
      state:newAndSetListing(title, Listing:unmodifiable(listAddEquipWeaponActions(selectedItem.listingTitle)))
      showQuickAction()

   elseif selectedItem.action.type == "ADD_EQUIP_WEAPON_ACTION" then
      local weaponId = selectedItem.action.args
      state:addItemTo(selectedItem.listingTitle, {
         name = selectedItem.name,
         texturePath = selectedItem.texturePath,
         action = { type = "EQUIP_TO_RIGHT_HAND", args = weaponId },
      })
      state:setListing(selectedItem.listingTitle)
      showQuickAction()

   elseif selectedItem.action.type == "EQUIP_TO_RIGHT_HAND" then
      local weaponId = selectedItem.action.args
      local weapon = Actor.inventory(self):find(weaponId)

      if weapon == nil then
         print('Selected weapon ' .. selectedItem.name .. ' could not be found (id:' .. tostring(weaponId) .. ')')
      else
         local equipment = Actor.getEquipment(self)
         print('Equipping ' .. selectedItem.name)
         equipment[Actor.EQUIPMENT_SLOT.CarriedRight] = weapon
         Actor.setEquipment(self, equipment)
         Actor.setStance(self, Actor.STANCE.Weapon)
      end
      closeQuickAction()
      state:setFirstListing()

   elseif selectedItem.action.type == "SHOW_EQUIP_SPELL_ACTIONS" then
      local title = 'Select Spell to add:'
      state:newAndSetListing(title, Listing:unmodifiable(listAddEquipSpellActions(selectedItem.listingTitle)))
      showQuickAction()

   elseif selectedItem.action.type == "ADD_EQUIP_SPELL_ACTION" then
      local spellId = selectedItem.action.args
      state:addItemTo(selectedItem.listingTitle, {
         name = selectedItem.name,
         texturePath = selectedItem.texturePath,
         action = { type = "EQUIP_SPELL", args = spellId },
      })
      state:setListing(selectedItem.listingTitle)
      showQuickAction()

   elseif selectedItem.action.type == "EQUIP_SPELL" then
      local spellId = selectedItem.action.args
      local spell = (core.magic.spells.records)[spellId]

      if spell == nil then
         print('Selected Spell ' .. selectedItem.name .. ' could not be found (spellId:' .. tostring(spellId) .. ')')
      else
         print('Equipping ' .. spell.name)
         Actor.clearSelectedCastable(self)
         Actor.setSelectedSpell(self, spell)

         async:newUnsavableGameTimer(10, function()
            Actor.setStance(self, Actor.STANCE.Spell)
         end)
      end
      closeQuickAction()
      state:setFirstListing()


   elseif selectedItem.action.type == "SHOW_EQUIP_ENCHANTED_ACTIONS" then
      local title = 'Select Enchantment to add:'
      state:newAndSetListing(title, Listing:unmodifiable(listAddEquipEnchantedActions(selectedItem.listingTitle)))
      showQuickAction()

   elseif selectedItem.action.type == "ADD_EQUIP_ENCHANTED_ACTION" then
      local itemId = selectedItem.action.args
      state:addItemTo(selectedItem.listingTitle, {
         name = selectedItem.name,
         texturePath = selectedItem.texturePath,
         action = { type = "EQUIP_ENCHANTED_ITEM", args = itemId },
      })
      state:setListing(selectedItem.listingTitle)
      showQuickAction()

   elseif selectedItem.action.type == "EQUIP_ENCHANTED_ITEM" then
      local itemId = selectedItem.action.args
      local item = Actor.inventory(self):find(itemId)

      if item == nil then
         print('Selected Enchanted Item ' .. selectedItem.name .. ' could not be found (id:' .. tostring(itemId) .. ')')
      else
         Actor.clearSelectedCastable(self)
         Actor.setSelectedEnchantedItem(self, item)

         async:newUnsavableGameTimer(10, function()
            Actor.setStance(self, Actor.STANCE.Spell)
         end)
      end
      closeQuickAction()
      state:setFirstListing()

   elseif selectedItem.action.type == 'ADD_SWITCH_TO_HAND2HAND' then
      state:addItemTo(selectedItem.listingTitle, {
         name = selectedItem.name,
         texturePath = selectedItem.texturePath,
         action = { type = "SWITCH_TO_HAND2HAND", args = nil },
      })
      state:setListing(selectedItem.listingTitle)
      showQuickAction()

   elseif selectedItem.action.type == 'SWITCH_TO_HAND2HAND' then
      local equipment = Actor.getEquipment(self)
      equipment[Actor.EQUIPMENT_SLOT.CarriedRight] = nil
      Actor.setEquipment(self, equipment)
      Actor.setStance(self, Actor.STANCE.Weapon)
      closeQuickAction()
      state:setFirstListing()

   else
      error('Unknown action type ' .. tostring(selectedItem.action.type))
      closeQuickAction()
   end
end

local function handleAddAction()
   if not inputWidget or core.isWorldPaused() or not state:current().listing.isModifiable then return end
   local title = 'Select the action to add:'
   state:newAndSetListing(title, Listing:unmodifiable(listBasicActions(state:current().title)))
   showQuickAction()
end

local function handleDelAction()
   if not inputWidget or core.isWorldPaused() or not state:current().listing.isModifiable then return end
   state:removeSelected()
   showQuickAction()
end

local function handleMoveUpAction()
   if not inputWidget or core.isWorldPaused() or not state:current().listing.isModifiable then return end
   state:moveCurrentUp()
   showQuickAction()
end

local function handleMoveDownAction()
   if not inputWidget or core.isWorldPaused() or not state:current().listing.isModifiable then return end
   state:moveCurrentDown()
   showQuickAction()
end

local function handleAddListing()
   if not inputWidget or core.isWorldPaused() or not state:current().listing.isModifiable then return end
   state:addNextListing()
   showQuickAction()
end

local function handleNextListing()
   if not inputWidget or core.isWorldPaused() or not state:current().listing.isModifiable then return end
   state:nextListing()
   showQuickAction()
end

local function handleDelListing()
   if not inputWidget or core.isWorldPaused() or not state:current().listing.isModifiable then return end
   state:delListing()
   showQuickAction()
end

local function handleSequentialSelection(offset)
   if not inputWidget or core.isWorldPaused() then return end
   local current = state:current()
   local numItems = #current.listing.items
   if numItems == 0 then return end
   offset = math.max(math.min(offset, 1), -1)
   local selected = current.selectedItemIndex or 1
   local newSelected = math.fmod(selected + offset, numItems + 1)
   if newSelected == 0 then
      if offset < 0 then
         newSelected = numItems
      else
         newSelected = 1
      end
   end
   changeSelection(newSelected)
end

local function onControllerButtonPress(ctrl)

   if inputWidget == nil and ctrl == controllerButtonFor('show') then
      showQuickAction()

   elseif ctrl == controllerButtonFor('select') then
      select()

   elseif ctrl == controllerButtonFor('close') then
      closeQuickAction()

   elseif ctrl == controllerButtonFor('addAction') then
      handleAddAction()

   elseif ctrl == controllerButtonFor('delAction') then
      handleDelAction()

   elseif ctrl == controllerButtonFor('moveUpAction') then
      handleMoveUpAction()

   elseif ctrl == controllerButtonFor('moveDownAction') then
      handleMoveDownAction()

   elseif ctrl == controllerButtonFor('addListing') then
      handleAddListing()

   elseif ctrl == controllerButtonFor('nextListing') then
      handleNextListing()

   elseif ctrl == controllerButtonFor('delListing') then
      handleDelListing()

   elseif ctrl == controllerButtonFor('switchToNext') then
      handleSequentialSelection(1)

   elseif ctrl == controllerButtonFor('switchToPrev') then
      handleSequentialSelection(-1)

   end
end

local function onKeyPress(key)

   local keyName = input.getKeyName(key.code):lower()

   if keyName == keyBindingNameFor('toggle') then
      toggleQuickAction()

   elseif keyName == keyBindingNameFor('addAction') then
      handleAddAction()

   elseif keyName == keyBindingNameFor('delAction') then
      handleDelAction()

   elseif keyName == keyBindingNameFor('moveUpAction') then
      handleMoveUpAction()

   elseif keyName == keyBindingNameFor('moveDownAction') then
      handleMoveDownAction()

   elseif keyName == keyBindingNameFor('addListing') then
      handleAddListing()

   elseif keyName == keyBindingNameFor('nextListing') then
      handleNextListing()

   elseif keyName == keyBindingNameFor('delListing') then
      handleDelListing()

   end
end

local function onMouseButtonRelease(button)
   if button == 1 then
      select()

   elseif button == 3 then
      closeQuickAction()

   end
end

local function onLoad(savedData, _)
   if savedData then
      state = State:from(savedData)
   end
end

local function onSave()
   if state then
      return state
   end
end

local function onFrame(_)
   if not inputWidget or core.isWorldPaused() then return end
   local current = state:current()
   local y = input.getMouseMoveY()
   local x = input.getMouseMoveX()
   if math.abs(x) + math.abs(y) <= 5 then return end
   local angle = 2 * math.pi / #current.listing.items
   local pointAngle = math.atan(y / x)
   if pointAngle < 0 then
      if y < 0 then
         pointAngle = 2 * math.pi + pointAngle
      else
         pointAngle = math.pi + pointAngle
      end
   elseif x < 0 and y < 0 then
      pointAngle = math.pi + pointAngle
   end
   changeSelection(1 + math.floor(pointAngle / angle))
end

local function onMouseWheel(vertical, _)
   handleSequentialSelection(vertical)
end

return {
   engineHandlers = {
      onControllerButtonPress = onControllerButtonPress,
      onMouseButtonRelease = onMouseButtonRelease,
      onMouseWheel = onMouseWheel,
      onKeyPress = onKeyPress,
      onFrame = onFrame,
      onLoad = onLoad,
      onSave = onSave,
   },
}
