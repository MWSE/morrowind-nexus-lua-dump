local ui             = require('openmw.ui')
local I              = require('openmw.interfaces')
local async          = require('openmw.async')
local util           = require('openmw.util')
local createTabs     = require('scripts.ActorInteractions.myLib.Tab')
local textures       = require('scripts.ActorInteractions.myLib.myConstants').textures
local templates      = require('scripts.ActorInteractions.myLib.myTemplates')
local gui            = require('scripts.ActorInteractions.myLib.myGUI')
local myVars         = require('scripts.ActorInteractions.myLib.myVars')
local myUtils        = require('scripts.ActorInteractions.myLib.myUtils')
local toolTip        = require('scripts.ActorInteractions.myLib.toolTip')

local DRAG_AREA      = 12
local MIN_WINDOW_W   = 640
local MIN_WINDOW_H   = 440

---@class Window
local o              = {}
local Window         = o
o.__index            = o
o.title              = nil
o.isDraggingTitleBar = false

o.resizeBegin        = false
o.initialMouseX      = 0
o.initialMouseY      = 0
o.initialSizeX       = 0
o.initialSizeY       = 0
o.MOVE_ANCHOR_X      = 0
o.MOVE_ANCHOR_Y      = 0
o.pos                = nil
o.size               = nil
o.anchor             = nil
o.windowsProps       = {}
o.element            = {}

---@param e MouseEvent
---@param layout ui.Layout
---@param anchX number
---@param anchY number
function o:initResize(e, layout, anchX, anchY)
        if not self.resizeBegin then
                self.resizeBegin = true

                self.initialSizeX = layout.props.size.x
                self.initialSizeY = layout.props.size.y
                self.initialMouseX = e.position.x
                self.initialMouseY = e.position.y

                local anchorDX = anchX - layout.props.anchor.x
                local anchorDY = anchY - layout.props.anchor.y
                local newPosX = layout.props.position.x + self.initialSizeX * anchorDX
                local newPosY = layout.props.position.y + self.initialSizeY * anchorDY
                layout.props.position = util.vector2(newPosX, newPosY)
                layout.props.anchor = util.vector2(anchX, anchY)
                self.anchor = layout.props.anchor
                self.pos = layout.props.position
        end
end

---@param e MouseEvent
---@param layout ui.Layout
---@return boolean
function o:resizeWindow(e, layout)
        if e.button == 1 then
                if e.offset.x < DRAG_AREA then
                        if e.offset.y < DRAG_AREA then
                                -- TOP LEFT
                                self:initResize(e, layout, 1, 1)
                        elseif e.offset.y > layout.props.size.y - DRAG_AREA then
                                -- BOTTOM LEFT
                                self:initResize(e, layout, 1, 0)
                        end
                elseif e.offset.x > layout.props.size.x - DRAG_AREA then
                        if e.offset.y < DRAG_AREA then
                                -- TOP RIGHT
                                self:initResize(e, layout, 0, 1)
                        elseif e.offset.y > layout.props.size.y - DRAG_AREA then
                                -- BOTTOM RIGHT
                                self:initResize(e, layout, 0, 0)
                        end
                end
        else
                self.resizeBegin = false
                return false
        end

        if self.resizeBegin then
                local newWidth, newHeight

                if layout.props.anchor.x == 0 then
                        -- Right side anchor
                        newWidth = self.initialSizeX + (e.position.x - self.initialMouseX)
                else
                        -- Left side anchor
                        newWidth = self.initialSizeX - (e.position.x - self.initialMouseX)
                end

                if layout.props.anchor.y == 0 then
                        -- Bottom side anchor
                        newHeight = self.initialSizeY + (e.position.y - self.initialMouseY)
                else
                        -- Top side anchor
                        newHeight = self.initialSizeY - (e.position.y - self.initialMouseY)
                end

                local newSizeX = math.max(newWidth, MIN_WINDOW_W)
                local newSizeY = math.max(newHeight, MIN_WINDOW_H)

                layout.props.size = util.vector2(newSizeX, newSizeY)
                self.size = layout.props.size
                -- print(self.size)
                return true
        end

        return false
end

---@param e MouseEvent
---@param layout ui.Layout
---@return boolean
function o:moveWindow(e, layout)
        if e.button == 1 then
                layout.props.anchor = util.vector2(self.MOVE_ANCHOR_X, self.MOVE_ANCHOR_Y)
                local newX = math.min(
                        math.max(e.position.x, self.MOVE_ANCHOR_X * layout.props.size.x),
                        (myVars.res.x / myVars.scale) - layout.props.size.x + self.MOVE_ANCHOR_X * layout.props.size.x
                )
                local newY = math.min(
                        math.max(e.position.y, self.MOVE_ANCHOR_Y * layout.props.size.y),
                        (myVars.res.y / myVars.scale) - layout.props.size.y + self.MOVE_ANCHOR_Y * layout.props.size.y
                )
                layout.props.position = util.vector2(newX, newY)
                self.pos = layout.props.position
                self.anchor = layout.props.anchor
                return true
        end
        return false
