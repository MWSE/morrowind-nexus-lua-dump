local types = require('openmw.types')
local core = require('openmw.core')
local async = require('openmw.async')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local util = require('openmw.util')
local myTypes = require("scripts.Loadouts.myLib.myTypes")
local g = require('scripts.Loadouts.myLib')
local getLoadoutGraph = require('scripts.Loadouts.contents.loadoutGraph')



local keepPrev = {}
local loadoutName = ''
local currentEqEls = {}

local function addInstrumentEntry()
        local record = types.Miscellaneous.records[g.myVars.instrument]
        -- print(record)
        -- print(record.icon)
        -- print(record.name)

        return {
                type = ui.TYPE.Flex,
                template = g.templates.getTemplate('none', { 0, 0, 0, 0 }, true, g.textures.eqRow),
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
                                                        textColor = g.colors.normal
                                                }
                                        },

                                }
                        },
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true,
                                },
                                userData = {
                                        empty = false,
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
                }
        }
end

local focusGainCall = async:callback(function(_, l)
        l.props.textColor = g.colors.hover
        table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
end)


local focusLossCall = async:callback(function(_, l)
        l.props.textColor = g.colors.normal
        table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
end)

---@return ui.Layout
local function getCurrentEquipment()
        keepPrev = {}
        currentEqEls = {}

        local eq = types.Actor.getEquipment(self)
        ---@cast eq EquipmentTable

        for index, slotName in pairs(myTypes.slotIndexToName) do
                ---@type ui.Layout
                local nameElement
                keepPrev[index - 1] = false


                if eq and eq[index - 1] then
                        ---@type Record
                        local record = eq[index - 1].type.record(eq[index - 1])

                        nameElement = {
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true,
                                },
                                userData = {
                                        empty = false,
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
                elseif slotName == 'Carried L' and core.contentFiles.has('dualwielding.omwscripts') == true and g.myVars.secondWeapon then
                        -- print('left dual carried = ', g.myVars.secondWeapon)
                        ---@type Record
                        local record = g.myVars.secondWeapon.type.record(g.myVars.secondWeapon)

                        nameElement = {
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true,
                                },
                                userData = {
                                        empty = false,
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
                        nameElement = {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = '[x] Empty     [ ] Keep Previous',
                                        textSize = g.sizes.TEXT_SIZE,
                                },
                                userData = {
                                        empty = true,
                                },
                                events = {
                                        mouseClick = async:callback(function(e, l)
                                                if l.userData.empty then
                                                        l.userData.empty = false
                                                        keepPrev[index - 1] = true
                                                else
                                                        l.userData.empty = true
                                                        keepPrev[index - 1] = false
                                                end
                                                l.props.text = string.format(
                                                        '[%s] Empty     [%s] Keep Previous',
                                                        l.userData.empty and 'x' or ' ', l.userData.empty and ' ' or 'x')
                                                if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
                                                        g.myVars.mainWindow.tabManager.contentContainer:update()
                                                end
                                        end),

                                        focusGain = focusGainCall,
                                        focusLoss = focusLossCall,
                                }
                        }
                end

                local layout = {
                        type = ui.TYPE.Flex,
                        template = g.templates.getTemplate('none', { 0, 0, 0, 0 }, true,
                                index % 2 == 0 and g.textures.eqRow or nil),
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
                                                                text = slotName,
                                                                textSize = g.sizes.TEXT_SIZE,
                                                                textColor = nameElement.userData.empty == true and g.colors.disabled or g.colors.normal
                                                        }
                                                },

                                        }
                                },
                                nameElement
                        }
                }

                table.insert(currentEqEls, layout)
        end

        if g.myVars.instrument and types.Miscellaneous.records[g.myVars.instrument] then
                table.insert(currentEqEls, addInstrumentEntry())
        end

        return {
                type = ui.TYPE.Flex,
                props = {
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content(currentEqEls)
        }
end

local function saveLoadout()
        if not loadoutName or loadoutName == '' then
                ui.showMessage('Enter a name for the loadout')
                return
        end

        for i = 1, #g.myVars.savedLoadouts do
                if g.myVars.savedLoadouts[i].name == loadoutName then
                        ui.showMessage(string.format('Loadout (%s) already exists', loadoutName))
                        return
                end
        end

        local eq = types.Actor.getEquipment(self)
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
                        keepPrev = keepPrev[v],
                }
        end

        table.insert(g.myVars.savedLoadouts, {
                name = loadoutName,
                myEq = myEq,
                secondWeapon = g.myVars.secondWeapon,
                instrument = g.myVars.instrument,
        })

        table.sort(g.myVars.savedLoadouts, function(a, b)
                return a.name:lower() < b.name:lower()
        end)

        ui.showMessage(string.format('Loadout created: %s', loadoutName))

        if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
                g.myVars.mainWindow.tabManager.contentContainer.layout.content = ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }

                table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
        end
