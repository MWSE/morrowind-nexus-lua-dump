local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local table = _tl_compat and _tl_compat.table or table; local async = require('openmw.async')
local auxUi = require('openmw_aux.ui')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local _utils = require('scripts.special.utils')

local v2 = util.vector2
local V2 = util.Vector2

sandColor = I.MWUI.templates.textNormal.props.textColor
lightSandColor = I.MWUI.templates.textHeader.props.textColor

local function calculateTextSize()
   local screenSize = ui.layers[ui.layers.indexOf('Windows')].size
   return screenSize.y / 35
end

local function calculateTextNormalTemplate()
   local textTemplate = auxUi.deepLayoutCopy(I.MWUI.templates.textNormal)
   textTemplate.props.textSize = calculateTextSize()
   textTemplate.props.textColor = sandColor
   return textTemplate
end

local function calculateTextHeaderTemplate()
   local textTemplate = auxUi.deepLayoutCopy(calculateTextNormalTemplate())
   textTemplate.props.textColor = lightSandColor
   return textTemplate
end

templates = {
   sandImage = {
      type = ui.TYPE.Image,
      props = {
         alpha = 0.8,
         color = sandColor,
         resource = ui.texture({ path = 'white' }),
      },
   },

   textHeader = calculateTextHeaderTemplate(),
   textNormal = calculateTextNormalTemplate(),
}

BackgroundOptions = {}




function background(options)
   return {
      type = ui.TYPE.Image,
      props = {
         alpha = options.alpha or 0.9,
         color = options.color or util.color.rgb(0, 0, 0),
         relativeSize = v2(1, 1),
         resource = ui.texture({ path = 'white' }),
      },
   }
end

function borders(thick)
   return {
      template = thick and I.MWUI.templates.bordersThick or I.MWUI.templates.borders,
      props = { relativeSize = v2(1, 1) },
   }
end










function textLines(options)
   local content = ui.content({})
   for i, line in ipairs(options.lines) do
      content:add({
         name = tostring(i),
         template = templates.textNormal,
         props = {
            text = line,
            textColor = options.color,
         },
      })
   end
   return {
      type = ui.TYPE.Flex,
      name = options.flexName or 'flex',
      props = {
         autoSize = false,
         arrange = ui.ALIGNMENT.Center,
         align = ui.ALIGNMENT.Center,
         relativePosition = options.relativePosition or v2(0, 0),
         relativeSize = options.relativeSize or v2(1, 1),
         size = options.size or v2(0, 0),
      },
      content = content,
   }
end

TextButtonEvents = {}






TextButtonProperties = {}





TextButtonOptions = {}







TextButton = {}





function TextButton:new(options)
   local self = setmetatable({}, { __index = TextButton })
   self.options = options
   local unfocusedColor = options.normalTextColor or sandColor
   self.textLines = textLines({
      color = unfocusedColor,
      lines = options.lines,
   })
   return self
end

function TextButton:changeTextColor(color)
   for i, _ in ipairs(self.options.lines) do
      lookupLayout(self.textLines, { tostring(i) }).props.textColor = color
   end
   if self.options.events.focusChange then self.options.events.focusChange() end
end

function TextButton:layout()
   local content = ui.content({})
   if self.options.backgroundOptions ~= nil then
      content:add(background(self.options.backgroundOptions))
   end
   content:add(borders(true))
   content:add(self.textLines)
   local events = {}
   local unfocusedColor = self.options.normalTextColor or sandColor
   events.focusGain = async:callback(self.options.events.focusGain or function() self:changeTextColor(lightSandColor) end)
   events.focusLoss = async:callback(self.options.events.focusLoss or function() self:changeTextColor(unfocusedColor) end)
   if self.options.events and self.options.events.mouseClick then
      events.mouseClick = async:callback(self.options.events.mouseClick)
   end
   return {
      content = content,
      events = events,
      props = self.options.props,
   }
end

ScrollbarProperties = {}




ScrollbarEvents = {}



ScrollbarOptions = {}





Scrollbar = {}















function Scrollbar:new(options)
   local self = setmetatable({}, { __index = Scrollbar })
   options.size = options.size or 1
   options.events = options.events or {}
   options.events.onChange = options.events.onChange or function(_) end
   options.props = options.props or {}
   self.options = options
   self.buttonRelativeSizeY = 0.1
   self.scrollerAreaRelativeSizeY = 1 - 2 * self.buttonRelativeSizeY
   self.scrollerRelativeSizeY = self.scrollerAreaRelativeSizeY / self.options.size
   self.current = 1
   return self
end

