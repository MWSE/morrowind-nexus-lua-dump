local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local storage = require('openmw.storage')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local _conf = require('scripts.special.conf')
local _widgets = require('scripts.special.widgets')
local _ = require('scripts.special.settings')

local rgb = util.color.rgb
local v2 = util.vector2
local V2 = util.Vector2

local specials = AdvantagesDisadvantages:new()
local specialsSkillMultiplier = 1
local phobias = {}
local phobiaCheckEvery = 2
local phobiaTimeSinceCheck = 0
local phobiaTimeSinceLastTriggerred = 0
local nightlys = {}
local nightlysCheckEvery = 5
local nightlysTimeSinceCheck = 10000000
local insidesOutsides = {}
local insidesCheckEvery = 5
local insidesTimeSinceCheck = 100000
local mainElement = nil
local createMainElement = nil
local editElement = nil
local editElementChangeSelection = nil
local applyElement = nil
local reputationElement = nil

local settings = storage.playerSection('Settings_special')


local function checkSpellExists(abilityId)
   if (core.magic.spells.records)[abilityId] == nil then
      error('Ability ' .. abilityId .. ' not found in game! Please load the plugin special.omwaddon.')
   end
end

local function checkSpecialAbilitiesExist(special)
   if special.abilityId then
      checkSpellExists(special.abilityId)
   end
   if special.abilityIdAtNight then
      checkSpellExists(special.abilityIdAtNight)
   end
   if special.abilityIdWhenInside then
      checkSpellExists(special.abilityIdWhenInside)
   end
   if special.abilityIdWhenOutside then
      checkSpellExists(special.abilityIdWhenOutside)
   end
end

checkSpellExists('special_phobia')

for _, advantage in ipairs(advantages) do
   checkSpecialAbilitiesExist(advantage)
end
for _, disadvantage in ipairs(disadvantages) do
   checkSpecialAbilitiesExist(disadvantage)
end


local function destroyMainElement()
   if not mainElement then return end
   mainElement:destroy()
   mainElement = nil
   I.UI.setMode()
end

local function destroyEditElement()
   if not editElement then return end
   editElement:destroy()
   editElement = nil
   editElementChangeSelection = nil
   I.UI.setMode()
end

local function destroyApplyElement()
   if not applyElement then return end
   applyElement:destroy()
   applyElement = nil
   I.UI.setMode()
end

local function destroyReputationElement()
   if not reputationElement then return end
   reputationElement:destroy()
   reputationElement = nil
   I.UI.setMode()
end



local function skillAdvancementDifficultyFraction()
   local difficulty = math.max(-maxDifficultyPoints, math.min(maxDifficultyPoints, specials:cost()))
   return (difficulty + maxDifficultyPoints) / (maxDifficultyPoints * 2)
end

local function updateDifficultyLine()
   local lineRelativePosition = 0.2 + 0.75 * (1 - skillAdvancementDifficultyFraction())
   local line = lookupLayout(mainElement.layout, { 'second_column', 'difficulty_line' })
   local linePosition = line.props.relativePosition
   line.props.relativePosition = v2(linePosition.x, lineRelativePosition)
end

