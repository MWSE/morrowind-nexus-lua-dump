local templates = require('scripts.InventoryManager.myLib.myTemplates')
local colors = require('scripts.InventoryManager.myLib.myConstants').colors
local sizes = require('scripts.InventoryManager.myLib.myConstants').sizes
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
-- -@return ui.Element[]
-- -@return ui.Element
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
        }

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

        -- local tabBarLayouts = {}
        for index, tabData in pairs(tabs) do
                tabData.element = ui.create {
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
                                                textSize = sizes.LABEL_SIZE,
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
                -- table.insert(tabBarLayouts, tabData.element)
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

        -- return tabBarLayouts, self.contentContainer
        return self
end

return createTabs