function Scrollbar:updateScrollerRelativePosition()
   if not self.scroller then return end
   local scrollerRelativePositionY = self.buttonRelativeSizeY +
   (self.current - 1) * self.scrollerRelativeSizeY
   self.scroller.props = self.scroller.props or {}
   self.scroller.props.relativePosition = v2(0, scrollerRelativePositionY)
end

function Scrollbar:updateScroller()
   self.scroller.props = self.scroller.props or {}
   self.scroller.props.relativeSize = v2(1, self.scrollerRelativeSizeY)
   self:updateScrollerRelativePosition()
end

function Scrollbar:update()
   self.scrollerRelativeSizeY = self.scrollerAreaRelativeSizeY / self.options.size

   if self.options.size <= 1 then return end

   if self._layout and self._layout.content and #self._layout.content > 1 then
      self:updateScroller()
      return
   end

   self._layout.content = ui.content({})


   self._layout.content:add({
      template = I.MWUI.templates.borders,
      props = { relativeSize = v2(1, 1) },
   })


   self.upButton = {
      template = templates.sandImage,
      events = {
         mouseClick = async:callback(function()
            self:decrease()
            self.options.events.onChange(self.current)
         end),
      },
      props = {
         relativeSize = v2(1, self.buttonRelativeSizeY),
      },
   }
   self._layout.content:add(self.upButton)


   self.scroller = { template = templates.sandImage }
   self._layout.content:add(self.scroller)
   self:updateScroller()


   local downButtonRelativePositionY = self.buttonRelativeSizeY + self.scrollerAreaRelativeSizeY
   self.downButton = {
      template = templates.sandImage,
      events = {
         mouseClick = async:callback(function()
            self:increase()
            self.options.events.onChange(self.current)
         end),
      },
      props = {
         relativePosition = v2(0, downButtonRelativePositionY),
         relativeSize = v2(1, self.buttonRelativeSizeY),
      },
   }
   self._layout.content:add(self.downButton)
end

function Scrollbar:changeSize(newSize)
   self.options.size = math.max(1, newSize)
   self.current = math.min(self.options.size, self.current)
   self:update()
end

function Scrollbar:decreaseSize()
   self:changeSize(self.options.size - 1)
end

function Scrollbar:setCurrent(newCurrent)
   self.current = math.max(1, math.min(self.options.size, newCurrent))
   self:updateScrollerRelativePosition()
end

function Scrollbar:increase() self:setCurrent(self.current + 1) end
function Scrollbar:decrease() self:setCurrent(self.current - 1) end

function Scrollbar:layout()
   self._layout = {
      props = self.options.props,
   }
   self:update()
   return self._layout
end

ScrollableTextLinesProperties = {}





ScrollableTextLinesEvents = {}




ScrollableTextLinesOptions = {}





ScrollableTextLines = {}





function ScrollableTextLines:new(options)
   local self = setmetatable({}, { __index = ScrollableTextLines })
   options.lines = options.lines or {}
   options.events = options.events or {}
   options.events.mouseDoubleClick = options.events.mouseDoubleClick or function(_) end
   options.events.onChange = options.events.onChange or function(_) end
   options.props = options.props or {}
   options.props.scrollbarRelativeSizeWidth = options.props.scrollbarRelativeSizeWidth or 0.01
   self.options = options
   return self
end

function ScrollableTextLines:update()
   if not self.linesFlex then return end
   local linesFlexContent = ui.content({})
   for i, line in ipairs(self.options.lines) do
      if i >= self.scrollbar.current then
         local isFirst = i == self.scrollbar.current
         linesFlexContent:add({
            template = isFirst and templates.textHeader or templates.textNormal,
            events = {
               mouseClick = async:callback(function()
                  self.scrollbar:setCurrent(i)
                  self:update()
                  self.options.events.onChange(i)
               end),
               mouseDoubleClick = async:callback(function()
                  self.options.events.mouseDoubleClick(i)
               end),
            },
            props = { text = line },
         })
      end
   end
   self.linesFlex.content = linesFlexContent
end

function ScrollableTextLines:remove(i)
   table.remove(self.options.lines, i)
   self.scrollbar:decreaseSize()
   self:update()
   self.options.events.onChange(self.scrollbar.current)
end

function ScrollableTextLines:layout()
   local content = ui.content({})

   self.linesFlex = {
      type = ui.TYPE.Flex,
      props = {
         relativePosition = v2(0.01, 0.01),
         relativeSize = v2(1 - 2 * 0.01 - self.options.props.scrollbarRelativeSizeWidth, 0.98),
      },
   }
   content:add(self.linesFlex)
   self.scrollbar = Scrollbar:new({
      size = #self.options.lines,
      events = {
         onChange = function(newCurrent)
            self:update()
            self.options.events.onChange(newCurrent)
         end,
      },
      props = {
         relativePosition = v2(0.98, 0.01),
         relativeSize = v2(self.options.props.scrollbarRelativeSizeWidth, 0.98),
      },
   })
   content:add(self.scrollbar:layout())

   self:update()

   return {
      content = content,
      props = self.options.props,
   }
