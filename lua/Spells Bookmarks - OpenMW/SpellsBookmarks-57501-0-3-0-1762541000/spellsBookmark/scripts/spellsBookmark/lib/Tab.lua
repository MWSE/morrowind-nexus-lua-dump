local templates = require('scripts.spellsBookmark.lib.myTemplates')
local colors = require('scripts.spellsBookmark.lib.myConstants').colors
local textures = require('scripts.spellsBookmark.lib.myConstants').textures
local sizes = require('scripts.spellsBookmark.lib.myConstants').sizes
local titleFlex = require('scripts.spellsBookmark.lib.myGUI').titleFlex
local makeInt = require('scripts.spellsBookmark.lib.myGUI').makeInt
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

        function self.registerTab(props)
                self.tabs[props.name] = {
                        name = props.name,
                        getContent = props.getContent,
                        layout = nil,
                        icon = props.icon
                }
                table.insert(self.tabsList, props.name)
        end

        function self.selectTab(tabName)
                --- Update old tab
                if self.activeTab and self.activeTab.layout then
                        -- self.activeTab.layout.template = templates.InactiveTab
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
                                size = util.vector2(sizes.TAB_SIZE, sizes.TAB_SIZE),
                                align = ui.ALIGNMENT.Center,
                                arrange = ui.ALIGNMENT.Center
                        },
                        content = ui.content {
                                -- {
                                --         name = 'tabName',
                                --         template = I.MWUI.templates.textNormal,
                                --         props = {
                                --                 text = string.format('  %s  ', tabData.name),
                                --                 -- textSize = 14,
                                --                 textSize = sizes.LABEL_SIZE,
                                --                 textColor = colors.black,
                                --         },
                                -- }
                                {
                                        name = 'tabName',

                                        type = ui.TYPE.Image,
                                        -- template = .getTemplate('none', {0, 0, 0, 0}, true, props.icon),
                                        props = {
                                                resource = tabData.icon,
                                                size = util.vector2(18, 18),
                                                -- relativeSize = util.vector2(0, 0.5),
                                                -- position = util.vector2(-14, -14),
                                                anchor = util.vector2(0.5, 0.5)
                                        }
                                },
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
