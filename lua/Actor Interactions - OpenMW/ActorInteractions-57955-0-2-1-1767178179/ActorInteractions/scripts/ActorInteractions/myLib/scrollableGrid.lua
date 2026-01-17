local ui = require('openmw.ui')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local myConstants = require('scripts.ActorInteractions.myLib.myConstants')
local myUtils = require('scripts.ActorInteractions.myLib.myUtils')
local myGUI = require('scripts.ActorInteractions.myLib.myGUI')
local myTemplates = require('scripts.ActorInteractions.myLib.myTemplates')
local myVars = require('scripts.ActorInteractions.myLib.myVars')
local toolTip = require('scripts.ActorInteractions.myLib.toolTip')

---@class ScrollableGrid
---@field key string
---@field focus boolean
---@field arrow table
---@field startRowIndex number
---@field currentIndex number
---@field maxVisibleRows number
---@field visibleRows ui.Layout[]
---@field element ui.Layout
---@field items ScrollableItem[]
---@field upArrow ui.Layout
---@field downArrow ui.Layout
---@field getItems fun(): ScrollableItem[]
---@field getLayout fun(item: ScrollableItem, index: number): ui.Layout
---@field extraItemsCount number
---@field updateParentElement function
---@field gridNext fun(self:ScrollableGrid, dir: number)
---@field selectCurrent fun(self: ScrollableGrid, index?: number)
---@field scroll fun(self: ScrollableGrid, amount:number)
---@field highlight fun(self: ScrollableGrid, index: number|nil, forcePosition: boolean)
---@field deHighlight fun(self: ScrollableGrid, index?: number)
---@field updateItems fun(self: ScrollableGrid)
---@field gridExact fun(self: ScrollableGrid, index: number)
---@field ROW_LEN number
local o = {}
local ScrollableGrid = o

o.__index = o
-- -@type table<string, ScrollableGrid>
-- o.all = {}
o.isGrid = true
o.cached = {}


---@class GridGetters
---@field getItems fun(): ScrollableItem[]
---@field getLayout? fun(item: ScrollableItem, index?: number): ui.Layout
---@field getAllLayouts? fun(self: ScrollableGrid): ui.Layout[]
---@field extraItemsCount? number
---@field updateParentElement function
---@field maxVisibleRows? number
---@field ROW_LEN? number
-- -@field onSelectAction fun(item: GameObject)

