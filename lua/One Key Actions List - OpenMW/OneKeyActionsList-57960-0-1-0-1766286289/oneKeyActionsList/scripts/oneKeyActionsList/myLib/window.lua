local ui          = require('openmw.ui')
local I           = require('openmw.interfaces')
local async       = require('openmw.async')
local util        = require('openmw.util')
local types       = require('openmw.types')
local myVars      = require('scripts.oneKeyActionsList.myLib.myVars')
local myGUI       = require('scripts.oneKeyActionsList.myLib.myGUI')
local myTemplates = require('scripts.oneKeyActionsList.myLib.myTemplates')
local textures    = require('scripts.oneKeyActionsList.myLib.myConstants').textures
local createTabs  = require('scripts.oneKeyActionsList.myLib.Tab')

---@class Window
---@field title string
---@field element ui.Element|{}
local o           = {}
local Window      = o
o.__index         = o

---@return ui.Layout
function o:getTitleBarLayout()
        return {
                template = myTemplates.getTemplate('none', { 0, 0, 0, 0 }, true, textures.menuBG, 1, false, true),
                props = {
                        size = util.vector2(0, 17),
                        relativeSize = util.vector2(1, 0),
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        {
                                template = myGUI.titleFlex,
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

---@param title string
---@param tabsData Tab[]
---@param alpha number
-- -@param mainContent ui.Layout
---@return Window
-- function o:new(title, mainContent, tabsData)
function o:new(title, tabsData, alpha)
        ---@class Window
        local inst = setmetatable({}, self)
        inst.title = title

        local tabManager = createTabs(tabsData, 1)
        inst.tabManager = tabManager

        local tabBarsLayouts = {}
        for i = 1, #tabManager.tabsList do
                table.insert(tabBarsLayouts, tabManager.tabsList[i].element)
        end


        inst.element = ui.create {
                layer = "Windows",
                template = myTemplates.getTemplate('thick', { 6, 6, 6, 5 }, true, textures.black, alpha),
                props = {
                        relativePosition = util.vector2(0.5, 0.5),
                        -- size = util.vector2(300, 300),
                        size = util.vector2(myVars.res.x - 20, myVars.res.y - 20),
                        anchor = util.vector2(0.5, 0.5),
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Start,
                },
                content = ui.content {
                        {
                                name = 'mainFlex',
                                type = ui.TYPE.Flex,
                                props = {
                                        relativeSize = util.vector2(1, 1),
                                },
                                content = ui.content {
                                        --- Title bar
                                        inst:getTitleBarLayout(),
                                        myGUI.makeInt(0, 3),
                                        {
                                                template = I.MWUI.templates.horizontalLine,
                                        },
                                        myGUI.makeInt(0, 3),
                                        {
                                                template = I.MWUI.templates.horizontalLine,
                                        },

                                        --- Tabs
                                        {
                                                type = ui.TYPE.Flex,
                                                props = { horizontal = true },
                                                content = ui.content(tabBarsLayouts)
                                        },
                                        -- myGUI.makeInt(0, 3),

                                        {
                                                template = I.MWUI.templates.horizontalLine,
                                        },

                                        myGUI.makeInt(0, 8),
                                        --- Content
                                        {
                                                type = ui.TYPE.Flex,
                                                -- template = I.MWUI.myTemplates.borders,
                                                external = { grow = 1, stretch = 1 },
                                                props = {
                                                        -- relativeSize = util.vector2(1, 1),
                                                        -- size = util.vector2(100, 1),
                                                },

                                                content = ui.content {

                                                        inst.tabManager.contentContainer
                                                }
                                        },
                                }
                        }
                },
        }



        return inst
end

return Window
