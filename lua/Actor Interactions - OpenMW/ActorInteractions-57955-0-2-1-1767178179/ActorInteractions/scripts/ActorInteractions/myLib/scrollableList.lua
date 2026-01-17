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

---@class ScrollableList
---@field key string
---@field focus boolean
---@field arrow table
---@field startElIndex number
---@field currentIndex number
---@field maxVisibleItems number
---@field visibleElements ui.Layout[]
---@field element ui.Layout
---@field elements ScrollableItem[]
---@field upArrow ui.Layout
---@field downArrow ui.Layout
---@field getItems fun(): ScrollableItem[]
---@field getLayout fun(item: ScrollableItem, index: number): ui.Layout
---@field extraItemsCount number
---@field updateParentElement function
---@field listNext fun(self:ScrollableList, dir: number)
---@field selectCurrent fun(self: ScrollableList, index?: number)
---@field scroll fun(self: ScrollableList, amount:number)
---@field highlight fun(self: ScrollableList, index: number|nil, forcePosition: boolean)
---@field deHighlight fun(self: ScrollableList, index?: number)
---@field updateItems fun(self: ScrollableList, index?: number)
---@field listExact fun(self: ScrollableList, index: number)
---@field ROW_LEN number
local o = {}
local ScrollableList = o

o.__index = o
-- -@type table<string, ScrollableList>
-- o.all = {}

o.cached = {}


---@class ListGetters
---@field getItems fun(): ScrollableItem[]
---@field getLayout? fun(item: ScrollableItem, index?: number): ui.Layout
---@field getAllLayouts? fun(self: ScrollableList): ui.Layout[]
---@field extraItemsCount? number
---@field maxVisibleItems? number
---@field updateParentElement function

