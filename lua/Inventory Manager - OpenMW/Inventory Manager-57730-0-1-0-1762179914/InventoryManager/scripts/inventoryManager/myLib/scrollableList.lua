local util = require('openmw.util')
local I = require('openmw.interfaces')
local auxUi = require('openmw_aux.ui')
local async = require('openmw.async')
local ui = require('openmw.ui')
local types = require('openmw.types')
local auxUi = require('openmw_aux.ui')

local makeInt = require('scripts.inventoryManager.myLib.myGUI').makeInt
local textures = require('scripts.inventoryManager.myLib.myConstants').textures
local colors = require('scripts.inventoryManager.myLib.myConstants').colors
local sizes = require('scripts.inventoryManager.myLib.myConstants').sizes
local lists = require('scripts.inventoryManager.myLib.myConstants').lists
local templates = require('scripts.inventoryManager.myLib.myTemplates')

local myDelayedActions = require(
        'scripts.inventoryManager.myLib.DELAYED_ACTION_IS_NOT_ALLOWED_TO_START_ANOTHER_DELAYED_ACTION')

-- local newType = require('scripts.inventoryManager.myTypes').newType


local ScrollableList = {}

-- local SCROLL_AMOUNT = 16 * 2

---@type table<string, ScrollableList>
ScrollableList.all = {}

