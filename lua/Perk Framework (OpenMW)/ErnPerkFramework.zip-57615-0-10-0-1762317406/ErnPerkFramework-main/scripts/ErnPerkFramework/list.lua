--[[
ErnPerkFramework for OpenMW.
Copyright (C) 2025 Erin Pentecost and ownlyme

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local MOD_NAME = require("scripts.ErnPerkFramework.settings").MOD_NAME
local pself = require("openmw.self")
local interfaces = require("openmw.interfaces")
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local core = require("openmw.core")
local localization = core.l10n(MOD_NAME)
local myui = require('scripts.ErnPerkFramework.pcp.myui')

local ListFunctions = {}
ListFunctions.__index = ListFunctions

function NewList(renderer, props)
    if type(renderer) ~= "function" then
        error("renderer must be a function")
    end
    local new = {
        topIndex = 1,
        selectedIndex = 1,
        displayCount = 16,
        totalCount = 1,
        renderer = renderer,
        containerElement = ui.create {
            name = 'listRoot',
            type = ui.TYPE.Flex,
            props = props or {
                horizontal = false,
                --autoSize = false,
                size = util.vector2(0, 480),
                relativeSize = util.vector2(1, 0),
            },
            content = ui.content {}
        },
        thumbElement = ui.create {
            type = ui.TYPE.Image,
            name = 'scrollThumb',
            props = {
                resource = ui.texture { path = 'white' },
                relativePosition = util.vector2(0, 0),
                relativeSize = util.vector2(1, 0),
                alpha = 0.4,
                color = myui.interactiveTextColors.normal.default,
            },
        },
        scrollBGElement = ui.create {
            type = ui.TYPE.Image,
            name = 'scrollBackground',
            props = {
                resource = ui.texture { path = 'white' },
                relativePosition = util.vector2(0, 0),
                relativeSize = util.vector2(1, 1),
                alpha = 0.625,
                color = util.color.rgb(0, 0, 0),
            },
            events = {},
        },
    }
    -- set root
    new.root = ui.create {
        type = ui.TYPE.Flex,
        template = interfaces.MWUI.templates.borders,
        props = { horizontal = true },
        content = ui.content {
            {
                type = ui.TYPE.Widget,
                template = interfaces.MWUI.templates.borders,
                props = {
                    size = util.vector2(20, 0),
                    relativeSize = util.vector2(0, 1),
                },
                content = ui.content {
                    new.scrollBGElement,
                    new.thumbElement
                }
            },
            myui.padWidget(8, 0),
            new.containerElement
        }
    }
    setmetatable(new, ListFunctions)
    -- hook up events
    new:setScrollBGEvents()
    new:setThumbEvents()
    return new
end

function ListFunctions.clamp(self, index)
    return ((index - 1) % self.totalCount) + 1
end

function ListFunctions.destroy(self)
    for _, old in ipairs(self.containerElement.layout.content) do
        old:destroy()
    end
    self.containerElement.layout.content = ui.content {}
end

function ListFunctions.height(self)
    return self.containerElement.layout.props.size.y
    --return 480
end

function ListFunctions.setThumbEvents(self)
    self.thumbElement.layout['events'] = {
        mousePress = async:callback(function(data, elem)
            if data.button == 1 then
                if not elem.userData then elem.userData = {} end
                elem.userData.isDragging = true
                elem.userData.dragStartY = data.position.y
                elem.userData.dragStartThumbY = elem.props.relativePosition.y * self:height()
            end
        end),

        mouseRelease = async:callback(function(_, elem)
            if elem.userData then
                elem.userData.isDragging = false
                self:update()
            end
        end),

        mouseMove = async:callback(function(data, elem)
            if elem.userData and elem.userData.isDragging then
                local totalItems = self.totalCount
                if totalItems <= self.displayCount then return end

                local scrollContainerHeight = self:height()
                local thumbHeight = (self.displayCount / self.totalCount) * scrollContainerHeight
                local availableScrollDistance = scrollContainerHeight - thumbHeight
                if availableScrollDistance <= 0 then return end

                local deltaY = data.position.y - elem.userData.dragStartY
                local newThumbY = math.max(0, math.min(
                    availableScrollDistance,
                    elem.userData.dragStartThumbY + deltaY
                ))

                elem.props.relativePosition = util.vector2(0, newThumbY / scrollContainerHeight)

                local newScrollPosition = newThumbY / availableScrollDistance
                local maxScrollIndex = math.max(1, totalItems - self.displayCount)
                self.selectedIndex = math.floor(newScrollPosition * (maxScrollIndex - 1) + 0.5) + 1
                self.topIndex = self.selectedIndex
                self.thumbElement:update()
            end
        end),

        focusGain = async:callback(function(_, elem)
            elem.props.alpha = 0.8
            self.thumbElement:update()
        end),

        focusLoss = async:callback(function(_, elem)
            elem.props.alpha = 0.4
            self.thumbElement:update()
        end),
    }
    self.thumbElement:update()
end

function ListFunctions.setScrollBGEvents(self)
    self.scrollBGElement.layout['events'] = {
        mousePress = async:callback(function(data, elem)
            local totalItems = self.totalCount
            if totalItems <= self.displayCount then return end
            local scrollAmount = math.ceil(self.displayCount / 3)

            local currentThumbY = self.thumbElement.layout.props.relativePosition.y * self:height()
            local clickY = data.offset.y
            if clickY < currentThumbY then
                self.selectedIndex = self:clamp(math.max(1, self.selectedIndex - scrollAmount))
            else
                self.selectedIndex = self:clamp(math.min(self.totalCount,
                    self.selectedIndex + scrollAmount))
            end
            self:update()
        end),
        focusGain = async:callback(function(_, elem)
            elem.props.alpha = 0.1
            elem.props.color = myui.interactiveTextColors.normal.default
            self.scrollBGElement:update()
        end),
        focusLoss = async:callback(function(_, elem)
            elem.props.alpha = 0.625
            elem.props.color = util.color.rgb(0, 0, 0)
            self.scrollBGElement:update()
        end)
    }
    self.scrollBGElement:update()
end

function ListFunctions.updateScrollbar(self)
    if self.totalCount <= self.displayCount then
        self.thumbElement.layout.props.relativeSize = util.vector2(1, 0)
        self.thumbElement.layout.props.relativePosition = util.vector2(0, 0)
    else
        local thumbHeight = self.displayCount / self.totalCount
        local scrollPosition = (1 - thumbHeight) * (self.topIndex - 1) / (self.totalCount - self.displayCount)
        self.thumbElement.layout.props.relativeSize = util.vector2(1, thumbHeight)
        self.thumbElement.layout.props.relativePosition = util.vector2(0, scrollPosition)
    end
    self.thumbElement:update()
    self.scrollBGElement:update()
end

function ListFunctions.update(self)
    -- delete all old content
    for _, old in ipairs(self.containerElement.layout.content) do
        old:destroy()
    end
    self.containerElement.layout.content = ui.content {}

    -- just wrap around infinitely
    self.topIndex = self:clamp(self.topIndex)
    self.selectedIndex = self:clamp(self.selectedIndex)

    -- if selectedIndex is outside our window, adjust the window.
    if self.selectedIndex < self.topIndex then
        self.topIndex = self.selectedIndex
    elseif self.selectedIndex > self.topIndex + self.displayCount - 1 then
        self.topIndex = self:clamp(self.selectedIndex - self.displayCount + 1)
    end

    -- make element items and insert them.
    -- we can show fewer items if the total count is less than display count
    for i = self.topIndex, self.topIndex + math.min(self.displayCount, self.totalCount) - 1 do
        local modI = self:clamp(i)
        local entryElement = self.renderer(modI, modI == self.selectedIndex)
        entryElement.layout['external'] = { grow = 1 }
        entryElement:update()
        table.insert(self.containerElement.layout.content, entryElement)
    end
    self.scrollBGElement:update()
    self.containerElement:update()
    self:updateScrollbar()
    self.root:update()
end

function ListFunctions.setTotal(self, total)
    if type(total) ~= "number" then
        error("total must be a number")
    end
    self.totalCount = total
    self.selectedIndex = self:clamp(self.selectedIndex)
end

function ListFunctions.setSelectedIndex(self, idx)
    self.selectedIndex = self:clamp(idx)
end

-- scroll 'step' indices. negative number is up. you want to call update afterward.
function ListFunctions.scroll(self, step)
    self.selectedIndex = self:clamp(self.selectedIndex + step)
end

return { NewList = NewList }