end


ScrollableProperties = {}






ScrollableEvents = {}





ScrollableOptions = {}





Scrollable = {}







local noOp = function() end

function Scrollable:new(options)
   local self = setmetatable({}, { __index = Scrollable })
   assert(options.props.lineSizeY)
   options.lines = options.lines or {}
   options.events = options.events or {}
   options.events.mouseClick = options.events.mouseClick or noOp
   options.events.mouseDoubleClick = options.events.mouseDoubleClick or noOp
   options.events.onChange = options.events.onChange or noOp
   options.props = options.props or {}
   options.props.scrollbarRelativeSizeWidth = options.props.scrollbarRelativeSizeWidth or 0.01
   self.options = options
   return self
end

function Scrollable:update()
   if not self.linesFlex then return end
   local linesFlexContent = ui.content({})
   for i, line in ipairs(self.options.lines) do
      if i >= self.scrollbar.current then
         linesFlexContent:add({
            content = ui.content({ line }),
            events = {
               mouseClick = async:callback(function()
                  self.options.events.mouseClick(i)
               end),
               mouseDoubleClick = async:callback(function()
                  self.options.events.mouseDoubleClick(i)
               end),
            },
            props = {
               relativeSize = v2(1, 0),
               size = v2(0, self.options.props.lineSizeY),
            },
         })
      end
   end
   self.linesFlex.content = linesFlexContent
end

function Scrollable:updateAndOnChange()
   self:update()
   self.options.events.onChange(self.scrollbar.current)
end

function Scrollable:setCurrent(current)
   self.scrollbar:setCurrent(current)
   self:updateAndOnChange()
end

function Scrollable:increase()
   self.scrollbar:increase()
   self:updateAndOnChange()
end

function Scrollable:decrease()
   self.scrollbar:decrease()
   self:updateAndOnChange()
end

