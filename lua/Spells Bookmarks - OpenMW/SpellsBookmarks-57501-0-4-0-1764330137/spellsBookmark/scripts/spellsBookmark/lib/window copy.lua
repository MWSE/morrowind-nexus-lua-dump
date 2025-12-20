-- local ui = require('openmw.ui')
-- local I = require('openmw.interfaces')
-- local async = require('openmw.async')
-- local util = require('openmw.util')
-- -- local self = require('openmw.self')
-- local types = require('openmw.types')

-- local templates = require('scripts.spellsBookmark.lib.myTemplates')
-- local colors = require('scripts.spellsBookmark.lib.myConstants').colors
-- local textures = require('scripts.spellsBookmark.lib.myConstants').textures
-- local titleFlex = require('scripts.spellsBookmark.lib.myGUI').titleFlex
-- local makeInt = require('scripts.spellsBookmark.lib.myGUI').makeInt

-- -- local TabManager = require('scripts.spellsBookmark.lib.Tab')
-- local createTabs = require('scripts.spellsBookmark.lib.Tab')


-- ---@type ui.Element|{}
-- local window = {}

-- local resizeBegin = false
-- local initialMouseX = 0
-- local initialMouseY = 0
-- local initialSizeX = 0
-- local initialSizeY = 0
-- local MOVE_ANCHOR_X = 0.5
-- local MOVE_ANCHOR_Y = 0.04

-- local MIN_WINDOW_W = 180
-- local MIN_WINDOW_H = 150

-- ---@type Vector2
-- local newSize = util.vector2(MIN_WINDOW_W, MIN_WINDOW_H)
-- ---@type Vector2
-- local newPos = util.vector2(0, 200)
-- ---@type Vector2
-- local newAnchor = util.vector2(0, 0)

-- local DRAG_AREA = 12

-- local function getWindowProps()
--         return {
--                 pos = newPos,
--                 size = newSize,
--                 anchor = newAnchor,
--         }
-- end

-- local function setWindowProps(p)
--         newPos = util.vector2(p[1], p[2])
--         newSize = util.vector2(p[3], p[4])
--         newAnchor = util.vector2(p[5], p[6])
-- end

-- ---@param e MouseEvent
-- ---@param layout ui.Layout
-- ---@param anchX number
-- ---@param anchY number
-- local function initResize(e, layout, anchX, anchY)
--         if not resizeBegin then
--                 resizeBegin = true

--                 initialSizeX = layout.props.size.x
--                 initialSizeY = layout.props.size.y
--                 initialMouseX = e.position.x
--                 initialMouseY = e.position.y
--                 local anchorDX = anchX - layout.props.anchor.x
--                 local anchorDY = anchY - layout.props.anchor.y
--                 local newPosX = layout.props.position.x + initialSizeX * anchorDX
--                 local newPosY = layout.props.position.y + initialSizeY * anchorDY
--                 layout.props.position = util.vector2(newPosX, newPosY)
--                 layout.props.anchor = util.vector2(anchX, anchY)
--                 newAnchor = layout.props.anchor
--                 newPos = layout.props.position
--         end
-- end

-- ---@param e MouseEvent
-- ---@param layout ui.Layout
-- ---@return boolean
-- local function resizWindow(e, layout)
--         if e.button == 1 then
--                 if e.offset.x < DRAG_AREA then
--                         if e.offset.y < DRAG_AREA then
--                                 -- TOP LEFT
--                                 initResize(e, layout, 1, 1)
--                         elseif e.offset.y > layout.props.size.y - DRAG_AREA then
--                                 -- BOTTOM LEFT
--                                 initResize(e, layout, 1, 0)
--                         end
--                 elseif e.offset.x > layout.props.size.x - DRAG_AREA then
--                         if e.offset.y < DRAG_AREA then
--                                 -- TOP RIGHT
--                                 initResize(e, layout, 0, 1)
--                         elseif e.offset.y > layout.props.size.y - DRAG_AREA then
--                                 -- BOTTOM RIGHT
--                                 initResize(e, layout, 0, 0)
--                         end
--                 end
--         else
--                 resizeBegin = false
--                 return false
--         end

--         if resizeBegin then
--                 local newWidth, newHeight

--                 if layout.props.anchor.x == 0 then
--                         -- Right side anchor
--                         newWidth = initialSizeX + (e.position.x - initialMouseX)
--                 else
--                         -- Left side anchor
--                         newWidth = initialSizeX - (e.position.x - initialMouseX)
--                 end

--                 if layout.props.anchor.y == 0 then
--                         -- Bottom side anchor
--                         newHeight = initialSizeY + (e.position.y - initialMouseY)
--                 else
--                         -- Top side anchor
--                         newHeight = initialSizeY - (e.position.y - initialMouseY)
--                 end

--                 local newSizeX = math.max(newWidth, MIN_WINDOW_W)
--                 local newSizeY = math.max(newHeight, MIN_WINDOW_H)
--                 -- local newSizeX = math.max(newWidth, 190)
--                 -- local newSizeY = math.max(newHeight, 138)

