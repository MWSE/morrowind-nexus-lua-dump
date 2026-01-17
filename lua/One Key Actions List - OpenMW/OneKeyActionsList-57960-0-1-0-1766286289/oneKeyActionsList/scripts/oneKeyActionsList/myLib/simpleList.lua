local myTemplates  = require "scripts.oneKeyActionsList.myLib.myTemplates"
local ui           = require('openmw.ui')
local util         = require('openmw.util')
local async        = require('openmw.async')
local I            = require('openmw.interfaces')
local myVars       = require('scripts.oneKeyActionsList.myLib.myVars')
local myGUI        = require('scripts.oneKeyActionsList.myLib.myGUI')
local myConstants  = require('scripts.oneKeyActionsList.myLib.myConstants')

---@class SimpleList
---@field layouts ui.Layout[]
---@field currentIndex number
-- -@field layout ui.Layout
---@field layout ui.Element
---@field parentElement? ui.Element
local simpleList   = {}
simpleList.__index = simpleList

---@class SimpleListData
---@field text string
---@field extraText? string
---@field action fun(): boolean|nil

---@param data SimpleListData[]
-- -@param parentElement ui.Element
---@param header? string
---@param headerEnd? string
---@return SimpleList
function simpleList:new(data, header, headerEnd)
        local inst = setmetatable({}, simpleList)
        inst.currentIndex = 1
        inst.layouts = {}
        inst.parentElement = nil

        for i = 1, #data do
                local obj = data[i]

                -- print(i)

                local layout = {
                        type = ui.TYPE.Flex,
                        -- template = I.MWUI.templates.borders,
                        -- external = { stretch = 1 },
                        external = { stretch = 1, grow = 1 },

                        props = {
                                horizontal = true,
                                arrange = ui.ALIGNMENT.Center,
                                -- align = ui.ALIGNMENT.Center
                        },
                        content = ui.content {
                                -- myGUI.makeInt(10, 0),
                                {

                                        type = ui.TYPE.Flex,
                                        -- template = I.MWUI.templates.borders,

                                        props = {
                                                horizontal = true,
                                                arrange = ui.ALIGNMENT.Center,
                                                align = ui.ALIGNMENT.Center,
                                        },
                                        external = { stretch = 0, grow = 1 },
                                        content = ui.content {

                                                {
                                                        template = I.MWUI.templates.textNormal,
                                                        props = {
                                                                text = obj.text,
                                                                -- textSize = myConstants.sizes.H5
                                                                textSize = myConstants.sizes.H1
                                                        },
                                                },

                                                -- obj.extraText and myGUI.makeInt(1, 0, 1, 1) or nil,
                                                -- obj.extraText and {
                                                --         template = I.MWUI.templates.textNormal,
                                                --         props = {
                                                --                 text = tostring(obj.extraText),
                                                --                 textSize = myConstants.sizes.H5

                                                --         },
                                                -- } or nil,
                                                -- obj.extraText and myGUI.makeInt(10, 0),




                                        },
                                },
                                -- myGUI.makeInt(10, 0),
                        },
                        events = {
                                mousePress = async:callback(function(e, l)
                                        if e.button ~= 1 then return end

                                        if myVars.mainWindow.element and myVars.mainWindow.element.layout then
                                                myVars.mainWindow.element:destroy()
                                        end

                                        if obj.action then
                                                if obj.action() ~= true then
                                                        I.UI.setMode(nil)
                                                end
                                        else
                                                ui.showMessage('No action found for ' .. obj.text)
                                        end
                                        -- return true
                                end),
                                focusGain = async:callback(function(_, layout)
                                        inst:deHighlight()
                                        -- inst.currentIndex = i
                                        inst:highlight(i)
                                        return true
                                end),
                        },

                }



                table.insert(inst.layouts, layout)
        end


        local layout
        layout = ui.create {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,

                external = { stretch = 1, grow = 1 },
                props = {
                        relativeSize = util.vector2(1, 1),
                        -- arrange= ui.ALIGNMENT.End
                },
                content = ui.content {
                        -- {
                        --         type = ui.TYPE.Flex,
                        --         external = { stretch = 1 },
                        --         props = {
                        --                 horizontal = true
                        --         },
                        --         content = ui.content {

                        --                 myGUI.makeInt(10, 0),
                        --                 header and {
                        --                         template = I.MWUI.templates.textNormal,
                        --                         props = {
                        --                                 text = header,
                        --                                 textSize = myConstants.sizes.H5

                        --                         }
                        --                 } or {},
                        --                 headerEnd and myGUI.makeInt(100, 0, 1),
                        --                 headerEnd and {
                        --                         template = I.MWUI.templates.textNormal,
                        --                         props = {
                        --                                 text = headerEnd,
                        --                                 textSize = myConstants.sizes.H5

                        --                         }
                        --                 },
                        --                 myGUI.makeInt(10, 0),
                        --                 -- myGUI.makeInt(10, 0),
                        --         }
                        -- },
                        -- {
                        --         template = I.MWUI.templates.horizontalLine,
                        -- },
                        -- myGUI.makeInt(0, 41),
                        {
                                type = ui.TYPE.Flex,
                                -- template = I.MWUI.templates.borders,
                                -- props = {
                                --         -- relativeSize = util.vector2(1, 1),
                                --         arrange = ui.ALIGNMENT.Center,
                                --         align = ui.ALIGNMENT.Center
                                -- },
                                external = { stretch = 1, grow = 1 },

                                content = ui.content {
                                        -- myGUI.makeInt(0, 10),
                                        {
                                                type = ui.TYPE.Flex,
                                                -- props = {
                                                --         relativeSize = util.vector2(1, 1),
                                                --         arrange = ui.ALIGNMENT.Center,
                                                --         align = ui.ALIGNMENT.Center
                                                -- },
                                                external = { stretch = 1, grow = 1 },
                                                -- template = I.MWUI.templates.borders,
                                                content = ui.content(inst.layouts)
                                        },
                                        -- myGUI.makeInt(0, 4),
                                }
                        },
                        -- myGUI.makeInt(0, 10),
                }
        }

        inst.layout = layout

        return inst
end

function simpleList:listNext(amount)
        self:deHighlight()
        self.currentIndex = self.currentIndex + amount

        if self.currentIndex > #self.layouts then
                self.currentIndex = #self.layouts
        elseif self.currentIndex < 1 then
                self.currentIndex = 1
        end
        self:highlight()
end

function simpleList:highlight(index)
        self.currentIndex = index or self.currentIndex
        local item = self.layouts[self.currentIndex]
        if not item then return end
        item.template = myTemplates.entryHighlight
        -- table.insert(myVars.myDelayedActions, myVars.mainWindow.tabManager.contentContainer)
        -- table.insert(myVars.myDelayedActions, myVars.mainWindow.element)
        table.insert(myVars.myDelayedActions, self.parentElement)
end

function simpleList:deHighlight(index)
        self.currentIndex = index or self.currentIndex
        local item = self.layouts[self.currentIndex]
        if not item then return end
        item.template = nil
        -- table.insert(myVars.myDelayedActions, myVars.mainWindow.tabManager.contentContainer)
        -- table.insert(myVars.myDelayedActions, myVars.mainWindow.element)
        table.insert(myVars.myDelayedActions, self.parentElement)
end

function simpleList:selectCurrent(index)
        self.currentIndex = index or self.currentIndex
        local item = self.layouts[self.currentIndex]
        if not item then return end


        item.events.mousePress({ button = 1 }, item)
end

return simpleList
