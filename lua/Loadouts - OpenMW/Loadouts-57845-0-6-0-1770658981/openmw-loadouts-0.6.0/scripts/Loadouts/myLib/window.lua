local ui         = require('openmw.ui')
local I          = require('openmw.interfaces')
local async      = require('openmw.async')
local util       = require('openmw.util')
local createTabs = require('scripts.Loadouts.myLib.Tab')
local textures   = require('scripts.Loadouts.myLib.myConstants').textures
local templates  = require('scripts.Loadouts.myLib.myTemplates')
local gui        = require('scripts.Loadouts.myLib.myGUI')
local myVars     = require('scripts.Loadouts.myLib.myVars')
local toolTip    = require('scripts.Loadouts.myLib.toolTip')


local DRAG_AREA      = 5
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
function o:resizWindow(e, layout)
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
                        myVars.res.x - layout.props.size.x + self.MOVE_ANCHOR_X * layout.props.size.x
                )
                local newY = math.min(
                        math.max(e.position.y, self.MOVE_ANCHOR_Y * layout.props.size.y),
                        myVars.res.y - layout.props.size.y + self.MOVE_ANCHOR_Y * layout.props.size.y
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
                type = ui.TYPE.Image,
                external = { grow = 0, stretch = 1 },
                props = {
                        resource = textures.menuBG,
                        size = util.vector2(1, 18),
                        anchor = util.vector2(0.5, 0.5),
                        tileH = true,
                },
                content = ui.content {
                        {
                                template = gui.titleFlex,
                                props = {
                                        relativeSize = util.vector2(0, 1),
                                        relativePosition = util.vector2(0.5, 0.5),
                                        anchor = util.vector2(0.5, 0.5),
                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        text = string.format(' %s ', self.title),
                                                        textSize = 14,
                                                }
                                        },
                                }
                        },
                },
                events = {
                        ---@param e MouseEvent
                        mousePress = async:callback(function(e)
                                if e.button ~= 1 then return end
                                self.MOVE_ANCHOR_X = math.min(e.offset.x / self.size.x, 1)
                                self.MOVE_ANCHOR_Y = math.min(e.offset.y / self.size.y, 1)
                                self.isDraggingTitleBar = true
                                return true
                        end),
                        mouseRelease = async:callback(function()
                                self.isDraggingTitleBar = false
                                return true
                        end)
                },
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

---@param title string
---@param x number
---@param y number
---@param tabsData Tab[]
---@param max? boolean
---@return myWindow
function o:new(title, x, y, tabsData, max, alpha)
        ---@class myWindow : Window
        local inst = setmetatable({}, self)
        inst.title = title
        inst.isDraggingTitleBar = false
        inst.max = max


        if max then
                inst.pos = nil
                inst.relativePosition = util.vector2(0.5, 0.5)
                inst.size = util.vector2(myVars.res.x - 20, myVars.res.y - 20)
                inst.anchor = util.vector2(0.5, 0.5)
        else
                if not self.windowsProps[title] then
                        self.windowsProps[title] = {}
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
                template = templates.getTemplate('thick', { 4, 4, 4, 3 }, textures.black, nil, nil, alpha),
                -- template = templates.getTemplate_3 {
                --         border = 'thick',
                --         bg = textures.black,
                --         alpha = alpha
                -- },
                -- template = I.MWUI.templates.bordersThick,

                props = {
                        position = inst.pos,
                        relativePosition = inst.relativePosition,
                        size = inst.size,
                        anchor = inst.anchor,
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Start,
                },
                -- external = { grow = 1, stretch = 1 },

                content = ui.content {
                        {
                                name = 'mainFlex',
                                type = ui.TYPE.Flex,
                                external = { grow = 1, stretch = 1 },

                                props = {
                                        relativeSize = util.vector2(1, 1),
                                },
                                content = ui.content {

                                        --- Title bar
                                        inst:getTitleBarLayout(),
                                        {
                                                template = I.MWUI.templates.horizontalLine,
                                                props = {
                                                        size = util.vector2(1, 3),
                                                }
                                        },
                                        --- Tabs
                                        {
                                                type = ui.TYPE.Flex,
                                                props = { horizontal = true },
                                                content = ui.content(tabBarsLayouts)
                                        },
                                        {
                                                template = I.MWUI.templates.horizontalLine,
                                        },

                                        --- Content
                                        {
                                                type = ui.TYPE.Flex,
                                                -- template = I.MWUI.templates.borders,
                                                external = { grow = 1, stretch = 1 },
                                                props = {
                                                        relativeSize = util.vector2(1, 1)
                                                },

                                                content = ui.content {

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
                        mouseMove = async:callback(function(e, layout)
                                toolTip.currentId = nil
                                toolTip.closed = true
                                if inst.max then return end
                                if inst.isDraggingTitleBar then
                                        inst:moveWindow(e, layout)
                                        inst.element:update()
                                        inst:setProps()
                                elseif inst:resizWindow(e, layout) then
                                        inst.element:update()
                                        inst:setProps()
                                end
                                return true
                        end),
                }
        }

        return inst
end

return Window