---@param getters GridGetters
---@return ScrollableGrid
function o:new(key, getters)
        ---@type ScrollableGrid
        local inst = setmetatable({}, o)

        inst.key = key
        inst.focus = false
        inst.arrow = {
                up = { focus = false, press = false },
                down = { focus = false, press = false }
        }

        inst.startRowIndex = 1
        inst.currentIndex = 1

        -- inst.savedLayouts = {}


        inst.ROW_LEN = getters.ROW_LEN or
            math.floor((myVars.res.x * 0.80) / myConstants.sizes.GRID_ITEM_SIZE)

        inst.maxVisibleRows = getters.maxVisibleRows or
            math.floor((myVars.res.y * 0.80) / myConstants.sizes.GRID_ITEM_SIZE)

        inst.visibleRows = {}

        inst.downArrow = {
                type = ui.TYPE.Flex,
                -- template = myTemplates.iconFrame,
                props = {
                        size = util.vector2(0, myConstants.sizes.LIST_TEXT_SIZE),
                        relativeSize = util.vector2(1, 0),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = myConstants.textures.downArrow,
                                        size = util.vector2(myConstants.sizes.LIST_TEXT_SIZE, myConstants.sizes.LIST_TEXT_SIZE),
                                },
                        }
                },
                events = {
                        mousePress = async:callback(function()
                                inst:scroll(inst.maxVisibleRows - 1)
                                return true
                        end)
                }
        }

        inst.upArrow = {
                type = ui.TYPE.Flex,
                -- template = myTemplates.iconFrame,
                external = { grow = 1, stretch = 1 },

                props = {
                        size = util.vector2(0, myConstants.sizes.LIST_TEXT_SIZE),
                        relativeSize = util.vector2(1, 0),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = myConstants.textures.upArrow,
                                        size = util.vector2(myConstants.sizes.LIST_TEXT_SIZE, myConstants.sizes.LIST_TEXT_SIZE),
                                },
                        }
                },
                events = {
                        mousePress = async:callback(function()
                                inst:scroll(-inst.maxVisibleRows + 1)
                                return true
                        end)
                }
        }

        inst.element = {
                type = ui.TYPE.Flex,
                template = I.MWUI.templates.bordersThick,
                external = { grow = 1, stretch = 1 },
                props = {
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {

                        myGUI.makeInt(0, 4),
                        inst.upArrow,
                        {
                                name = 'listContent',
                                type = ui.TYPE.Flex,
                        },
                        inst.downArrow,
                        myGUI.makeInt(0, 4),

                },
                events = {
                        focusGain = async:callback(function()
                                inst.focus = true
                                return true
                        end),
                        focusLoss = async:callback(function()
                                inst.focus = false
                                return true
                        end),
                }
        }

        -- inst.onSelectAction = getters.onSelectAction
        inst.getItems = getters.getItems
        inst.getLayout = getters.getLayout
        inst.updateParentElement = getters.updateParentElement
        inst.extraItemsCount = getters.extraItemsCount or 0

        -- function inst:getAllLayouts()
        --         return getters.getAllLayouts(self)
        -- end

        inst:updateItems()

        -- o.all[key] = inst


        myVars.currentScrollable = inst

        return inst
end

function o:getAllItemsCount()
        return #self.items + self.extraItemsCount
end

function o:getAllRowsCount()
        return math.ceil(self:getAllItemsCount() / self.ROW_LEN)
end

function o:updateItems()
        self.items = self.getItems()
        self:getVisibleElements()
end

local function getRowLayout()
        return {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                props = { horizontal = true },
                content = ui.content {},
        }
end

function o:getFirstVisibleLayoutIndex()
        return 1 + (self.startRowIndex - 1) * self.ROW_LEN
end

function o:getVisibleElements()
        self.visibleRows = {}

        local lastRow = self.startRowIndex + self.maxVisibleRows - 1

        if lastRow > self:getAllRowsCount() then
                lastRow = self:getAllRowsCount()
        end

        local allItemsCount = self:getAllItemsCount()

        if self.getLayout then
                local itemIndex = 1
                for i = self.startRowIndex, lastRow do
                        table.insert(self.visibleRows, getRowLayout())
                        for __ = 1, self.ROW_LEN do
                                local visibleItemIndex = itemIndex + (self.startRowIndex - 1) * self.ROW_LEN
                                if visibleItemIndex > allItemsCount then
                                        break
                                end

                                local item = self.items[visibleItemIndex]
                                local lastRowLayout = self.visibleRows[#self.visibleRows]
                                lastRowLayout = self.visibleRows[#self.visibleRows]

                                -- local layout
                                -- if item.id then
                                --         if self.cached[item.id] then
                                --                 layout = self.cached[item.id]
                                --                 layout.template = nil
                                --         else
                                --                 -- layout = self.getLayout(item, i)
                                --                 layout = self.getLayout(item, visibleItemIndex)
                                --                 self.cached[item.id] = layout
                                --         end
                                -- else
                                --         layout = self.getLayout(item, i)
                                -- end

                                local layout = self.getLayout(item, visibleItemIndex)

                                lastRowLayout.content:add(layout)

                                itemIndex = itemIndex + 1
                        end
                end
                -- elseif self.getAllLayouts then
                -- TODO : FIX/CACHE
                -- local allLayouts = self:getAllLayouts() #############
                -- local itemIndex = 1
                -- for _ = self.startRowIndex, lastRow do
                --         table.insert(self.visibleRows, getRowLayout())
                --         for __ = 1, self.ROW_LEN do
                --                 local visibleItemIndex = itemIndex + (self.startRowIndex - 1) * self.ROW_LEN
                --                 if visibleItemIndex > allItemsCount then
                --                         break
                --                 end
                --                 local lastRowLayout = self.visibleRows[#self.visibleRows]
                --                 lastRowLayout = self.visibleRows[#self.visibleRows]
                --                 lastRowLayout.content:add(allLayouts[visibleItemIndex])
                --                 itemIndex = itemIndex + 1
                --         end
                -- end
        else
                error('No layout getter provided')
        end


        if lastRow < self:getAllRowsCount() then
                self.downArrow.props.alpha = 1
        else
                self.downArrow.props.alpha = 0.2
        end

        if self.startRowIndex ~= 1 then
                self.upArrow.props.alpha = 1
        else
                self.upArrow.props.alpha = 0.2
        end

        local firstVisibleIndex = self:getFirstVisibleLayoutIndex()

        if self.currentIndex < firstVisibleIndex then
                self.currentIndex = firstVisibleIndex
        elseif self.currentIndex > lastRow * self.ROW_LEN then
                -- self.currentIndex = lastRow
                self.currentIndex = self.currentIndex - self.ROW_LEN
        elseif self.currentIndex > #self.items then
                self.currentIndex = #self.items
        end
        -- elseif self.currentIndex > self:getAllItemsCount() then
        --         self.currentIndex = self:getAllItemsCount()
        -- end

        self:setContent()
end

function o:setContent()
        if #self.visibleRows == 0 then
                ---@diagnostic disable-next-line: undefined-field
                self.element.content.listContent.content = ui.content {
                        {
                                template = I.MWUI.templates.textHeader,
                                props = {
                                        text = 'No Items'
                                }
                        }
                }
                self.updateParentElement()
                return
        else
                ---@diagnostic disable-next-line: undefined-field
                self.element.content.listContent.content = ui.content(self.visibleRows)
        end
        self:highlight(nil, true)
end

---@param index any
function o:listExact(index)
        -- self:deHighlight()
        local amount = self.currentIndex - index
        self:listNext(amount)
        -- self.currentIndex = index

        -- if self.currentIndex > self:getAllItemsCount() then
        --         self.currentIndex = self:getAllItemsCount()
        -- elseif self.currentIndex < 1 then
        --         self.currentIndex = 1
        -- end

        -- if self.currentIndex >= self.startRowIndex + self.maxVisibleRows then
        --         self:scroll(self.currentIndex - (self.startRowIndex + self.maxVisibleRows))
        -- elseif self.currentIndex < self.startRowIndex then
        --         self:scroll(-1)
        -- else
        --         self:highlight(nil, true)
        -- end
end

---@param amount number
function o:scroll(amount)
        self.startRowIndex = self.startRowIndex + amount

        if self.startRowIndex < 1 then
                self.startRowIndex = 1
        end

        if self.startRowIndex + self.maxVisibleRows - 1 > self:getAllRowsCount() then
                self.startRowIndex = math.max(1, self:getAllRowsCount() - self.maxVisibleRows + 1)
        end

        self:getVisibleElements()
end

---@param index any
---@return ui.Layout|nil
function o:getCurrentItemLayout(index)
        if not self.element then return end
        self.currentIndex = index or self.currentIndex

        local visibleIndex = (self.currentIndex - 1) % self.ROW_LEN + 1

        local absoluteRow = math.floor((self.currentIndex - 1) / self.ROW_LEN) + 1
        local visibleIndexRow = absoluteRow - self.startRowIndex + 1

        ---@type ui.Layout
        local visibleRow = self.visibleRows[visibleIndexRow]
        if not visibleRow then return end

        ---@type ui.Layout
        local visibleLayout = visibleRow.content[visibleIndex]
        return visibleLayout
end

---@param index number
function o:deHighlight(index)
        local currentItemLayout = self:getCurrentItemLayout(index)
        if not currentItemLayout then return end

        currentItemLayout.template = nil

        self.updateParentElement()
end

---@param index number
---@param forcePosition boolean
function o:highlight(index, forcePosition)
        local currentItemLayout = self:getCurrentItemLayout(index)
        if not currentItemLayout then return end

        currentItemLayout.template = myTemplates.highlight_white

        self.updateParentElement()

        toolTip.closed = nil
        myUtils.debounce('showToolTip', 0.4, function()
                if self.element and currentItemLayout.userData.item then
                        toolTip.showToolTip(currentItemLayout.userData.item, forcePosition)
                end
        end)
end

---@param index number
function o:selectCurrent(index)
        local currentItemLayout = self:getCurrentItemLayout(index)

        if currentItemLayout then
                self:deHighlight()
                currentItemLayout.events.mousePress({ button = 1 }, currentItemLayout)
        end

        self:highlight(nil, true)
end

---@param amount number
function o:listNext(amount)
        self:deHighlight()

        local nextIndex = self.currentIndex + amount

        local itemsCount = self:getAllItemsCount()


        if math.abs(amount) == 1 then
                if amount > 0 then
                        if self.currentIndex % self.ROW_LEN == 0 then
                                nextIndex = self.currentIndex - self.ROW_LEN + 1
                        end
                        if nextIndex > itemsCount then
                                local rowStart = math.floor((self.currentIndex - 1) / self.ROW_LEN) * self.ROW_LEN + 1
                                self.currentIndex = rowStart
                        else
                                self.currentIndex = nextIndex
                        end
                elseif amount < 0 then
                        if (self.currentIndex - 1) % self.ROW_LEN == 0 then
                                nextIndex = self.currentIndex + self.ROW_LEN - 1
                                if nextIndex > itemsCount then
                                        self.currentIndex = itemsCount
                                else
                                        self.currentIndex = nextIndex
                                end
                        else
                                self.currentIndex = nextIndex
                        end
                end
        else
                if amount > 0 then
                        if nextIndex > itemsCount then
                                local col = (self.currentIndex - 1) % self.ROW_LEN
                                self.currentIndex = col + 1
                                self:scroll(-self.startRowIndex + 1)
                        else
                                self.currentIndex = nextIndex
                                local currentRow = math.ceil(self.currentIndex / self.ROW_LEN)
                                local lastVisibleRow = self.startRowIndex + self.maxVisibleRows - 1

                                if currentRow > lastVisibleRow then
                                        self:scroll(currentRow - lastVisibleRow)
                                end
                        end
                elseif amount < 0 then
                        if nextIndex < 1 then
                                local col = (self.currentIndex - 1) % self.ROW_LEN

                                if col >= itemsCount then
                                        self.currentIndex = itemsCount
                                else
                                        local targetRow = math.floor((itemsCount - col - 1) / self.ROW_LEN)
                                        self.currentIndex = targetRow * self.ROW_LEN + col + 1
                                end
                                -- Scroll to the end when wrapping
                                local lastRow = self:getAllRowsCount()
                                self:scroll(lastRow - self.startRowIndex - self.maxVisibleRows + 1)
                        else
                                self.currentIndex = nextIndex
                                local currentRow = math.ceil(self.currentIndex / self.ROW_LEN)

                                if currentRow < self.startRowIndex then
                                        self:scroll(currentRow - self.startRowIndex)
                                end
                        end
                end
        end


        self:highlight(nil, true)
end

return ScrollableGrid
