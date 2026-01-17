local types                       = require('openmw.types')
local core                        = require('openmw.core')
local async                       = require('openmw.async')
local ui                          = require('openmw.ui')
local I                           = require('openmw.interfaces')
local util                        = require('openmw.util')
local myTypes                     = require("scripts.ActorInteractions.myLib.myTypes")
local g                           = require('scripts.ActorInteractions.myLib')
local getLoadoutGraph             = require('scripts.ActorInteractions.contents.loadoutGraph').getLoadoutGraph
local selectInstrumentWindow      = require('scripts.ActorInteractions.contents.loadoutGraph').selectInstrumentWindow
local createSelectEquipmentWindow = require('scripts.ActorInteractions.contents.loadoutGraph')
    .createSelectEquipmentWindow

local loadoutName                 = ''
local saveAsName                  = ''
local currentEqEls                = {}

---@type ui.Layout
local currentGraph

local nav                         = {}
nav.index                         = 1
---@type ui.Layout[]
nav.items                         = {}
nav.inputFocused                  = false
function nav:next()
        if #self.items == 0 then return end
        self:deHighlight()
        self.index = self.index + 1
        if self.index > #self.items then
                self.index = #self.items
        end
        self:highlight()
end

function nav:prev()
        if #self.items == 0 then return end
        self:deHighlight()
        self.index = self.index - 1
        if self.index < 1 then
                self.index = 1
        end
        self:highlight()
end

function nav:highlight(index)
        self.index = index or self.index
        self.items[self.index].template = g.templates.highlight

        local graphIndex
        local graphSlotLayout

        graphIndex = myTypes.SLOTS[myTypes.ARRANGED_SLOTS[self.index]]

        if not graphIndex then
                if g.myVars.performerInfo then
                        graphSlotLayout = currentGraph.userData.instrumentLO
                        graphIndex = 19
                else
                        return
                end
        else
                graphSlotLayout = currentGraph.userData.slotsLOs[graphIndex]
        end


        if graphSlotLayout.content and graphSlotLayout.content.overlay then
                graphSlotLayout.content.overlay.template = g.templates.highlight_white
        else
                graphSlotLayout.template = g.templates.highlight_white
        end


        ---@diagnostic disable-next-line: undefined-field
        currentGraph.content.currEqName.props.text = myTypes.slotIndexToName[graphIndex + 1]

        -- table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
        if g.myVars.dressUpWindow.tabManager then
                table.insert(g.myVars.myDelayedActions, g.myVars.dressUpWindow.tabManager.contentContainer)
        end
end

function nav:deHighlight(index)
        self.index = index or self.index
        self.items[self.index].template = nil

        local graphIndex
        local graphSlotLayout

        graphIndex = myTypes.SLOTS[myTypes.ARRANGED_SLOTS[self.index]]

        if not graphIndex then
                if g.myVars.performerInfo then
                        graphSlotLayout = currentGraph.userData.instrumentLO
                else
                        return
                end
        else
                graphSlotLayout = currentGraph.userData.slotsLOs[graphIndex]
        end


        if graphSlotLayout.content and graphSlotLayout.content.overlay then
                graphSlotLayout.content.overlay.template = nil
        else
                graphSlotLayout.template = nil
        end
        if g.myVars.dressUpWindow.tabManager then
                table.insert(g.myVars.myDelayedActions, g.myVars.dressUpWindow.tabManager.contentContainer)
        end
end

function nav:selectSlot()
        if (self.index - 1) > myTypes.SLOTS.Ammunition then
                -- selectInstrumentWindow()
        else
                -- createSelectEquipmentWindow(self.index - 1)
        end
end

local function addInstrumentEntry()
        local instNameEl

        if g.myVars.instrument then
                local record = types.Miscellaneous.records[g.myVars.instrument]
                instNameEl = {
                        type = ui.TYPE.Flex,
                        props = {
                                horizontal = true,
                        },
                        userData = {
                                empty = nil,
                        },
                        content = ui.content {
                                {
                                        type  = ui.TYPE.Image,
                                        props = {
                                                resource = ui.texture { path = record.icon },
                                                size = util.vector2(g.sizes.TEXT_SIZE, g.sizes.TEXT_SIZE)
                                        }
                                },
                                g.gui.makeInt(4, 0),
                                {
                                        template = I.MWUI.templates.textNormal,
                                        props    = {
                                                text = record.name,
                                                textSize = g.sizes.TEXT_SIZE,
                                        }
                                }
                        }
                }
        else
                instNameEl = {
                        template = I.MWUI.templates.textNormal,
                        props = {
                                -- text = g.myVars.keepPrev[index - 1] == false
                                --     and ' - Empty -'
                                --     or ' - Keep Previous -',
                                text = ' - Empty -',
                                textSize = g.sizes.TEXT_SIZE,
                        },
                        userData = {
                                empty = true,
                        },
                }
        end

        local layout = {
                type = ui.TYPE.Flex,
                props = {
                        relativeSize = util.vector2(1, 0),
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        size = util.vector2(100, g.sizes.TEXT_SIZE),
                                        align = ui.ALIGNMENT.Center,
                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        text = 'Instrument',
                                                        textSize = g.sizes.TEXT_SIZE,
                                                        textColor = not instNameEl.userData.empty and g.colors.normal or g.colors.disabled
                                                }
                                        },

                                }
                        },
                        instNameEl
                },
                events = {
                        mousePress = async:callback(function(e)
                                if e and e.button ~= 1 then return end
                                selectInstrumentWindow()
                        end),
                        focusGain = async:callback(function()
                                nav:deHighlight()
                                nav:highlight(#nav.items)
                        end),
                }
        }

        return layout
end