end


---@return ui.Layout
local function getSaveLO()
        return {
                type = ui.TYPE.Flex,
                props = {
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {

                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = 'Loadout name: ',
                                        textSize = g.sizes.TEXT_SIZE,

                                },

                        },
                        {
                                type = ui.TYPE.Flex,
                                template = g.templates.getTemplate('thin', { 0, 0, 0, 2 }, false),
                                props = {
                                        size = util.vector2(1, g.sizes.BOX_SIZE),
                                        align = ui.ALIGNMENT.Center
                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textEditLine,
                                                props = {
                                                        text = '',
                                                        textSize = g.sizes.TEXT_SIZE,
                                                },
                                                events = {
                                                        textChanged = async:callback(function(
                                                            a, l)
                                                                if string.len(a) < 24 then
                                                                        l.props.text =
                                                                            a
                                                                        loadoutName = a
                                                                end
                                                                if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
                                                                        table.insert(
                                                                                g.myVars.myDelayedActions,
                                                                                g.myVars.mainWindow.tabManager
                                                                                .contentContainer)
                                                                end
                                                        end)
                                                }
                                        },
                                }
                        },

                        g.gui.makeInt(4, 0),

                        {
                                type = ui.TYPE.Flex,
                                template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, false),
                                props = {
                                        size = util.vector2(1, g.sizes.BOX_SIZE),
                                        align = ui.ALIGNMENT.Center,

                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        text = ' Save ',
                                                        textSize = g.sizes.TEXT_SIZE,

                                                },
                                                events = {

                                                        focusGain = focusGainCall,
                                                        focusLoss = focusLossCall,
                                                }
                                        }
                                },
                                events = {
                                        mouseClick = async:callback(saveLoadout)
                                }
                        },
                }
        }
end


---@return ui.Layout
local function getCreateLoadoutLO()
        loadoutName = ''
        local ce = getCurrentEquipment()

        local eq = types.Actor.getEquipment(self)
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
                        keepPrev = keepPrev[v],
                        -- secondWeapon = g.myVars.secondWeapon
                }
        end

        local currentGraph = getLoadoutGraph(myEq, g.myVars.secondWeapon, g.myVars.instrument)

        ---@type ui.Layout
        local element
        element = {
                type = ui.TYPE.Flex,
                props = {
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        g.gui.makeInt(0, 10),
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true,
                                },
                                content = ui.content {
                                        g.gui.makeInt(10, 0),
                                        {
                                                type = ui.TYPE.Flex,
                                                -- template = g.templates.iconFrame,
                                                -- template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, false),
                                                props = {
                                                        -- size = util.vector2(300, 300),
                                                        -- size = util.vector2(285, 300),

                                                        -- autoSize = true,
                                                },
                                                content = ui.content({ currentGraph })
                                        },
                                        g.gui.makeInt(10, 0),
                                        {
                                                type = ui.TYPE.Flex,
                                                props = {
                                                        horizontal = false,
                                                },
                                                content = ui.content {
                                                        getSaveLO(),
                                                        g.gui.makeInt(0, 10),
                                                        ce

                                                }
                                        }


                                }
                        }
                }
        }

        return element
end


return {
        -- init = init,
        getCreateLoadoutLO = getCreateLoadoutLO,
}