---@param key string
---@param initialItems ui.Element[]
---@param options? {filterFunction: function, header: ui.Layout, quickStackButtons: function, filterButtons: table<number, { key: string, name: string, callback: function }>, container: GameObject}
function ScrollableList.create(key, initialItems, options)
        if ScrollableList.all[key] then
                for _, v in pairs(ScrollableList.all[key].items) do
                        if v.layout then
                                v:destroy()
                        end
                end

                ScrollableList.all[key].container = options and options.container
                ScrollableList.all[key].items = initialItems
                ScrollableList.all[key].reset()
                return ScrollableList.all[key]
        end

        ---@class ScrollableList
        local self = {
                key = key,
                header = options and options.header or nil,
                filterFunction = options and options.filterFunction or nil,
                filterButtons = options and options.filterButtons or nil,
                -- filterButtonCallback = options and options.filterButtons[1].callback,
                filterButtonName = nil,
                items = initialItems or {},
                filteredItems = initialItems or {},
                filterText = '',
                focus = false,
                -- -@type ui.Layout
                -- expandable = nil,
                -- expSize = 0,
                -- expTargetSize = 0,
                -- maxSize = 0,
                arrow = {
                        up = { focus = false, press = false },
                        down = { focus = false, press = false }
                },
                ---@type ui.Element|{}
                element = {},
                ---@type ui.Element|{}
                bottomPanel = {},
                itemsCount = {
                        ['All'] = 0,
                        [types.Weapon] = 0,
                        [types.Armor] = 0,
                        [types.Clothing] = 0,
                        [types.Ingredient] = 0,
                        [types.Miscellaneous] = 0,
                        [types.Potion] = 0,
                        [types.Book] = 0,
                        ['Paper'] = 0,
                        ['Tool'] = 0
                        -- ['Scroll'] = 0,
                        -- [types.Apparatus] = 0
                },
                getQuickStackButtons = options and options.quickStackButtons,
                container = options and options.container,
                ---@type ui.Element[]
                filterButtonsEls = nil,
                -- fbIndex = 0,

                startElIndex = 1,
                -- endElIndex = 0,
                maxVisibleItems = 37,
        }


        local function getTypeCountText(fButtonKey)
                return tostring((fButtonKey == 'All' and self.itemsCount['All']) or self.itemsCount[fButtonKey])
        end

        if not SCROLL_AMOUNT then
                SCROLL_AMOUNT = initialItems[1].layout.props.textSize
        end

        function self.reset()
                -- self.expSize = 0
                -- self.expTargetSize = 0
                self.startElIndex = 1
                self.focus = false
                self.filterText = ''
                self.filterButtonName = 'All'

                -- self.endElIndex = self.startElIndex + self.maxVisibleItems

                self.applyFilter()
        end

        function self.setFilterText(text)
                self.filterText = text
                self.applyFilter()
                self.updateElement()
        end

        function self.createFilterButtons()
                if not self.filterButtons then return {} end

                ---@type ui.Element[]
                local buttonsLOs = {}

                -- for _, data in pairs(self.filterButtons) do
                for i = 1, #self.filterButtons do
                        local data = self.filterButtons[i]
                        if self.itemsCount[data.key] == 0 then
                                goto next_button
                        end

                        local layout = ui.create {
                                type = ui.TYPE.Flex,
                                template = templates.getTemplate('none', { 0, 0, 0, 0 }, false),
                                external = { grow = 1, stretch = 1 },
                                userData = {
                                        key = data.key
                                },
                                props = {
                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                        horizontal = false,
                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        text = string.format(' %s ', data.name),
                                                        textColor = #buttonsLOs + 1 == 1 and colors.selected or colors.normal,
                                                        textSize = sizes.LABEL_SIZE,
                                                        -- textSize = 14,
                                                },

                                        },
                                        {
                                                name = 'typeCount',
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        text = getTypeCountText(data.key),
                                                        textSize = sizes.LABEL_SIZE,
                                                        -- textSize = 14,
                                                },

                                        },
                                },
                                events = {
                                        mouseClick = async:callback(function(_, l)
                                                -- for _, v in pairs(buttonsLOs) do
                                                for btnIndex = 1, #buttonsLOs do
                                                        local v = buttonsLOs[btnIndex]
                                                        v.layout.content[1].props.textColor = colors.normal
                                                        if v.layout == l then
                                                                v.layout.content[1].props.textColor = colors.selected
                                                        end
                                                        -- v:update()
                                                        table.insert(myDelayedActions, 1, v)
                                                end

                                                -- self.filterButtonCallback = data.callback
                                                self.filterButtonName = data.key
                                                self.applyFilter()
                                                -- self.expTargetSize = 0
                                                self.startElIndex = 1

                                                self.updateElement()
                                        end),
                                }
                        }

                        table.insert(buttonsLOs, layout)
                        ::next_button::
                end

                self.filterButtonsEls = buttonsLOs

                return self.filterButtonsEls
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
                                        -- self.expTargetSize = 0
                                        self.startElIndex = 1
                                        self.setFilterText(newText)
                                end),
                        }
                }

                return {
                        type = ui.TYPE.Flex,
                        -- template = I.MWUI.templates.borders,
                        -- external = { grow = 1, stretch = 1 },
                        props = {
                                arrange = ui.ALIGNMENT.Center,
                                align = ui.ALIGNMENT.Start,
                                horizontal = true,
                                -- size = util.vector2(50, 30)
                        },
                        content = ui.content {
                                {
                                        -- relativeSize = util.vector2(1, 1),
                                        template = I.MWUI.templates.box,
                                        content = ui.content { filterInput }
                                }
                        }
                }
        end

        function self.updateItems(newItems)
                -- for _, v in pairs(self.items) do
                for i = 1, #self.items do
                        self.items[i]:destroy()
                end

                self.items = newItems
                self.applyFilter()
                self.updateElement()
        end

        local itemType
        function self.applyFilter()
                self.filteredItems = {}

                for typeKey, _ in pairs(self.itemsCount) do
                        self.itemsCount[typeKey] = 0
                end

                -- for _, item in ipairs(self.items) do
                for i = 1, #self.items do
                        local item = self.items[i]
                        -- itemType = newType[item.layout.userData.type] or item.layout.userData.type
                        itemType = item.layout.userData.type
                        -- print(item.layout.userData.type, '    ==', itemType)
                        self.itemsCount[itemType] = self.itemsCount[itemType] + 1
                        self.itemsCount['All'] = self.itemsCount['All'] + 1
                        -- if self.filterButtonCallback(item) then
                        if self.filterButtonName == 'All' or itemType == self.filterButtonName then
                                if not self.filterFunction or self.filterText == "" then
                                        table.insert(self.filteredItems, item)
                                elseif self.filterFunction(item, self.filterText) then
                                        table.insert(self.filteredItems, item)
                                end
                        end
                end

                -- self.maxSize = self.getMaxSize()



                if self.filterButtonsEls then
                        -- for i, v in pairs(self.filterButtonsEls) do
                        for i = 1, #self.filterButtonsEls do
                                local v = self.filterButtonsEls[i]
                                if not v or not v.layout then return end
                                local fbKey = v.layout.userData.key
                                ---@diagnostic disable-next-line: undefined-field
                                v.layout.content.typeCount.props.text = getTypeCountText(fbKey)
                                table.insert(myDelayedActions, 1, v)
                        end
                end
        end

        -- function self.getMaxSize()
        --         return (- #self.filteredItems + 1) * sizes.SCROLL_AMOUNT
        --         -- return (- #self.filteredItems + 3) * SCROLL_AMOUNT
        --         -- return (- #self.filteredItems) * SCROLL_AMOUNT
        -- end

        ---@type ui.Layout
        local layout = {
                name = 'list',
                type = ui.TYPE.Flex,
                template = templates.getTemplate('none', { 0, 0, 4, 0 }, false),
                props = { autoSize = false, horizontal = false },
                external = { grow = 1, stretch = 1 },
                events = {
                        focusGain = async:callback(function() self.focus = true end),
                        focusLoss = async:callback(function() self.focus = false end)
                },
                content = ui.content({})
        }


        function self.sortList(callback)
                table.sort(self.filteredItems, function(a, b)
                        return callback(a.layout.userData, b.layout.userData)
                end)
                -- self.expTargetSize = 0
                self.startElIndex = 1
                self.updateElement()
        end

        function self.updateElement()


                -- print('self.updateElement() is called')
                local displayItems = {}
                local el

                for i = self.startElIndex, self.startElIndex + self.maxVisibleItems do
                        el = self.filteredItems[i]
                        if el and self.filteredItems[i].layout then
                                self.filteredItems[i].layout.userData.list = self
                                table.insert(displayItems, self.filteredItems[i])
                        end
                end


                if self.element.layout then
                        self.element.layout = layout
                else
                        self.element = ui.create(layout)
                end
                self.element.layout.content = ui.content(displayItems)
                ----------------------------------
                self.element:update()
        end

        function self.createLayout()
                -- self.maxSize = self.getMaxSize()

                -- self.filterButtonCallback = self.filterButtons[1].callback
                self.reset()
                -- self.expandable = self.createExpandable(self.expSize)
                self.updateElement()

                local scrollControls = {
                        type = ui.TYPE.Flex,
                        props = { horizontal = true, arrange = ui.ALIGNMENT.Center, align = ui.ALIGNMENT.Center },
                        content = ui.content({
                                {
                                        type = ui.TYPE.Image,
                                        props = { resource = textures.upArrow, size = util.vector2(14, 14) },
                                        events = self.getArrowEvents(self.arrow.up)
                                },
                                {
                                        type = ui.TYPE.Image,
                                        props = { resource = textures.downArrow, size = util.vector2(14, 14) },
                                        events = self.getArrowEvents(self.arrow.down)
                                }
                        })
                }

                -- self.bottomPanel = ui.create {
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
                                self.createFilterInput(),
                                makeInt(8, 0),
                                {
                                        type = ui.TYPE.Flex,
                                        props = { horizontal = true },
                                        content = ui.content {
                                                unpack(self.createFilterButtons())
                                        }
                                }
                        })
                }

                return {
                        type = ui.TYPE.Flex,
                        template = templates.getTemplate('thin', { 4, 4, 4, 4 }, false),
                        props = {
                                relativeSize = util.vector2(1, 1),
                                arrange = ui.ALIGNMENT.Start,
                                align = ui.ALIGNMENT.Center
                        },
                        external = { grow = 1, stretch = 0 },
                        content = ui.content({
                                self.getQuickStackButtons(self.container),
                                --- Header
                                {
                                        template = I.MWUI.templates.horizontalLine,
                                        external = { grow = 0, stretch = 1 },
                                        props = { size = util.vector2(1, 2), relativeSize = util.vector2(0, 0) }
                                },
                                self.header,
                                {
                                        template = I.MWUI.templates.horizontalLine,
                                        external = { grow = 0, stretch = 1 },
                                        props = { size = util.vector2(1, 2), relativeSize = util.vector2(0, 0) }
                                },


                                --- List Content
                                self.element,
                                {
                                        template = I.MWUI.templates.horizontalLine,
                                        external = { grow = 0, stretch = 1 },
                                        props = { size = util.vector2(1, 2), relativeSize = util.vector2(0, 0) }
                                },
                                makeInt(0, 4),
                                self.bottomPanel,
                                makeInt(0, 10)
                        })
                }
        end

        function self.onFrame()
                -- if self.expSize ~= self.expTargetSize then
                --         self.expSize = self.expTargetSize
                --         if self.expandable then
                --                 self.expandable.props.size = util.vector2(0, self.expSize)
                --         end
                --         self.element:update()
                -- end

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
                        elseif direction == 1 then
                                self.scrollDown()
                        end
                end
        end

        function self.getAllLists()
                return ScrollableList.all
        end

        function self.scroll(direction)
                self.startElIndex = math.min(math.max(1, self.startElIndex - direction), #self.filteredItems)
                self.updateElement()
        end

        function self.scrollUp()
                self.scroll(lists.SCROLL_AMOUNT)
        end

        function self.scrollDown()
                self.scroll(-lists.SCROLL_AMOUNT)
        end

        -- function self.createExpandable(height)
        --         local expandable = auxUi.deepLayoutCopy(I.MWUI.templates.interval)
        --         expandable.props.external = { grow = 0, stretch = 0 }
        --         expandable.props.autoSize = false
        --         expandable.props.size = util.vector2(0, height)
        --         expandable.props.isExpandable = true
        --         return expandable
        -- end

        function self.getArrowEvents(arrowState)
                return {
                        mousePress = async:callback(function(e)
                                if e.button == 1 then arrowState.press = true end
                        end),
                        mouseRelease = async:callback(function(e)
                                arrowState.press = false
                        end),
                        focusGain = async:callback(function() arrowState.focus = true end),
                        focusLoss = async:callback(function() arrowState.focus = false end)
                }
        end

        ScrollableList.all[key] = self

        return self
end

return ScrollableList
