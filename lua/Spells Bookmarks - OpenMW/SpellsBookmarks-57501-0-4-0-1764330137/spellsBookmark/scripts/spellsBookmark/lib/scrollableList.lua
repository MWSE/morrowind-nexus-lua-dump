local util = require('openmw.util')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local ui = require('openmw.ui')

local makeInt = require('scripts.spellsBookmark.lib.myGUI').makeInt
local textures = require('scripts.spellsBookmark.lib.myConstants').textures
local colors = require('scripts.spellsBookmark.lib.myConstants').colors
local sizes = require('scripts.spellsBookmark.lib.myConstants').sizes
local templates = require('scripts.spellsBookmark.lib.myTemplates')

local o = require('scripts.spellsBookmark.settings').o

local ScrollableList = {}

---@type ScrollableList[]
ScrollableList.all = {}

---@param key string
---@param initialItems ui.Element[]
---@param options? {filterFunction: function, sortCallback: function}
---@returns ScrollableList
function ScrollableList.create(key, initialItems, options)
        if ScrollableList.all[key] then
                for _, v in pairs(ScrollableList.all[key].items) do
                        if v.layout then v:destroy() end
                end

                -- ScrollableList.all[key].container = options and options.container
                ScrollableList.all[key].items = initialItems or {}
                ScrollableList.all[key].reset()
                return ScrollableList.all[key]
        end

        ---@class ScrollableList
        local self = {
                key = key,
                filterFunction = options and options.filterFunction or nil,
                sortCallback = options and options.sortCallback or nil,
                items = initialItems or {},
                filteredItems = {},
                filterText = '',
                focus = false,
                arrow = { up = { focus = false, press = false }, down = { focus = false, press = false } },
                element = {},
                bottomPanel = {},
                startElIndex = 1,
                maxVisibleItems = 37,
        }

        local function applyFilter()
                self.filteredItems = {}
                if not self.filterFunction or self.filterText == '' then
                        for i = 1, #self.items do
                                table.insert(self.filteredItems, self.items[i])
                        end
                        return
                end

                local ftext = string.lower(self.filterText)
                for i = 1, #self.items do
                        local el = self.items[i]
                        if self.filterFunction(el.layout.userData.item, ftext) then
                                table.insert(self.filteredItems, el)
                        end
                end
        end

        function self.reset()
                self.startElIndex = 1
                self.focus = false
                self.filterText = ''
                applyFilter()
        end

        function self.setFilterText(text)
                self.filterText = text or ''
                applyFilter()
                self.sortList()
                self.updateElement()
        end

        function self.updateItems(newItems)
                for i = 1, #self.items do
                        local it = self.items[i]
                        if it and type(it.destroy) == 'function' then it:destroy() end
                end
                self.items = newItems or {}
                applyFilter()
                self.updateElement()
        end

        function self.sortList()
                table.sort(self.filteredItems, self.sortCallback)
                -- self.startElIndex = 1
                self.updateElement()
        end

        function self.updateElement()
                local displayItems = {}
                for i = self.startElIndex, self.startElIndex + self.maxVisibleItems do
                        local el = self.filteredItems[i]
                        if el and el.layout then
                                -- el.layout.userData = el.layout.userData or {}
                                el.layout.userData.list = self
                                table.insert(displayItems, el)
                        end
                end

                local layout = {
                        -- name = 'list',
                        -- name = 'mainContent',
                        type = ui.TYPE.Flex,
                        template = templates.getTemplate('none', { 0, 0, 4, 0 }, false),
                        props = { autoSize = false, horizontal = false },
                        external = { grow = 1, stretch = 1 },
                        events = {
                                focusGain = async:callback(function() self.focus = true end),
                                focusLoss = async:callback(function() self.focus = false end),
                        },
                        content = ui.content(displayItems),
                }

                if self.element.layout then
                        self.element.layout = layout
                else
                        self.element = ui.create(layout)
                end
                self.element.layout.content = ui.content(displayItems)
                self.element:update()
        end

        local function getScrollButtonsEvents(arrowState)
                return {
                        mousePress = async:callback(function(e) if e.button == 1 then arrowState.press = true end end),
                        mouseRelease = async:callback(function(e) arrowState.press = false end),
                        focusGain = async:callback(function() arrowState.focus = true end),
                        focusLoss = async:callback(function() arrowState.focus = false end),
                }
        end

        function self.createFilterInput()
                if not self.filterFunction then return nil end

                local filterInput = {
                        template = I.MWUI.templates.textEditLine,
                        props = {
                                text = self.filterText,
                                textColor = util.color.hex('ffffff'),
                                size = util.vector2(50, 1),
                        },
                        events = {
                                textChanged = async:callback(function(newText)
                                        self.startElIndex = 1
                                        self.setFilterText(newText)
                                end),
                        }
                }

                return {
                        type = ui.TYPE.Flex,
                        props = {
                                arrange = ui.ALIGNMENT.Center,
                                align = ui.ALIGNMENT.Start,
                                horizontal = true,
                        },
                        content = ui.content {
                                {
                                        template = I.MWUI.templates.box,
                                        content = ui.content { filterInput }
                                }
                        }
                }
        end

        function self.createLayout()
                self.reset()
                self.sortList()

                local scrollControls = {
                        type = ui.TYPE.Flex,
                        props = { horizontal = true, arrange = ui.ALIGNMENT.Center, align = ui.ALIGNMENT.Center },
                        content = ui.content({
                                { type = ui.TYPE.Image, props = { resource = textures.upArrow, size = util.vector2(14, 14) },   events = getScrollButtonsEvents(self.arrow.up) },
                                { type = ui.TYPE.Image, props = { resource = textures.downArrow, size = util.vector2(14, 14) }, events = getScrollButtonsEvents(self.arrow.down) },
                        })
                }

                self.bottomPanel = {
                        type = ui.TYPE.Flex,
                        template = templates.getTemplate('none', { 0, 0, 0, 0 }, false),
                        props = {
                                horizontal = true,
                                arrange = ui.ALIGNMENT.Center,
                                align = ui.ALIGNMENT.Start,
                                size = util.vector2(100, 20)
                        },
                        content = ui.content({
                                scrollControls,
                                makeInt(4, 0),
                                self.createFilterInput()
                        })
                }

                return {
                        type = ui.TYPE.Flex,
                        template = templates.getTemplate('thin', { 4, 4, 4, 4 }, false),
                        props = { relativeSize = util.vector2(1, 1), arrange = ui.ALIGNMENT.Start, align = ui.ALIGNMENT.Center },
                        external = { grow = 1, stretch = 0 },
                        content = ui.content({
                                -- (self.getQuickStackButtons and self.getQuickStackButtons(self.container)) or {},
                                { template = I.MWUI.templates.horizontalLine, external = { grow = 0, stretch = 1 }, props = { size = util.vector2(1, 2), relativeSize = util.vector2(0, 0) } },
                                -- self.header or {},
                                { template = I.MWUI.templates.horizontalLine, external = { grow = 0, stretch = 1 }, props = { size = util.vector2(1, 2), relativeSize = util.vector2(0, 0) } },
                                self.element,
                                { template = I.MWUI.templates.horizontalLine, external = { grow = 0, stretch = 1 }, props = { size = util.vector2(1, 2), relativeSize = util.vector2(0, 0) } },
                                makeInt(0, 4),
                                self.bottomPanel,
                                makeInt(0, 10)
                        })
                }
        end

        function self.onFrame()
                if self.arrow.up.focus and self.arrow.up.press then
                        self.scrollUp()
                        self.element:update()
                elseif self.arrow.down.focus and self.arrow.down.press then
                        self.scrollDown()
                        self.element:update()
                end
        end

        function self.onMouseWheel(direction)
                if self.focus then
                        if direction == -1 then
                                self.scrollUp()
                                return true
                        elseif direction == 1 then
                                self.scrollDown()
                                return true
                        end
                end
                return false
        end

        function self.getAllLists() return ScrollableList.all end

        function self.scroll(direction)
                self.startElIndex = math.min(math.max(1, self.startElIndex - direction), math.max(1, #self.filteredItems))
                self.updateElement()
        end

        function self.scrollUp() self.scroll(sizes.SCROLL_AMOUNT) end

        function self.scrollDown() self.scroll(-sizes.SCROLL_AMOUNT) end

        function self.getArrowEvents(arrowState) return getScrollButtonsEvents(arrowState) end

        ScrollableList.all[key] = self

        return self
end

return ScrollableList
