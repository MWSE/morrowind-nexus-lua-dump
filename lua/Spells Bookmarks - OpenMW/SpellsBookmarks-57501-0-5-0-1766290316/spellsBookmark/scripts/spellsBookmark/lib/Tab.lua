local templates = require('scripts.spellsBookmark.lib.myTemplates')
local colors = require('scripts.spellsBookmark.lib.myConstants').colors
local sizes = require('scripts.spellsBookmark.lib.myConstants').sizes
local util = require('openmw.util')
local async = require('openmw.async')
local ui = require('openmw.ui')

---@class Tab
---@field name? string
---@field icon string
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
                        icon = '',
                        getContent = function() end,
                        ---@type ui.Element|{}
                        element = {}
                },
                ---@type ui.Element
                contentContainer = nil,
                currentIndex = 1,
        }

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

        function self.selectTab(index)
                --- old tab
                if self.activeTab.element.layout then
                        self.activeTab.element.layout.template = templates.InactiveTab
                        self.activeTab.element.layout.content.tabName.props.textColor = colors.black
                        self.activeTab.element:update()
                end
                --- new tab
                self.activeTab = self.tabsList[index]
                if self.activeTab.element.layout then
                        self.activeTab.element.layout.template = templates.activeTab
                        self.activeTab.element.layout.content.tabName.props.textColor = colors.normal
                        self.activeTab.element:update()
                end

                self.contentContainer.layout.content = ui.content { self.activeTab.getContent() }
                self.contentContainer:update()
        end

        for index, tabData in pairs(tabs) do
                tabData.element = ui.create {
                        type = ui.TYPE.Flex,
                        template = templates.InactiveTab,
                        props = {
                                size = util.vector2(sizes.TAB_SIZE, sizes.TAB_SIZE),
                                align = ui.ALIGNMENT.Center,
                                arrange = ui.ALIGNMENT.Center
                        },
                        content = ui.content {
                                {
                                        name = 'tabName',
                                        type = ui.TYPE.Image,
                                        props = {
                                                resource = tabData.icon,
                                                size = util.vector2(18, 18),
                                                anchor = util.vector2(0.5, 0.5)
                                        }
                                },
                        },
                        events = {
                                mouseClick = async:callback(function()
                                        self.selectTab(index)
                                end),
                        },
                }
                table.insert(self.tabsList, tabData)
        end


        if not defaultTab then
                defaultTab = 1
        end

        self.activeTab = self.tabsList[defaultTab]
        if self.activeTab.element.layout then
                self.activeTab.element.layout.template = templates.activeTab
                self.activeTab.element.layout.content.tabName.props.textColor = colors.normal
                self.activeTab.element:update()
        end

        self.contentContainer = ui.create {
                template = templates.getTemplate('none', { 0, 0, 0, 0 }, false),
                external = { grow = 1, stretch = 1 },
                content = ui.content { self.tabsList[defaultTab].getContent() }
        }

        return self
end

return createTabs