--                 layout.props.size = util.vector2(newSizeX, newSizeY)
--                 newSize = layout.props.size
--                 return true
--         end

--         return false
-- end

-- ---@param e MouseEvent
-- ---@param layout ui.Layout
-- ---@return boolean
-- local function moveWindow(e, layout)
--         if e.button == 1 then
--                 layout.props.anchor = util.vector2(MOVE_ANCHOR_X, MOVE_ANCHOR_Y)

--                 local newX = math.min(
--                         math.max(e.position.x, layout.props.size.x / 2),
--                         (Res.x / Scale) - layout.props.size.x / 2
--                 )


--                 local newY = math.min(
--                         math.max(e.position.y, MOVE_ANCHOR_Y * layout.props.size.y),
--                         (Res.y / Scale) - layout.props.size.y + MOVE_ANCHOR_Y * layout.props.size.y
--                 )


--                 -- layout.props.position = e.position
--                 layout.props.position = util.vector2(newX, newY)
--                 newPos = layout.props.position
--                 newAnchor = layout.props.anchor
--                 return true
--         end
--         return false
-- end


-- ---@param args { title: string, tabs: Tab[], defaultTab: string }
-- ---@return ui.Element
-- local function createResizableWindow(args)
--         Res = ui.screenSize()
--         Scale = Res.x / ui.layers[1].size.x
--         local title = args.title
--         local titleHover = false

--         -- local tabManager = TabManager.create()

--         -- tabManager.setOnTabChange(function()
--         --         if window.layout then
--         --                 window:update()
--         --         end
--         -- end)

--         local tabManager = createTabs(args.tabs, 1)


--         local tabBarLayouts = {}
--         for _, tab in pairs(tabManager.tabsList) do
--                 table.insert(tabBarLayouts, tab.element)
--         end

--         local windowLayout = {
--                 layer = "Windows",
--                 template = templates.getTemplate('thick', { 6, 6, 6, 6 }, true, textures.black),
--                 props = {
--                         position = util.vector2(newPos.x or 30, newPos.y or 30),
--                         size = util.vector2(newSize.x or MIN_WINDOW_W, newSize.y or MIN_WINDOW_H),
--                         anchor = util.vector2(newAnchor.x or 0, newAnchor.y or 0),
--                         arrange = ui.ALIGNMENT.Center,
--                         align = ui.ALIGNMENT.Start,
--                 },
--                 userData = {
--                         tabManager = tabManager
--                 },
--                 content = ui.content {
--                         {
--                                 name = 'mainFlex',
--                                 type = ui.TYPE.Flex,
--                                 props = {
--                                         relativeSize = util.vector2(1, 1),
--                                         horizontal = false,
--                                 },
--                                 content = ui.content {
--                                         --- Title Bar
--                                         {
--                                                 template = templates.getTemplate('none', { 0, 0, 0, 0 }, true, textures.menuBG, false, true),
--                                                 props = {
--                                                         size = util.vector2(0, 17),
--                                                         relativeSize = util.vector2(1, 0),
--                                                         horizontal = true,
--                                                         arrange = ui.ALIGNMENT.Center,
--                                                         align = ui.ALIGNMENT.Center,
--                                                 },
--                                                 events = {
--                                                         mousePress = async:callback(function()
--                                                                 titleHover = true
--                                                         end),
--                                                         mouseRelease = async:callback(function()
--                                                                 titleHover = false
--                                                         end)
--                                                 },
--                                                 content = ui.content {
--                                                         {
--                                                                 template = titleFlex,
--                                                                 props = {
--                                                                         position = util.vector2(0, -2),
--                                                                         size = util.vector2(0, 15),
--                                                                         arrange = ui.ALIGNMENT.Center,
--                                                                 },
--                                                                 content = ui.content {
--                                                                         {
--                                                                                 template = I.MWUI.templates.textNormal,
--                                                                                 props = {
--                                                                                         text = title,
--                                                                                         textSize = 14,
--                                                                                 },
--                                                                         },
--                                                                 }
--                                                         },
--                                                 }
--                                         },
--                                         makeInt(0, 3),
--                                         --- Tabs
--                                         {
--                                                 type = ui.TYPE.Flex,
--                                                 props = { horizontal = true },
--                                                 -- content = ui.content(tabBarLayouts)
--                                                 content = ui.content(tabBarLayouts)
--                                         },
--                                         makeInt(0, 3),
--                                         --- Current Content
--                                         tabManager.contentContainer
--                                 }
--                         }
--                 },
--                 events = {
--                         focusGain = async:callback(function(e, l)
--                                 titleHover = false
--                         end),
--                         mouseMove = async:callback(function(e, layout)
--                                 if titleHover then
--                                         moveWindow(e, layout)
--                                         window:update()
--                                 elseif resizWindow(e, layout) then
--                                         window:update()
--                                 end
--                         end),
--                 }
--         }

--         window = ui.create(windowLayout)
--         return window
--         -- return window, tabManager -- Return both for external control if needed
-- end


-- return {
--         createResizableWindow = createResizableWindow,
--         getWindowProps = getWindowProps,
--         setWindowProps =
--             setWindowProps
-- }