local function firstColumn()
   local content = ui.content({})
   content:add(background({}))
   content:add(borders(true))
   content:add(textLines({
      lines = { 'ADVANTAGES/DISADVANTAGES' },
      relativeSize = v2(1, 0.08),
   }))
   content:add({
      template = I.MWUI.templates.horizontalLineThick,
      props = {
         anchor = v2(0, 0.5),
         relativePosition = v2(0, 0.08),
      },
   })
   local lines = {}
   for _, advantage in ipairs(specials.advantages) do
      table.insert(lines, advantage.name .. ' [' .. tostring(advantage.cost) .. ' points]')
   end
   for _, disadvantage in ipairs(specials.disadvantages) do
      table.insert(lines, disadvantage.name .. ' [' .. tostring(disadvantage.cost) .. ' points]')
   end
   local scrollableTextLine
   scrollableTextLine = ScrollableTextLines:new({
      lines = lines,
      events = {
         mouseDoubleClick = function(i)
            if i <= #specials.advantages then
               table.remove(specials.advantages, i)
            else
               table.remove(specials.disadvantages, i - #specials.advantages)
            end
            scrollableTextLine:remove(i)
            updateDifficultyLine()
            mainElement:update()
         end,
         onChange = function(_) mainElement:update() end,
      },
      props = {
         relativePosition = v2(0.05, 0.1),
         relativeSize = v2(0.9, 0.85),
         scrollbarRelativeSizeWidth = 0.05,
      },
   })
   content:add(scrollableTextLine:layout())
   return {
      content = content,
      props = {
         relativeSize = v2(0.48, 1),
      },
   }
end

local function secondColumn()
   local content = ui.content({})
   content:add(background({}))
   content:add(borders(true))
   content:add(textLines({
      lines = { 'SKILL', 'ADVANCEMENT', 'FOR CLASS' },
      relativeSize = v2(1, 0.15),
   }))
   content:add({
      template = I.MWUI.templates.horizontalLineThick,
      props = { relativePosition = v2(0, 0.15) },
   })
   content:add({
      template = templates.textNormal,
      props = {
         anchor = v2(1, 0),
         relativePosition = v2(0.65, 0.2),
         text = 'DIFFICULT',
      },
   })
   content:add({
      template = templates.textNormal,
      props = {
         anchor = v2(1, 0.5),
         relativePosition = v2(0.65, 0.575),
         text = 'AVERAGE',
      },
   })
   content:add({
      template = templates.textNormal,
      props = {
         anchor = v2(1, 1),
         relativePosition = v2(0.65, 0.95),
         text = 'EASY',
      },
   })
   content:add({
      type = ui.TYPE.Image,
      props = {
         alpha = 0.5,
         color = util.color.hex('910601'),
         relativePosition = v2(0.7, 0.2),
         relativeSize = v2(0.2, 0.15),
         resource = ui.texture({ path = 'white' }),
      },
   })
   content:add({
      type = ui.TYPE.Image,
      props = {
         alpha = 0.5,
         color = util.color.hex('910601'),
         relativePosition = v2(0.7, 0.8),
         relativeSize = v2(0.2, 0.15),
         resource = ui.texture({ path = 'white' }),
      },
   })
   content:add({
      template = templates.textNormal,
      props = {
         anchor = v2(1, 0.5),
         relativePosition = v2(0.65, 0.35),
         text = 'x3.0',
      },
   })
   content:add({
      template = templates.textNormal,
      props = {
         anchor = v2(1, 0.5),
         relativePosition = v2(0.65, 0.8),
         text = 'x0.3',
      },
   })
   content:add({
      content = ui.content({ borders(true) }),
      props = {
         relativePosition = v2(0.7, 0.2),
         relativeSize = v2(0.2, 0.75),
      },
   })
   local lineRelativePosition = 0.2 + 0.75 * (1 - skillAdvancementDifficultyFraction())
   content:add({
      name = 'difficulty_line',
      type = ui.TYPE.Image,
      props = {
         color = rgb(0.5, 0.5, 0.5),
         anchor = v2(0, 0.5),
         relativePosition = v2(0.68, lineRelativePosition),
         relativeSize = v2(0.24, 0.01),
         resource = ui.texture({ path = 'white' }),
      },
   })
   return {
      name = 'second_column',
      content = content,
      props = {
         relativePosition = v2(0.49, 0),
         relativeSize = v2(0.25, 1),
      },
   }
end






local function changeHitPoints(_)
   ui.showMessage('Changing hit points is not supported yet')






end

local function hitPoint()
   local content = ui.content({})

   content:add(background({}))
   content:add(borders(true))
   content:add(textLines({
      lines = { 'MAX', 'HIT POINTS', 'PER LEVEL' },
      relativePosition = v2(0.1, 0.01),
      relativeSize = v2(0.8, 0.49),
   }))
   content:add(TextButton:new({
      lines = { '+' },
      events = {
         focusChange = function() mainElement:update() end,
         mouseClick = function() changeHitPoints(1) end,
      },
      props = {
         relativePosition = v2(0.1, 0.5),
         relativeSize = v2(0.1, 0.2),
      },
   }):layout())
   content:add(TextButton:new({
      lines = { '-' },
      events = {
         focusChange = function() mainElement:update() end,
         mouseClick = function() changeHitPoints(-1) end,
      },
      props = {
         relativePosition = v2(0.1, 0.7),
         relativeSize = v2(0.1, 0.2),
      },
   }):layout())
   content:add({
      name = 'boxedHitPoints',
      content = ui.content({
         borders(false),
         textLines({ lines = { tostring(specials.maxHp) } }),
      }),
      props = {
         relativePosition = v2(0.3, 0.5),
         relativeSize = v2(0.6, 0.4),
      },
   })
   return {
      name = 'hitPoints',
      content = content,
      props = {
         relativePosition = v2(0.75, 0),
         relativeSize = v2(0.25, 0.32),
      },
   }
end

local function createEditElement(availableSpecials, add)
   destroyMainElement()
   local toGroup = {}
   for _, special in ipairs(availableSpecials) do
      table.insert(toGroup, {
         layout = {
            type = ui.TYPE.Flex,
            props = {
               autoSize = false,
               horizontal = true,
               relativeSize = v2(1, 0),
               size = v2(0, templates.textNormal.props.textSize),
            },
            content = ui.content({
               {
                  template = templates.textNormal,
                  name = 'text',
                  props = {
                     autoSize = false,
                     relativeSize = v2(0.7, 0),
                     size = v2(0, templates.textNormal.props.textSize),
                     text = special.name,
                  },
               },
               {
                  template = templates.textNormal,
                  name = 'cost',
                  props = {
                     autoSize = false,
                     relativeSize = v2(0.3, 0),
                     size = v2(0, templates.textNormal.props.textSize),
                     text = tostring(special.cost),
                     textAlignH = ui.ALIGNMENT.End,
                  },
               },
            }),
         },
         group = special.group,
         data = special,
      })
   end
   local items = group(toGroup)
   local selected = nil
   local scrollable
   scrollable = ScrollableGroups:new({
      items = items,
      events = {
         focusGainNonGroup = function(_, item)
            if not item.data then return end
            local special = item.data
            if not special.description then return end
            local tooltip = lookupLayout(editElement.layout, { 'tooltip' })
            tooltip.content = ui.content({
               background({}),
               borders(true),
               {
                  template = templates.textNormal,
                  props = {
                     autoSize = false,
                     multiline = true,
                     relativePosition = v2(0.05, 0.1),
                     relativeSize = v2(0.9, 0.8),
                     wordWrap = true,
                     text = special.description,
                  },
               },
            })
            editElement:update()
         end,
         focusLossNonGroup = function(_, _)
            local tooltip = lookupLayout(editElement.layout, { 'tooltip' })
            if not tooltip.content then return end
            tooltip.content = nil
            editElement:update()
         end,
         mouseClickNonGroup = function(_, item)
            if type(selected) == "table" then
               lookupLayout(selected.layout, { 'text' }).props.textColor = templates.textNormal.props.textColor
               lookupLayout(selected.layout, { 'cost' }).props.textColor = templates.textNormal.props.textColor
            end
            selected = item
            lookupLayout(selected.layout, { 'text' }).props.textColor = templates.textHeader.props.textColor
            lookupLayout(selected.layout, { 'cost' }).props.textColor = templates.textHeader.props.textColor
         end,
         mouseDoubleClickNonGroup = function(_, item)
            add(item.data)
            destroyEditElement()
            createMainElement()
         end,
         onChange = function(_) editElement:update() end,
      },
      props = {
         lineSizeY = templates.textNormal.props.textSize,
         relativePosition = v2(0.05, 0.05),
         relativeSize = v2(0.9, 0.7),
      },
   })
   editElementChangeSelection = function(offset)

      local newCurrent = scrollable.scrollable.scrollbar.current + offset
      scrollable.scrollable:setCurrent(newCurrent)
      scrollable:update()
      scrollable.options.events.onChange(newCurrent)
   end
   local content = ui.content({})
   content:add(background({}))
   content:add(borders(true))
   content:add(scrollable:layout())
   content:add(TextButton:new({
      lines = { 'EXIT' },
      backgroundOptions = {
         color = rgb(0.1, 0, 0),
      },
      events = {
         focusChange = function() editElement:update() end,
         mouseClick = function()
            destroyEditElement()
            createMainElement()
         end,
      },
      props = {
         relativePosition = v2(0.8, 0.8),
         relativeSize = v2(0.15, 0.15),
      },
   }):layout())
   editElement = ui.create({
      layer = 'Windows',
      content = ui.content({
         {
            content = content,
            props = {
               anchor = v2(0.5, 0.5),
               relativePosition = v2(0.5, 0.5),
               relativeSize = v2(0.5, 0.5),
            },
         },
         {
            name = 'tooltip',
            props = {
               anchor = v2(0.5, 0),
               relativePosition = v2(0.5, 0.77),
               relativeSize = v2(0.5, 0.15),
            },
         },
      }),
      props = { relativeSize = v2(1, 1) },
   })
   I.UI.setMode('Interface', { windows = {} })
end

local function openAddAdvantagesWindow()
   createEditElement(specials:availableAdvantages(), function(a) table.insert(specials.advantages, a) end)
end

local function openAddDisadvantagesWindow()
   createEditElement(specials:availableDisadvantages(), function(a) table.insert(specials.disadvantages, a) end)
end

local function editSpecialAdvantagesButton()
   return TextButton:new({
      lines = { 'ADD', 'SPECIAL', 'ADVANTAGES' },
      backgroundOptions = {},
      events = {
         focusChange = function() mainElement:update() end,
         mouseClick = openAddAdvantagesWindow,
      },
      props = {
         relativePosition = v2(0.75, 0.33),
         relativeSize = v2(0.25, 0.16),
      },
   }):layout()
end

local function editSpecialDisadvantagesButton()
   return TextButton:new({
      lines = { 'ADD', 'SPECIAL', 'DISADVANTAGES' },
      backgroundOptions = {},
      events = {
         focusChange = function() mainElement:update() end,
         mouseClick = openAddDisadvantagesWindow,
      },
      props = {
         relativePosition = v2(0.75, 0.50),
         relativeSize = v2(0.25, 0.16),
      },
   }):layout()
end

local function createReputationElement()
   ui.showMessage('Changing reputation is not yet implemented!')
   return










































































































































































end

local function editReputationButton()
   return TextButton:new({
      lines = { 'EDIT', 'REPUTATION' },
      backgroundOptions = {},
      events = {
         focusChange = function() mainElement:update() end,
         mouseClick = createReputationElement,
      },
      props = {
         relativePosition = v2(0.75, 0.67),
         relativeSize = v2(0.25, 0.16),
      },
   }):layout()
end

local function calculateSpecialsSkillMultiplier(cost)
   if cost >= 0 then
      return 1 + (0.3 - 1) / 30 * cost
   else
      return 3 + (1 - 3) / 30 * (cost + 30)
   end
end

local function isSkillGainMultiplierEnabled()
   return settings:get('enable_special_skill_progression_modifier')
end

I.SkillProgression.addSkillUsedHandler(function(_, params)
   local multiplier = isSkillGainMultiplierEnabled() and 1 or specialsSkillMultiplier
   params.skillGain = params.skillGain * multiplier
   return true
end)





























local function removeExistingSpecials()
   for _, spell in ipairs(types.Actor.spells(self)) do
      if advantagesByAbilityId[spell.id] or disadvantagesByAbilityId[spell.id] then
         print('Removing spell ' .. spell.id)
         types.Actor.spells(self):remove(spell)
      end
   end
end

local function applySpecials()
   removeExistingSpecials()

   print('Applying specials abilities')
   nightlys = {}
   for _, advantage in ipairs(specials.advantages) do
      if advantage.abilityId then
         types.Actor.spells(self):add(advantage.abilityId)
      end
      if advantage.abilityIdAtNight then
         table.insert(nightlys, advantage)
      end
      if advantage.abilityIdWhenInside or advantage.abilityIdWhenOutside then
         table.insert(insidesOutsides, advantage)
      end
   end
   phobias = {}
   for _, disadvantage in ipairs(specials.disadvantages) do
      if disadvantage.abilityId then
         types.Actor.spells(self):add(disadvantage.abilityId)
      end
      if disadvantage.abilityIdAtNight then
         table.insert(nightlys, disadvantage)
      end
      if disadvantage.abilityIdWhenInside or disadvantage.abilityIdWhenOutside then
         table.insert(insidesOutsides, disadvantage)
      end

      local phobiaOf = disadvantage.phobiaOf
      if type(phobiaOf) == "table" then
         table.insert(phobias, disadvantage)
      end
   end

   specialsSkillMultiplier = calculateSpecialsSkillMultiplier(specials:cost())
   print('Applying specials skill multiplier ' .. tostring(specialsSkillMultiplier))


end

local function createApplyElement()
   local content = ui.content({})
   content:add(background({}))
   content:add(borders(true))
   content:add({
      content = ui.content({ borders(false) }),
      props = {
         relativePosition = v2(0.05, 0.05),
         relativeSize = v2(0.9, 0.5),
      },
   })
   local specialsCost = specials:cost()
   local text
   local enableApplyButton
   if specialsCost > maxValidDifficultyPoints or specialsCost < -maxValidDifficultyPoints then
      text = 'The total cost of the special advantages and disadvantages is ' .. tostring(specialsCost) ..
      ' which is outside the valid range [-' .. tostring(maxValidDifficultyPoints) .. ',' ..
      tostring(maxValidDifficultyPoints) .. ']. Do you want to exit or go back to editing?'
      enableApplyButton = false
   else
      text = 'Do you want to apply the special advantages and disadvantages, exit without applying them or go back to editing?'
      enableApplyButton = true
   end
   content:add({
      template = templates.textNormal,
      props = {
         autoSize = false,
         text = text,
         multiline = true,
         wordWrap = true,
         relativePosition = v2(0.1, 0.1),
         relativeSize = v2(0.8, 0.4),
      },
   })
   if enableApplyButton then
      content:add(TextButton:new({
         lines = { 'APPLY' },
         backgroundOptions = {
            color = rgb(0.1, 0, 0),
         },
         events = {
            focusChange = function() applyElement:update() end,
            mouseClick = function()
               applySpecials()
               destroyApplyElement()
            end,
         },
         props = {
            relativePosition = v2(0.1, 0.6),
            relativeSize = v2(0.2, 0.3),
         },
      }):layout())
   end
   content:add(TextButton:new({
      lines = { 'EXIT' },
      backgroundOptions = {
         color = rgb(0.1, 0, 0),
      },
      events = {
         focusChange = function() applyElement:update() end,
         mouseClick = destroyApplyElement,
      },
      props = {
         relativePosition = v2(0.4, 0.6),
         relativeSize = v2(0.2, 0.3),
      },
   }):layout())
   content:add(TextButton:new({
      lines = { 'GO BACK' },
      events = {
         focusChange = function() applyElement:update() end,
         mouseClick = function()
            destroyApplyElement()
            createMainElement()
         end,
      },
      props = {
         relativePosition = v2(0.7, 0.6),
         relativeSize = v2(0.2, 0.3),
      },
   }):layout())
   applyElement = ui.create({
      layer = 'Windows',
      content = content,
      props = {
         anchor = v2(0.5, 0.5),
         relativePosition = v2(0.5, 0.5),
         relativeSize = v2(0.4, 0.3),
      },
   })
   I.UI.setMode('Interface', { windows = {} })
end

local function exitButton()
   return TextButton:new({
      lines = { 'EXIT' },
      backgroundOptions = {
         color = rgb(0.1, 0, 0),
      },
      events = {
         focusChange = function() mainElement:update() end,
         mouseClick = function()
            destroyMainElement()
            createApplyElement()
         end,
      },
      props = {
         relativePosition = v2(0.825, 0.86),
         relativeSize = v2(0.10, 0.12),
      },
   }):layout()
end

createMainElement = function()
   mainElement = ui.create({
      layer = 'Windows',
      name = 'outer',
      type = ui.TYPE.Widget,
      props = {
         anchor = v2(0.5, 0.5),
         relativePosition = v2(0.5, 0.5),
         relativeSize = v2(0.7, 0.8),
      },
      content = ui.content({
         firstColumn(),
         secondColumn(),
         hitPoint(),
         editSpecialAdvantagesButton(),
         editSpecialDisadvantagesButton(),
         editReputationButton(),
         exitButton(),
      }),
   })
   I.UI.setMode('Interface', { windows = {} })
end

local function getOpenSpecialMainElementKey()
   return settings:get('open_special_main_element_key')
end

local function loadPlayerSpecials()
   specials = AdvantagesDisadvantages:new()
   for _, spell in ipairs(types.Actor.spells(self)) do
      local advantage = advantagesByAbilityId[spell.id]
      if advantage then
         table.insert(specials.advantages, advantage)
      else
         local disadvantage = disadvantagesByAbilityId[spell.id]
         if disadvantage then
            table.insert(specials.disadvantages, disadvantage)
         end
      end
   end
   for _, phobia in ipairs(phobias) do
      table.insert(specials.disadvantages, phobia)
   end
end

local testElement = nil

local function onKeyPress(key)
   if not mainElement and input.getKeyName(key.code):lower() == getOpenSpecialMainElementKey():lower() then
      loadPlayerSpecials()
      createMainElement()
   elseif key.code == input.KEY.Escape then
      destroyMainElement()
      destroyEditElement()
      destroyApplyElement()
      destroyReputationElement()
   elseif editElement and key.code == input.KEY.UpArrow then
      editElementChangeSelection(-1)
   elseif editElement and key.code == input.KEY.DownArrow then
      editElementChangeSelection(1)
   elseif editElement and key.code == input.KEY.Enter then

   end
end

local function onMouseWheel(vertical, _)
   if not editElement or not onMouseWheel then return end
   editElementChangeSelection(-vertical)
end

local applyReputationChangesLastRun = 100000000
local applyReputationChangesEvery = 5
local function applyReputationChanges(dt)
   applyReputationChangesLastRun = applyReputationChangesLastRun + dt
   if applyReputationChangesLastRun < applyReputationChangesEvery then return end
   applyReputationChangesLastRun = 0
   for _, actor in ipairs(nearby.actors) do
      if not types.NPC.objectIsInstance(actor) then return end
      for _, factionId in ipairs(types.NPC.getFactions(actor)) do
         if specials.reputation[factionId] then
            actor:sendEvent('SpecialModifyDisposition', { toward = self.id, modifier = specials.reputation[factionId] })
            break
         end
      end
   end
end

local function applyNightlys(dt)
   nightlysTimeSinceCheck = nightlysTimeSinceCheck + dt
   if nightlysTimeSinceCheck < nightlysCheckEvery then return end
   nightlysTimeSinceCheck = 0
   local hour = core.getGameTime() % time.day
   local isNight = hour < 21600 or hour >= 64800
   for _, special in ipairs(nightlys) do
      if isNight and not (types.Actor.spells(self))[special.abilityIdAtNight] then
         types.Actor.spells(self):add(special.abilityIdAtNight)
      elseif not isNight and (types.Actor.spells(self))[special.abilityIdAtNight] then
         types.Actor.spells(self):remove(special.abilityIdAtNight)
      end
   end
end

local function applyInsidesOutsides(dt)
   insidesTimeSinceCheck = insidesTimeSinceCheck + dt
   if insidesTimeSinceCheck < insidesCheckEvery then return end
   insidesTimeSinceCheck = 0
   for _, special in ipairs(insidesOutsides) do
      if self.cell.isExterior then
         if special.abilityIdWhenInside and (types.Actor.spells(self))[special.abilityIdWhenInside] then
            types.Actor.spells(self):remove(special.abilityIdWhenInside)
         end
         if special.abilityIdWhenOutside and not (types.Actor.spells(self))[special.abilityIdWhenOutside] then
            types.Actor.spells(self):add(special.abilityIdWhenOutside)
         end
      else
         if special.abilityIdWhenInside and not (types.Actor.spells(self))[special.abilityIdWhenInside] then
            types.Actor.spells(self):add(special.abilityIdWhenInside)
         end
         if special.abilityIdWhenOutside and (types.Actor.spells(self))[special.abilityIdWhenOutside] then
            types.Actor.spells(self):remove(special.abilityIdWhenOutside)
         end
      end
   end
end

local function onUpdate(dt)
   applyReputationChanges(dt)
   applyNightlys(dt)
   applyInsidesOutsides(dt)

   if not phobias then return end

   if types.Actor.activeSpells(self):isSpellActive('special_phobia') then
      phobiaTimeSinceLastTriggerred = phobiaTimeSinceLastTriggerred + dt

      local willpower = types.Actor.stats.attributes.willpower(self).modified
      local duration = math.max(10, 60 - 0.5 * willpower)

      if phobiaTimeSinceLastTriggerred >= duration then

         types.Actor.activeSpells(self):remove('special_phobia')
      end
   else

      phobiaTimeSinceCheck = phobiaTimeSinceCheck + dt
      if phobiaTimeSinceCheck < phobiaCheckEvery then return end
      phobiaTimeSinceCheck = 0

      local res = nearby.castRay(camera.getPosition(), camera.getPosition() + camera.viewportToWorldVector(v2(0.5, 0.5)) * 2048, { ignore = self })
      if res and res.hitObject and (types.Creature.objectIsInstance(res.hitObject) or types.NPC.objectIsInstance(res.hitObject)) then
         local id = ''
         if types.Creature.objectIsInstance(res.hitObject) then
            id = types.Creature.record(res.hitObject).id
         elseif types.NPC.objectIsInstance(res.hitObject) then
            id = types.NPC.record(res.hitObject).id
         end
         for _, special in ipairs(phobias) do
            for _, phobia in ipairs(special.phobiaOf or {}) do
               if string.find(id:lower(), phobia) then
                  phobiaTimeSinceLastTriggerred = 0
                  print('is spell active:' .. tostring(types.Actor.activeSpells(self):isSpellActive('special_phobia')))
                  if not types.Actor.activeSpells(self):isSpellActive('special_phobia') then
                     local name = nil
                     if types.Creature.objectIsInstance(res.hitObject) then
                        name = types.Creature.record(res.hitObject).name
                     elseif types.NPC.objectIsInstance(res.hitObject) then
                        name = types.NPC.record(res.hitObject).name
                     end
                     ui.showMessage(special.name .. ' triggered by ' .. name)
                     types.Actor.activeSpells(self):add({
                        id = 'special_phobia',
                        name = 'Phobia',
                        effects = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26 },
                        ignoreResistances = true,
                        ignoreSpellAbsorption = true,
                        ignoreReflect = true,
                        stackable = false,
                        temporary = true,
                     })
                  end
               end
            end
         end
      end
   end
end

local function onSave()
   return {
      insidesOutsides = insidesOutsides,
      nightlys = nightlys,
      phobias = phobias,
      reputation = specials.reputation,
      specialsSkillMultiplier = specialsSkillMultiplier,
   }
end

local function onLoad(data)
   if data.insidesOutsides then
      insidesOutsides = insidesOutsides
   end
   if data.nightlys then
      nightlys = data.nightlys
   end
   if data.specialsSkillMultiplier and data.specialsSkillMultiplier ~= 1 then
      specialsSkillMultiplier = data.specialsSkillMultiplier
      print('Applying specials skill multiplier ' .. tostring(specialsSkillMultiplier))
   end
   if data.phobias then
      phobias = data.phobias
   end
   if data.reputation then
      specials.reputation = data.reputation
   end

end

local function checkAndAddSpecial(special)
   checkSpecialAbilitiesExist(special)
   addSpecial(special)
end

return {
   engineHandlers = {
      onKeyPress = onKeyPress,
      onUpdate = onUpdate,
      onMouseWheel = onMouseWheel,
      onSave = onSave,
      onLoad = onLoad,
   },
   eventHandlers = {
      AddSpecial = checkAndAddSpecial,
   },
}