function Scrollable:setLines(lines)
   self.options.lines = lines or {}
   self.scrollbar:changeSize(#self.options.lines)
   self:update()
end

function Scrollable:remove(i)
   table.remove(self.options.lines, i)
   self.scrollbar:decreaseSize()
   self:updateAndOnChange()
end

function Scrollable:layout()
   local content = ui.content({})

   local scrollbarPositionX = 1 - 2 * 0.01 - self.options.props.scrollbarRelativeSizeWidth
   self.linesFlex = {
      type = ui.TYPE.Flex,
      props = {
         autoSize = false,
         relativePosition = v2(0.01, 0.01),
         relativeSize = v2(scrollbarPositionX - 0.05, 0.98),
      },
   }
   content:add(self.linesFlex)
   self.scrollbar = Scrollbar:new({
      size = #self.options.lines,
      events = {
         onChange = function(_) self:updateAndOnChange() end,
      },
      props = {
         relativePosition = v2(scrollbarPositionX, 0.01),
         relativeSize = v2(self.options.props.scrollbarRelativeSizeWidth, 0.98),
      },
   })
   local scrollbarLayout = self.scrollbar:layout()
   scrollbarLayout.name = 'scrollbar'
   content:add(self.scrollbar:layout())

   self:update()

   self._layout = {
      content = content,
      props = self.options.props,
   }
   return self._layout
end

Expandable = {}







function Expandable:new(expandable)
   local self = setmetatable(expandable, { __index = Expandable })
   expandable.isExpanded = expandable.isExpanded == nil and false or expandable.isExpanded
   expandable.items = expandable.items == nil and {} or expandable.items
   expandable.numParents = expandable.numParents == nil and 0 or expandable.numParents
   return self
end

function flattenExpandables(expandables)
   local layouts = {}
   local toVisit = {}
   for i = 0, #expandables - 1 do
      expandables[#expandables - i].numParents = 0
      table.insert(toVisit, expandables[#expandables - i])
   end
   while #toVisit > 0 do
      local current = table.remove(toVisit)
      table.insert(layouts, current)
      if current.isExpanded then
         for i = 0, #current.items - 1 do
            current.items[#current.items - i].numParents = current.numParents + 1
            table.insert(toVisit, current.items[#current.items - i])
         end
      end
   end
   return layouts
end

ExpandableScrollableEvents = {}









ExpandableScrollableOption = {}





ScrollableGroups = {}








function ScrollableGroups:new(options)
   local self = setmetatable({}, { __index = ScrollableGroups })
   self.options = options
   self.options.events = self.options.events or {}
   self.options.events.focusGainNonGroup = self.options.events.focusGainNonGroup or noOp
   self.options.events.focusLossNonGroup = self.options.events.focusLossNonGroup or noOp
   self.options.events.mouseClickGroup = self.options.events.mouseClickGroup or noOp
   self.options.events.mouseClickNonGroup = self.options.events.mouseClickNonGroup or noOp
   self.options.events.mouseDoubleClickGroup = self.options.events.mouseDoubleClickGroup or noOp
   self.options.events.mouseDoubleClickNonGroup = self.options.events.mouseDoubleClickNonGroup or noOp
   self.options.events.onChange = self.options.events.onChange or noOp
   self.options.items = self.options.items or {}
   self.options.props = self.options.props or {}
   return self
end

function ScrollableGroups:update()
   self._flattenedItems = flattenExpandables(self.options.items)
   local itemsLayouts = {}
   for i, item in ipairs(self._flattenedItems) do
      item.items = item.items or {}
      local content = ui.content({})
      local paddingSizeX = item.numParents * 0.025
      local expandingSignSizeX = 0.05
      content:add({
         props = {
            relativeSize = v2(paddingSizeX, 1),
         },
      })
      if #item.items > 0 then
         content:add({
            template = templates.textNormal,
            props = {
               autoSize = false,
               relativeSize = v2(expandingSignSizeX, 1),
               text = item.isExpanded and '-' or '+',
            },
         })
      else
         content:add({
            props = {
               relativeSize = v2(expandingSignSizeX, 1),
            },
         })
      end
      content:add({
         content = ui.content({ item.layout }),
         props = {
            relativeSize = v2(1 - paddingSizeX - expandingSignSizeX, 1),
         },
      })
      table.insert(itemsLayouts, {
         type = ui.TYPE.Flex,
         content = content,
         events = {
            focusGain = async:callback(function()
               if #item.items <= 0 then
                  self.options.events.focusGainNonGroup(i, item)
               end
            end),
            focusLoss = async:callback(function()
               if #item.items <= 0 then
                  self.options.events.focusLossNonGroup(i, item)
               end
            end),
            mouseClick = async:callback(function()
               if #item.items > 0 then
                  self.options.events.mouseClickGroup(i, item)
               else
                  self.options.events.mouseClickNonGroup(i, item)
               end
               return true
            end),
            mouseDoubleClick = async:callback(function()
               if #item.items > 0 then
                  self.options.events.mouseDoubleClickGroup(i, item)
               else
                  self.options.events.mouseDoubleClickNonGroup(i, item)
               end
               return true
            end),
         },
         props = {
            autoSize = false,
            horizontal = true,
            relativeSize = v2(1, 0),
            size = v2(0, templates.textNormal.props.textSize),
         },
      })
   end
   self.scrollable:setLines(itemsLayouts)
end

function ScrollableGroups:updateAndOnChange()
   self:update()
   self.options.events.onChange()
end

function ScrollableGroups:layout()
   self.scrollable = Scrollable:new({
      events = {
         mouseClick = function(i)
            self._flattenedItems[i].isExpanded = not self._flattenedItems[i].isExpanded
            self:updateAndOnChange()
         end,
         onChange = self.options.events.onChange,
      },
      props = {
         relativeSize = v2(1, 1),
         lineSizeY = self.options.props.lineSizeY,
      },
   })
   self._layout = {
      content = ui.content({ self.scrollable:layout() }),
      props = self.options.props,
   }
   self:update()
   return self._layout
end

Grouppable = {}





function group(grouppables)
   local expandables = {}
   local expandablesByGroup = {}
   for _, grouppable in ipairs(grouppables) do
      local pgroup = ''
      local lastExpandable = nil

      for i, part in ipairs(grouppable.group) do
         pgroup = pgroup .. '.' .. part
         if not expandablesByGroup[pgroup] then
            local expandable = Expandable:new({
               layout = {
                  template = templates.textNormal,
                  props = { text = part },
               },
            })
            if lastExpandable then
               table.insert(lastExpandable.items, expandable)
            end
            expandablesByGroup[pgroup] = expandable
            if i == 1 then
               table.insert(expandables, expandable)
            end
         end
         lastExpandable = expandablesByGroup[pgroup]
      end

      if lastExpandable then
         lastExpandable.items = lastExpandable.items or {}
         table.insert(lastExpandable.items, {
            layout = grouppable.layout,
            data = grouppable.data,
         })
      else
         table.insert(expandables, {
            layout = grouppable.layout,
            data = grouppable.data,
         })
      end
   end
   return expandables
end