---@param actor NPC
---@return ui.Layout
local function getCurrentEquipment(actor)
        currentEqEls = {}
        nav.items = {}

        local eq = types.Actor.getEquipment(actor)

        ---@cast eq EquipmentTable

        for i = 1, #myTypes.ARRANGED_SLOTS do
                local slotKey = myTypes.ARRANGED_SLOTS[i]
                local index = myTypes.SLOTS[slotKey] + 1
                local slotName = myTypes.slotIndexToName[index]

                ---@type ui.Layout
                local nameElement

                if eq and eq[index - 1] then
                        ---@type Record
                        local record = eq[index - 1].type.record(eq[index - 1])

                        nameElement = {
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true,
                                },
                                userData = {
                                        empty = nil,
                                },
                                content = ui.content {
                                        {
                                                type = ui.TYPE.Container,
                                                content = ui.content {
                                                        record.enchant and {
                                                                type = ui.TYPE.Flex,
                                                                template = g.templates.getTemplate('none', { 0, 0, 0, 0 },
                                                                        true, g.textures.magicIcon),
                                                                props = {
                                                                        size = util.vector2(g.sizes.TEXT_SIZE, g.sizes.TEXT_SIZE),
                                                                },
                                                        } or {},
                                                        {
                                                                type = ui.TYPE.Image,
                                                                props = {
                                                                        resource = ui.texture {
                                                                                path = record.icon,
                                                                        },
                                                                        size = util.vector2(g.sizes.TEXT_SIZE, g.sizes.TEXT_SIZE),
                                                                },
                                                        }
                                                },
                                        },
                                        g.gui.makeInt(4, 0),
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props    = {
                                                        text = record.name,
                                                        textSize = g.sizes.TEXT_SIZE,
                                                }
                                        }
                                },
                        }
                else
                        nameElement = {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = ' - Empty -',
                                        textSize = g.sizes.TEXT_SIZE,
                                },
                                userData = {
                                        empty = true,
                                },
                        }
                end

                local layout = {
                        type = ui.TYPE.Flex,
                        props = {
                                relativeSize = util.vector2(1, 0),
                                horizontal = true,
                                arrange = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {
                                {
                                        type = ui.TYPE.Flex,
                                        props = {
                                                size = util.vector2(130, g.sizes.TEXT_SIZE),
                                                align = ui.ALIGNMENT.Center,
                                        },

                                        content = ui.content {
                                                {
                                                        template = I.MWUI.templates.textNormal,
                                                        props = {
                                                                text = slotName,
                                                                textSize = g.sizes.TEXT_SIZE,
                                                                textColor = nameElement.userData.empty == nil and g.colors.normal or g.colors.disabled
                                                        }
                                                },

                                        }
                                },
                                nameElement
                        },
                        events = {
                                mousePress = async:callback(function(e)
                                        if e and e.button ~= 1 then return end
                                        if not nav.items or #nav.items < 1 then return end
                                        createSelectEquipmentWindow(index - 1, actor)
                                end),
                                focusGain = async:callback(function()
                                        nav:deHighlight()
                                        nav:highlight(i)
                                end),
                        }
                }

                table.insert(currentEqEls, layout)
        end

        nav.items = currentEqEls

        local layout = {
                type = ui.TYPE.Flex,
                props = {
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content(currentEqEls)
        }


        layout.content:insert(3, g.gui.makeInt(0, 10))
        layout.content:insert(9, g.gui.makeInt(0, 10))
        layout.content:insert(15, g.gui.makeInt(0, 10))
        layout.content:insert(#layout.content, g.gui.makeInt(0, 10))


        return layout
end

---@param actor NPC
---@return ui.Layout
local function getCreateLoadoutLO(actor)
        local currentEquipment = getCurrentEquipment(actor)

        local eq = types.Actor.getEquipment(actor)
        ---@cast eq EquipmentTable
        local myEq = {}
        for _, v in pairs(myTypes.SLOTS) do
                local item = eq[v]
                local recordId
                local icon

                if item then
                        recordId = item.recordId
                        local record = item.type.record(item)
                        icon = record.icon
                end
                myEq[v] = {
                        recordId = recordId,
                        icon = icon,
                }
        end

        currentGraph = getLoadoutGraph(myEq, nav, actor)

        ---@type ui.Layout
        local element

        element = {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders, --- ############
                props = {
                        relativeSize = util.vector2(1, 1),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Flex,
                                -- template = I.MWUI.templates.borders, --- ############
                                props = {
                                        horizontal = true,
                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                        relativeSize = util.vector2(1, 1),

                                },
                                content = ui.content {
                                        g.gui.makeInt(10, 0),
                                        {
                                                type = ui.TYPE.Flex,
                                                -- template = I.MWUI.templates.borders, --- ############
                                                content = ui.content({ currentGraph })
                                        },
                                        g.gui.makeInt(10, 0),
                                        {
                                                template = I.MWUI.templates.verticalLine,
                                                external = { grow = 0, stretch = 0 },
                                                props = {
                                                        relativeSize = util.vector2(0, 0.9),
                                                        size = util.vector2(1, 0),
                                                }
                                        },
                                        g.gui.makeInt(10, 0),
                                        {
                                                type = ui.TYPE.Flex,
                                                props = {
                                                        horizontal = false,
                                                        size = util.vector2(400, 1),

                                                },
                                                content = ui.content {
                                                        -- getSaveLO(),
                                                        g.gui.makeInt(0, 10),
                                                        currentEquipment

                                                }
                                        },


                                }
                        }
                }
        }

        nav:highlight()

        return element
end


return {
        -- init = init,
        getCreateLoadoutLO = getCreateLoadoutLO,
        nav = nav
}