end

---@return ui.Layout
function o:getTitleBarLayout()
        return {
                template = templates.getTemplate('none', { 0, 0, 0, 0 }, true, textures.menuBG, false, true),
                props = {
                        size = util.vector2(0, 17),
                        relativeSize = util.vector2(1, 0),
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Center,
                },
                events = {
                        ---@param e MouseEvent
                        mousePress = async:callback(function(e)
                                self.isDraggingTitleBar = true
                                self.MOVE_ANCHOR_X = e.offset.x / self.size.x
                                self.MOVE_ANCHOR_Y = e.offset.y / self.size.y
                        end),
                        mouseRelease = async:callback(function()
                                self.isDraggingTitleBar = false
                        end)
                },
                content = ui.content {
                        {
                                template = gui.titleFlex,
                                props = {
                                        position = util.vector2(0, -2),
                                        size = util.vector2(0, 15),
                                        arrange = ui.ALIGNMENT.Center,
                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        text = self.title,

                                                        textSize = 14,
                                                },
                                        },
                                }
                        },
                }
        }
end

function o:getProps()
        self.pos = self.windowsProps[self.title].pos
        self.size = self.windowsProps[self.title].size
        self.anchor = self.windowsProps[self.title].anchor
end

function o:setProps()
        self.windowsProps[self.title].pos = self.pos
        self.windowsProps[self.title].size = self.size
        self.windowsProps[self.title].anchor = self.anchor
end

---@param key string
---@param title string
---@param x number
---@param y number
---@param tabsData Tab[]
---@param max? boolean
---@return myWindow
function o:new(key, x, y, tabsData, max, title)
        -- Res = ui.screenSize()
        -- Scale = Res.x / ui.layers[1].size.x

        ---@class myWindow : Window
        local inst = setmetatable({}, self)
        inst.key = key
        inst.title = title
        inst.isDraggingTitleBar = false
        inst.max = max


        if max then
                inst.pos = nil
                inst.relativePosition = util.vector2(0.5, 0.5)
                inst.size = util.vector2(myVars.res.x - 20, myVars.res.y - 20)
                inst.anchor = util.vector2(0.5, 0.5)
        else
                if not self.windowsProps[key] then
                        self.windowsProps[key] = {}
                        inst.pos = util.vector2(x, y)
                        inst.size = util.vector2(MIN_WINDOW_W, MIN_WINDOW_H)
                        inst.anchor = util.vector2(0, 0)

                        inst:setProps()
                else
                        inst:getProps()
                end
        end


        local tabManager = createTabs(tabsData, 1)
        inst.tabManager = tabManager

        local tabBarsLayouts = {}
        for i = 1, #tabManager.tabsList do
                table.insert(tabBarsLayouts, tabManager.tabsList[i].element)
        end


        inst.element = ui.create {
                layer = "Windows",
                -- type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.bordersThick,
                template = templates.getTemplate('thick', { 6, 6, 6, 5 }, true, textures.black),
                props = {
                        position = inst.pos,
                        relativePosition = inst.relativePosition,
                        size = inst.size,
                        anchor = inst.anchor,
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Start,
                },
                content = ui.content {
                        {
                                name = 'mainFlex',
                                type = ui.TYPE.Flex,
                                -- template = I.MWUI.templates.borders,
                                -- external = {grow = 1, stretch = 1},
                                props = {
                                        relativeSize = util.vector2(1, 1),
                                },
                                content = ui.content {

                                        --- Title bar
                                        inst:getTitleBarLayout(),
                                        gui.makeInt(0, 3),
                                        {
                                                template = I.MWUI.templates.horizontalLine,
                                        },

                                        --- Tabs
                                        {
                                                type = ui.TYPE.Flex,
                                                props = { horizontal = true },
                                                content = ui.content(tabBarsLayouts)
                                        },
                                        {
                                                type = ui.TYPE.Flex,
                                                template = I.MWUI.templates.borders,
                                                external = { grow = 1, stretch = 1 },
                                                props = {
                                                        -- relativeSize = util.vector2(1, 1),
                                                        -- size = util.vector2(100, 1),
                                                        -- align = ui.ALIGNMENT.Center,
                                                        -- arrange = ui.ALIGNMENT.Center,
                                                },

                                                content = ui.content {
                                                        gui.makeInt(0, 8),
                                                        inst.tabManager.contentContainer
                                                }
                                        },
                                }
                        }
                },
                events = {
                        focusGain = async:callback(function(e, l)
                                inst.isDraggingTitleBar = false
                        end),
                        focusLoss = async:callback(function(e, l)
                                if inst.max then return end
                                inst:setProps()
                        end),
                        mouseMove = async:callback(function(e, layout)
                                toolTip.currentId = nil
                                toolTip.closed = true
                                if inst.max then return true end
                                if inst.isDraggingTitleBar then
                                        inst:moveWindow(e, layout)
                                        inst.element:update()
                                elseif inst:resizeWindow(e, layout) then
                                        inst.element:update()
                                end
                                return true
                        end),
                }
        }

        return inst
end

return Window
