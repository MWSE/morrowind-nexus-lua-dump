local templates = require('scripts.Loadouts.myLib.myTemplates')
local colors = require('scripts.Loadouts.myLib.myConstants').colors
local sizes = require('scripts.Loadouts.myLib.myConstants').sizes
local util = require('openmw.util')
local async = require('openmw.async')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

---@class Tab
---@field name string
---@field getContent function
---@field element? ui.Element
local TAB = {
        name = '',
        getContent = function() end,
        ---@type ui.Element|{}
        element = {}
}


---@param tabs Tab[]
---@param defaultTab? number
---@return TabManager
local function createTabs(tabs, defaultTab)
        ---@class TabManager
        local self = {
                ---@type Tab[]
                tabsList = {},
                ---@type Tab
                activeTab = {
                        name = '',
                        getContent = function() end,
                        ---@type ui.Element|{}
                        element = {}
                },
                ---@type ui.Element
                contentContainer = nil,
                currentIndex = 1,
        }

        function self.selectTab(index)
                self.currentIndex = index
                --- old tab
                if self.activeTab.element.layout then
                        self.activeTab.element.layout.template = templates.InactiveTab
                        ---@diagnostic disable-next-line: undefined-field
                        self.activeTab.element.layout.content.tabName.props.textColor = colors.black
                        self.activeTab.element:update()
                end
                --- new tab
                self.activeTab = self.tabsList[index]
                if self.activeTab.element.layout then
                        self.activeTab.element.layout.template = templates.activeTab
                        ---@diagnostic disable-next-line: undefined-field
                        self.activeTab.element.layout.content.tabName.props.textColor = colors.normal
                        self.activeTab.element:update()
                end

                self.contentContainer.layout.content = ui.content { self.activeTab.getContent() }
                self.contentContainer:update()
        end

        function self.nextTab()
                self.currentIndex = self.currentIndex + 1
                if self.currentIndex > #self.tabsList then
                        self.currentIndex = #self.tabsList
                end
                self.selectTab(self.currentIndex)
        end

        function self.prevTab()
                self.currentIndex = self.currentIndex - 1
                if self.currentIndex < 1 then
                        self.currentIndex = 1
                end
                self.selectTab(self.currentIndex)
        end

        -- local tabBarLayouts = {}
        for index, tabData in pairs(tabs) do
                tabData.element = ui.create {
                        type = ui.TYPE.Flex,
                        template = templates.InactiveTab,
                        props = {
                                size = util.vector2(1, sizes.TEXT_SIZE + 8),
                                align = ui.ALIGNMENT.Center,
                                arrange = ui.ALIGNMENT.Center
                        },
                        content = ui.content {
                                {
                                        name = 'tabName',
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                                text = string.format('  %s  ', tabData.name),
                                                textSize = sizes.TEXT_SIZE,
                                                textColor = colors.black,
                                        },
                                }
                        },
                        events = {
                                mouseClick = async:callback(function()
                                        self.selectTab(index)
                                end),
                        },
                }
                table.insert(self.tabsList, tabData)
        end

        self.contentContainer = ui.create {
                -- template = templates.getTemplate('none', { 0, 0, 0, 0 }, false),
                external = { grow = 1, stretch = 1 },
                content = ui.content {}
        }

        return self
end

return createTabs
