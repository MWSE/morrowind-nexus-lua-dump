local util = require('openmw.util')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local ui = require('openmw.ui')

local makeInt = require('scripts.spellsBookmark.lib.myGUI').makeInt
local textures = require('scripts.spellsBookmark.lib.myConstants').textures
local colors = require('scripts.spellsBookmark.lib.myConstants').colors
local sizes = require('scripts.spellsBookmark.lib.myConstants').sizes
local templates = require('scripts.spellsBookmark.lib.myTemplates')
local window = require('scripts.spellsBookmark.lib.window')

local myVars = require('scripts.spellsBookmark.lib.myVars')
local myConstants = require('scripts.spellsBookmark.lib.myConstants')

local ScrollableList = {}

---@type ScrollableList[]
ScrollableList.all = {}
ScrollableList.active = nil


---@param key string
---@param initialItems ui.Element[]
---@param options? {filterFunction: function, sortCallback: function}
---@returns ScrollableList
function ScrollableList.create(key, initialItems, options)
        if ScrollableList.all[key] then
                for _, v in pairs(ScrollableList.all[key].items) do
                        if v.layout then v:destroy() end
                end

                ScrollableList.all[key].items = initialItems or {}
                ScrollableList.all[key].reset()
                return ScrollableList.all[key]
        end

        ---@class ScrollableList
        local self = {
                key = key,
                filterFunction = options and options.filterFunction or nil,
                sortCallback = options and options.sortCallback or nil,
                ---@type ui.Element[]
                items = initialItems or {},
                ---@type ui.Element[]
                filteredItems = {},
                filterText = '',
                focus = false,
                arrow = { up = { focus = false, press = false }, down = { focus = false, press = false } },
                ---@type ui.Element|{}
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
                self:deHighlight()
                self.currentIndex = 1
                self.startElIndex = 1
                self.focus = false
                self.filterText = ''


                --- 10 margin
                --- 12 gap
                --- 17 TOP BAR
                --- 3 interval
                --- 1 horizontalLine
                --- 30 MID BAR
                --- 1 interval
                --- ############ MY LIST ############
                --- 1 horizontalLine
                --- 4 interval
                --- 20 BOTTOM PANEL
                --- 10 pad
                --- 12 more pad ??
                --- 10 margin

                --- 10 mar
                --- 52
                --- List
                --- 35
                --- 10 mar

                --- height = 62 + 45 = 107
                --- list height = res.y - 107 * scale

                --- ALT ###
                --- windowExtras = 52 + 35 = 87
                --- list height = (window.size.y - 87)

                -- local listHeight = myVars.res.y - 107 * myVars.scale
                -- local itemHeight = myConstants.sizes.TEXT_SIZE * myVars.scale
                -- local listHeight = myVars.res.y - 107
                -- local itemHeight = myConstants.sizes.TEXT_SIZE
                -- local itemsCount = math.floor(listHeight / itemHeight)
                -- local listHeight = myVars.mainWindow.size.y - 87 - 8
                local listHeight = myVars.mainWindow.size.y - 87 - 8 - 24
                local itemHeight = myConstants.sizes.CONTAINER_SIZE
                local itemsCount = math.floor(listHeight / itemHeight)
                self.maxVisibleItems = itemsCount
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
                                table.insert(displayItems, el)
                        end
                end

                local layout = {
                        type = ui.TYPE.Flex,
                        template = templates.getTemplate('none', { 0, 0, 4, 0 }, false),
                        props = { autoSize = false, horizontal = false },
                        external = { grow = 1, stretch = 1 },
                        events = {
                                focusGain = async:callback(function()
                                        self.focus = true
                                        return true
                                end),

                                focusLoss = async:callback(function()
                                        self.focus = false
                                        return true
                                end),
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
                self:highlight()

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

                ScrollableList.active = self

                return {
                        type = ui.TYPE.Flex,
                        props = { relativeSize = util.vector2(1, 1), arrange = ui.ALIGNMENT.Start, align = ui.ALIGNMENT.Center },
                        external = { grow = 1, stretch = 0 },
                        content = ui.content {
                                self.element,
                                {
                                        template = I.MWUI.templates.horizontalLine,
                                        props = {
                                                size = util.vector2(1, 1),
                                        }
                                },
                                makeInt(0, 4),
                                self.bottomPanel,
                                makeInt(0, 10)
                        }
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
                        if direction == 1 then
                                self.scrollUp()
                                return true
                        elseif direction == -1 then
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



        function self.deHighlight()
                local el = self.filteredItems[self.currentIndex]
                if not el then return end
                el.layout.events.focusLoss(nil, el.layout)
        end

        function self.highlight()
                local el = self.filteredItems[self.currentIndex]
                if not el then return end
                el.layout.events.focusGain(nil, el.layout, true)
        end

        function self.nextItem(dir)
                self.deHighlight()
                self.currentIndex = self.currentIndex + dir
                local lastIndex = self.startElIndex + self.maxVisibleItems
                if self.currentIndex < 1 then
                        self.currentIndex = 1
                elseif self.currentIndex > #self.filteredItems then
                        self.currentIndex = #self.filteredItems
                elseif self.currentIndex > lastIndex then
                        self.scroll(-1)
                elseif self.currentIndex < self.startElIndex then
                        self.scroll(1)
                end
                self.highlight()
        end

        function self.selectCurrent()
                local current = self.filteredItems[self.currentIndex]

                if current then
                        current.layout.events.focusLoss(nil, current.layout)
                        current.layout.events.mousePress({ button = 1 }, current.layout)
                end

                self.highlight()
        end

        return self
end

return ScrollableList
