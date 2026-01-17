local ui = require('openmw.ui')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local util = require('openmw.util')

local myConstants = require('scripts.Loadouts.myLib.myConstants')
local myTemplates = require('scripts.Loadouts.myLib.myTemplates')
local myVars = require('scripts.Loadouts.myLib.myVars')

---@class ScrollableList
---@field key string
---@field focus boolean
---@field arrow table
---@field startElIndex number
---@field maxVisibleItems number
---@field elements ui.Element[]
---@field visibleElements ui.Element[]
---@field element ui.Element
---@field upArrow ui.Layout
---@field downArrow ui.Layout
local o = {}
local ScrollableList = o

o.__index = o
---@type table<string, ScrollableList>
o.all = {}

---@param elements ui.Element[]
---@return table
function o:new(key, elements)
        local inst = setmetatable({}, o)

        inst.key = key
        inst.focus = false
        inst.arrow = {
                up = { focus = false, press = false },
                down = { focus = false, press = false }
        }
        inst.startElIndex = 1
        inst.maxVisibleItems = math.floor((myVars.res.y * 0.8) / myConstants.sizes.LIST_TEXT_SIZE)
        -- print(inst.maxVisibleItems)
        inst.elements = elements or {}

        inst.visibleElements = {}


        inst.downArrow = {
                type = ui.TYPE.Flex,
                template = myTemplates.iconFrame,
                props = {
                        size = util.vector2(0, 16),
                        relativeSize = util.vector2(1, 0),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = myConstants.textures.downArrow,
                                        size = util.vector2(16, 16),
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
                template = myTemplates.iconFrame,
                props = {
                        size = util.vector2(0, 16),
                        relativeSize = util.vector2(1, 0),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = myConstants.textures.upArrow,
                                        size = util.vector2(16, 16),
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


        inst.element = ui.create {
                type = ui.TYPE.Flex,
                -- template = myTemplates.iconFrame,
                props = {
                        horizontal = false,
                        size = util.vector2(400, 1),
                },
                content = ui.content {

                        inst.upArrow,
                        {
                                name = 'listContent',
                                type = ui.TYPE.Flex,
                                external = { grow = 1, stretch = 1 },
                                props = {
                                        horizontal = false,
                                },
                                -- template = myTemplates.iconFrame,
                                content = ui.content(inst.visibleElements)
                        },
                        inst.downArrow

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

        inst:getVisibleElements()

        o.all[key] = inst

        return inst
end

function o:getVisibleElements()
        self.visibleElements = {}
        local lastIndex = self.startElIndex + self.maxVisibleItems
        for i = self.startElIndex, lastIndex do
                table.insert(self.visibleElements, self.elements[i])
        end

        if lastIndex < #self.elements then
                self.downArrow.props.visible = true
        else
                self.downArrow.props.visible = false
        end

        if self.startElIndex ~= 1 then
                self.upArrow.props.visible = true
        else
                self.upArrow.props.visible = false
        end


        self:setContent()
end

function o:setContent()
        ---@diagnostic disable-next-line: undefined-field
        self.element.layout.content.listContent.content = ui.content(self.visibleElements)
        self.element:update()
end

function o:scroll(amount)
        self.startElIndex = self.startElIndex + amount

        if self.startElIndex < 1 then
                self.startElIndex = 1
        end

        if self.startElIndex + self.maxVisibleItems > #self.elements then
                self.startElIndex = math.max(1, #self.elements - self.maxVisibleItems)
        end

        self:getVisibleElements()
end

return ScrollableList