---@param getters ListGetters
---@return ScrollableList
function o:new(key, getters)
        local inst = setmetatable({}, o)

        inst.key = key
        inst.focus = false
        inst.arrow = {
                up = { focus = false, press = false },
                down = { focus = false, press = false }
        }
        inst.startElIndex = 1
        inst.currentIndex = 1

        inst.updateParentElement = getters.updateParentElement

        inst.ROW_LEN = 10

        inst.maxVisibleItems = getters.maxVisibleItems or
            math.floor((myVars.res.y * 0.8) / myConstants.sizes.LIST_TEXT_SIZE)
        inst.visibleElements = {}

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
                                inst:scroll(inst.maxVisibleItems - 1)
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
                                inst:scroll(-inst.maxVisibleItems + 1)
                                return true
                        end)
                }
        }

        -- inst.element = ui.create {
        inst.element = {
                type = ui.TYPE.Flex,
                template = I.MWUI.templates.bordersThick,
                external = { grow = 1, stretch = 1 },
                content = ui.content {
                        myGUI.makeInt(0, 4),
                        inst.upArrow,
                        {
                                name = 'listContent',
                                type = ui.TYPE.Flex,
                                external = { grow = 1, stretch = 1 },
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

        inst.getItems = getters.getItems
        inst.getLayout = getters.getLayout
        inst.extraItemsCount = getters.extraItemsCount or 0

        -- function inst:getAllLayouts()
        --         return getters.getAllLayouts(inst)
        -- end

        inst:updateItems()

        -- o.all[key] = inst


        myVars.currentScrollable = inst

        return inst
end

function o:getAllItemsCount()
        return #self.elements + self.extraItemsCount
end

function o:updateItems()
        self.elements = self.getItems()
        self:getVisibleElements()
end

function o:getVisibleElements()
        self.visibleElements = {}
        local lastIndex = self.startElIndex + self.maxVisibleItems

        if lastIndex > self:getAllItemsCount() then
                lastIndex = self:getAllItemsCount()
        end

        if self.getLayout then
                for i = self.startElIndex, lastIndex do
                        local item = self.elements[i]

                        -- local layout
                        -- if item.id then
                        --         if self.cached[item.id] then
                        --                 layout = self.cached[item.id]
                        --                 layout.template = nil
                        --         else
                        --                 layout = self.getLayout(item, i)
                        --                 self.cached[item.id] = layout
                        --         end
                        -- else
                        --         layout = self.getLayout(item, i)
                        -- end
                        local layout = self.getLayout(item, i)


                        table.insert(self.visibleElements, layout)
                end

                -- elseif self.getAllLayouts then
                -- NO
                -- local all = self:getAllLayouts()
                -- for i = self.startElIndex, lastIndex do
                --         table.insert(self.visibleElements, all[i])
                -- end
        else
                error('No layout getter provided')
        end

        if lastIndex < self:getAllItemsCount() then
                self.downArrow.props.alpha = 1
        else
                self.downArrow.props.alpha = 0.2
        end

        if self.startElIndex ~= 1 then
                self.upArrow.props.alpha = 1
        else
                self.upArrow.props.alpha = 0.2
        end

        if self.currentIndex < self.startElIndex then
                self.currentIndex = self.startElIndex
        elseif self.currentIndex > lastIndex then
                self.currentIndex = lastIndex
        end



        self:setContent()
end

function o:setContent()
        if #self.visibleElements == 0 then
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
                self.element.content.listContent.content = ui.content(self.visibleElements)
        end
        self:highlight(nil, true)
end

function o:listExact(index)
        self:deHighlight()
        self.currentIndex = index

        if self.currentIndex > self:getAllItemsCount() then
                self.currentIndex = self:getAllItemsCount()
        elseif self.currentIndex < 1 then
                self.currentIndex = 1
        end

        if self.currentIndex >= self.startElIndex + self.maxVisibleItems then
                self:scroll(self.currentIndex - (self.startElIndex + self.maxVisibleItems))
        elseif self.currentIndex < self.startElIndex then
                self:scroll(-1)
        else
                self:highlight(nil, true)
        end
end

function o:scroll(amount)
        self.startElIndex = self.startElIndex + amount

        if self.startElIndex < 1 then
                self.startElIndex = 1
        end

        if self.startElIndex + self.maxVisibleItems > self:getAllItemsCount() then
                self.startElIndex = math.max(1, self:getAllItemsCount() - self.maxVisibleItems)
        end

        self:getVisibleElements()
end

function o:listNext(dir)
        self:deHighlight()

        self.currentIndex = self.currentIndex + dir

        if self.currentIndex > self:getAllItemsCount() then
                self.currentIndex = self:getAllItemsCount()
        elseif self.currentIndex < 1 then
                self.currentIndex = 1
        end

        if self.currentIndex > self.startElIndex + self.maxVisibleItems then
                self:scroll(1)
        elseif self.currentIndex < self.startElIndex then
                self:scroll(-1)
        end

        self:highlight(nil, true)
end

function o:deHighlight(index)
        -- if not self.element.layout then return end
        if not self.element then return end
        self.currentIndex = index or self.currentIndex
        local visibleIndex = self.currentIndex - self.startElIndex + 1
        local visibleLayout = self.visibleElements[visibleIndex]
        if not visibleLayout then return end
        visibleLayout.template = nil

        self.updateParentElement()
end

---@param index number
---@param forcePosition boolean
function o:highlight(index, forcePosition)
        if not self.element then return end
        self.currentIndex = index or self.currentIndex
        local visibleIndex = self.currentIndex - self.startElIndex + 1
        ---@type ui.Layout
        local visibleLayout = self.visibleElements[visibleIndex]
        if not visibleLayout then return end
        visibleLayout.template = myTemplates.highlight

        self.updateParentElement()

        toolTip.closed = nil
        myUtils.debounce('showToolTip', 0.4, function()
                if self.element and visibleLayout.userData.item then
                        toolTip.showToolTip(visibleLayout.userData.item, forcePosition)
                end
        end)

        -- if showToolTip then
        -- end
end

---@param index number
function o:selectCurrent(index)
        self.currentIndex = index or self.currentIndex
        local visibleIndex = self.currentIndex - self.startElIndex + 1
        local visibleLayout = self.visibleElements[visibleIndex]

        if visibleLayout then
                self:deHighlight()
                visibleLayout.events.mousePress({ button = 1 }, visibleLayout)
        end

        self:highlight(nil, true)
end

return ScrollableList
