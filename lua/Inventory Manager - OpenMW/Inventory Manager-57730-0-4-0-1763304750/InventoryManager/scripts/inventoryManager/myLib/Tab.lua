local templates = require('scripts.inventoryManager.myLib.myTemplates')
local colors = require('scripts.inventoryManager.myLib.myConstants').colors
local textures = require('scripts.inventoryManager.myLib.myConstants').textures
local sizes = require('scripts.inventoryManager.myLib.myConstants').sizes
local titleFlex = require('scripts.inventoryManager.myLib.myGUI').titleFlex
local makeInt = require('scripts.inventoryManager.myLib.myGUI').makeInt
local util = require('openmw.util')
local async = require('openmw.async')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')


---@class Tab
local TAB = {
        name = '',
        getContent = function() end,
        layout = {}
}

local TabManager = {}

function TabManager.create()
        local self = {
                tabs = {},
                ---@type Tab
                activeTab = nil,
                ---@type ui.Layout
                contentContainer = nil,
                onTabChange = function() end,
                tabsList = {}
        }


        function self.setOnTabChange(callback)
                self.onTabChange = callback
        end

        function self.registerTab(name, getContentFunction)
                self.tabs[name] = {
                        name = name,
                        getContent = getContentFunction,
                        layout = nil
                }
                table.insert(self.tabsList, name)
        end

        function self.selectTab(tabName)
                --- Update old tab
                if self.activeTab and self.activeTab.layout then
                        self.activeTab.layout.template = templates.InactiveTab
                        self.activeTab.layout.content.tabName.props.textColor = colors.black
                end

                --- Update new tab
                self.activeTab = self.tabs[tabName]
                if self.activeTab and self.activeTab.layout then
                        self.activeTab.layout.template = templates.activeTab
                        self.activeTab.layout.content.tabName.props.textColor = colors.normal
                end

                self.contentContainer.content = ui.content { self.activeTab.getContent() }

                self.onTabChange()
        end

        function self.createTabLayout(tabData)
                return {
                        type = ui.TYPE.Flex,
                        template = templates.InactiveTab,
                        props = {
                                size = util.vector2(1, sizes.CONTAINER_SIZE),
                                align = ui.ALIGNMENT.Center,
                                arrange = ui.ALIGNMENT.Center
                        },
                        content = ui.content {
                                {
                                        name = 'tabName',
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                                text = string.format('  %s  ', tabData.name),
                                                -- textSize = 14,
                                                textSize = sizes.LABEL_SIZE,
                                                textColor = colors.black,
                                        },
                                }
                        },
                        events = {
                                mouseClick = async:callback(function()
                                        self.selectTab(tabData.name)
                                end),
                        },
                }
        end

        ---@param defaultTab string
        ---@return ui.Layout[]
        ---@return ui.Layout
        function self.initialize(defaultTab)
                local tabBarLayouts = {}

                -- for _, tabData in pairs(self.tabs) do
                for _, name in pairs(self.tabsList) do
                        local tabData = self.tabs[name]
                        tabData.layout = self.createTabLayout(tabData)
                        table.insert(tabBarLayouts, tabData.layout)
                end

                self.contentContainer = {
                        template = templates.getTemplate('none', { 0, 0, 0, 0 }, false),
                        external = { grow = 1, stretch = 1 },
                        content = ui.content {}
                }

                if defaultTab and self.tabs[defaultTab] then
                        self.selectTab(defaultTab)
                else
                        self.selectTab(self.tabsList[#self.tabsList])
                end

                return tabBarLayouts, self.contentContainer
        end

        return self
end

return TabManager
