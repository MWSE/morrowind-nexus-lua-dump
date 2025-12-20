local types = require('openmw.types')
local core = require('openmw.core')
local async = require('openmw.async')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local util = require('openmw.util')
local myTypes = require("scripts.Loadouts.myLib.myTypes")
local g = require('scripts.Loadouts.myLib')
local events = require('scripts.Loadouts.events')

local gap = 2

local RING_TYPE = {
        [myTypes.SLOTS.LeftRing] = true,
        [myTypes.SLOTS.RightRing] = true,
}

---@type ui.Layout
local emptyEquipmentSlot = {
        type = ui.TYPE.Image,
        props = {
                resource = g.textures.emptyEq,
                size = util.vector2(32, 32),
                alpha = 0.2,
        }
}

---@type ui.Layout
local keepPrevEqSlot = {
        type = ui.TYPE.Image,
        props = {
                resource = g.textures.keepPrevEq,
                size = util.vector2(32, 32),
                alpha = 0.2,
        }
}

---@param eqSlot number
---@return ui.Layout
local function getEmptyEqSlotLayout(eqSlot)
        return {
                type = ui.TYPE.Image,
                props = {
                        resource = g.textures.emptyEq,
                        size = util.vector2(32, 32),
                        alpha = 0.2,
                },
                events = {
                        focusGain = async:callback(function(_, l)
                                l.template = g.templates.iconFrame
                                table.insert(g.myVars.myDelayedActions, g.myVars.selectEqWindow)
                        end),
                        focusLoss = async:callback(function(_, l)
                                l.template = nil
                                table.insert(g.myVars.myDelayedActions, g.myVars.selectEqWindow)
                        end),
                        mousePress = async:callback(function(e)
                                if e.button ~= 1 then
                                        g.myVars.selectEqWindow:destroy()
                                        return
                                end
                                local skip = 3
                                local item = types.Actor.getEquipment(self, eqSlot)
                                if not item then
                                        if g.myVars.secondWeapon then
                                                self:sendEvent('RemoveSecondWeaponUI')
                                        end
                                else
                                        self:sendEvent('Unequip', { item = item })
                                        if eqSlot == myTypes.SLOTS.CarriedRight and g.myVars.secondWeapon then
                                                skip = 9
                                        end
                                end

                                g.myVars.selectEqWindow:destroy()

                                table.insert(g.myVars.doLater, {
                                        action = function()
                                                if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
                                                        g.myVars.mainWindow.tabManager.contentContainer.layout.content =
                                                            ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
                                                        g.myVars.mainWindow.tabManager
                                                            .contentContainer:update()
                                                end
                                        end,
                                        skip = skip,
                                })
                        end)
                }
        }
end

local function selectEquipmentWindow(eqSlot)
        local playerItems = types.Player.inventory(self):getAll()
        if not playerItems then return end

        local equippableItems = {}

        local dualWieldingIsInstalled = core.contentFiles.has('dualwielding.omwscripts') == true

        if dualWieldingIsInstalled and eqSlot == myTypes.SLOTS.CarriedLeft then
                local carriedRight = types.Player.getEquipment(self, myTypes.SLOTS.CarriedRight)
                local carriedRightType = carriedRight and carriedRight.type.record(carriedRight).type or ''
                for _, item in pairs(playerItems) do
                        ---@type Record
                        local record = item.type.record(item)
                        if item.type == types.Armor and myTypes.ARMOR_TYPE[record.type] == myTypes.SLOTS.CarriedLeft then
                                table.insert(equippableItems, item)
                        elseif item.type == types.Weapon and myTypes.ONE_HAND_WEAPON[record.type] and myTypes.ONE_HAND_WEAPON[carriedRightType] then
                                table.insert(equippableItems, item)
                        else
                                goto continue
                        end
                        ::continue::
                end
        else
                for _, item in pairs(playerItems) do
                        local itemSlot

                        ---@type Record
                        local record = item.type.record(item)
                        if item.type == types.Armor then
                                itemSlot = myTypes.ARMOR_TYPE[record.type]
                                if itemSlot == eqSlot then
                                        table.insert(equippableItems, item)
                                end
                        elseif item.type == types.Clothing then
                                if record.type == 8 and RING_TYPE[eqSlot] then
                                        table.insert(equippableItems, item)
                                else
                                        itemSlot = myTypes.CLOTHING_TYPE[record.type]
                                        if itemSlot == eqSlot then
                                                table.insert(equippableItems, item)
                                        end
                                end
                        elseif item.type == types.Weapon then
                                if myTypes.RANGED_AMMO[record.type] and eqSlot == myTypes.SLOTS.Ammunition then
                                        table.insert(equippableItems, item)
                                elseif not myTypes.RANGED_AMMO[record.type] and eqSlot == myTypes.SLOTS.CarriedRight then
                                        table.insert(equippableItems, item)
                                else
                                        goto continue
                                end
                        else
                                goto continue
                        end
                        ::continue::
                end
        end


        local itemsLayouts = {
                {
                        type = ui.TYPE.Flex,
                        props = { horizontal = true },
                        content = ui.content {
                                g.gui.makeInt(20, 0),
                                getEmptyEqSlotLayout(eqSlot),
                                --- TODO : Add keepPrev slot layout
                                --- getKeepPrevEqSlotLayout(eqSlot)

                                g.gui.makeInt(4, 0)
                        }
                },
        }


        local alreadyAdded = {}
        local ROW_LEN = 10
        for i = 1, #equippableItems do
                local item = equippableItems[i]
                local record = item.type.record(item)

                if alreadyAdded[item.recordId] then
                        goto continue
                else
                        alreadyAdded[item.recordId] = true
                end


                -- local layout = {
                local layout = {
                        type = ui.TYPE.Container,
                        content = ui.content {
                                record.enchant and {
                                        type = ui.TYPE.Flex,
                                        template = g.templates.getTemplate('none', { 0, 0, 0, 0 },
                                                true, g.textures.magicIcon),
                                        props = {
                                                size = util.vector2(32, 32),
                                        }
                                } or {},
                                {

                                        type = ui.TYPE.Image,
                                        -- template = g.templates.iconFrame,
                                        props = {
                                                resource = ui.texture { path = record.icon },
                                                size = util.vector2(32, 32),
                                        },
                                        events = {
                                                focusGain = async:callback(function(_, l)
                                                        l.template = g.templates.iconFrame
                                                        table.insert(g.myVars.myDelayedActions, g.myVars.selectEqWindow)
                                                end),
                                                focusLoss = async:callback(function(_, l)
                                                        l.template = nil
                                                        table.insert(g.myVars.myDelayedActions, g.myVars.selectEqWindow)
                                                end),
                                                mousePress = async:callback(function(e)
                                                        if e.button ~= 1 then
                                                                g.myVars.selectEqWindow:destroy()
                                                                return
                                                        end


                                                        if eqSlot == myTypes.SLOTS.CarriedLeft and dualWieldingIsInstalled and item.type == types.Weapon then
                                                                self:sendEvent("EquipSecondWeapon", { Weapon = item })
                                                        else
                                                                core.sendGlobalEvent('UseItem',
                                                                        { object = item, actor = self })
                                                        end

                                                        g.myVars.selectEqWindow:destroy()

                                                        local skip

                                                        if eqSlot == myTypes.SLOTS.CarriedRight and dualWieldingIsInstalled and g.myVars.secondWeapon then
                                                                skip = 9
                                                        else
                                                                skip = 2
                                                        end

                                                        table.insert(g.myVars.doLater, {
                                                                action = function()
                                                                        if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
                                                                                g.myVars.mainWindow.tabManager.contentContainer.layout.content =
                                                                                    ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
                                                                                g.myVars.mainWindow.tabManager
                                                                                    .contentContainer:update()
                                                                        end
                                                                        -- self:sendEvent(events.loadoutsRedrawCurrentView)
                                                                end,
                                                                skip = skip,
                                                        })
                                                end)
                                        }
                                }
                        }
                }

                itemsLayouts[#itemsLayouts].content:add(layout)
                itemsLayouts[#itemsLayouts].content:add(g.gui.makeInt(4, 0))

                if i % ROW_LEN == 0 then
                        itemsLayouts[#itemsLayouts].content:add(g.gui.makeInt(20, 0))
                        table.insert(itemsLayouts, {
                                type = ui.TYPE.Flex,
                                props = { horizontal = true },
                                content = ui.content {
                                        g.gui.makeInt(20, 0)
                                }
                        })
                end

                -- table.insert(itemsLayouts, layout)
                -- table.insert(itemsLayouts, g.gui.makeInt(4, 0))
                ::continue::
        end
        itemsLayouts[#itemsLayouts].content:add(g.gui.makeInt(20, 0))

        table.insert(itemsLayouts, 1, g.gui.makeInt(20, 0))
        table.insert(itemsLayouts, g.gui.makeInt(20, 0))

        if g.myVars.selectEqWindow.layout then
                g.myVars.selectEqWindow:destroy()
        end

        g.myVars.selectEqWindow = ui.create {
                layer = 'Windows',
                type = ui.TYPE.Flex,

                template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, true),

                props = {
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(0.5, 0.5),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        g.gui.makeInt(0, 20),
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        -- align = ui.ALIGNMENT.Center,
                                        -- arrange = ui.ALIGNMENT.Center,
                                        -- horizontal = true
                                        horizontal = false,
                                },
                                content = ui.content(itemsLayouts)
                        },
                        g.gui.makeInt(0, 20),
                },
                events = {
                        mouseClick = async:callback(function()
                        end),
                        focusLoss = async:callback(function()
                                -- g.myVars.selectEqWindow:destroy()
                        end),
                }
        }
end


local function selectInstrumentWindow()
        local Data = require('scripts.Bardcraft.data')

        if not Data then return end

        local instrumentItems = Data.InstrumentItems

        if not instrumentItems then return end


        local playerItems = types.Player.inventory(self):getAll()
        if not playerItems then return end

        local equippableItems = {}

        for _, item in pairs(playerItems) do
                for i, v in pairs(instrumentItems) do
                        if v[item.recordId] then
                                table.insert(equippableItems, item)
                        end
                end
        end

        local itemsLayouts = {
                {
                        type = ui.TYPE.Image,
                        props = {
                                resource = g.textures.emptyEq,
                                size = util.vector2(32, 32),
                                alpha = 0.2,
                        },
                        events = {
                                focusGain = async:callback(function(_, l)
                                        l.template = g.templates.iconFrame
                                        table.insert(g.myVars.myDelayedActions, g.myVars.selectEqWindow)
                                end),
                                focusLoss = async:callback(function(_, l)
                                        l.template = nil
                                        table.insert(g.myVars.myDelayedActions, g.myVars.selectEqWindow)
                                end),
                                mousePress = async:callback(function(e)
                                        if e.button ~= 1 then
                                                g.myVars.selectEqWindow:destroy()
                                                return
                                        end

                                        self:sendEvent('BC_SheatheInstrument',
                                                { actor = self, recordId = g.myVars.instrument })

                                        g.myVars.selectEqWindow:destroy()
                                        table.insert(g.myVars.doLater, {
                                                action = function()
                                                        if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
                                                                g.myVars.mainWindow.tabManager.contentContainer.layout.content =
                                                                    ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
                                                                g.myVars.mainWindow.tabManager
                                                                    .contentContainer:update()
                                                        end
                                                end,
                                                skip = 2,
                                        })
                                end)
                        }
                },
                g.gui.makeInt(4, 0)
        }


        local alreadyAdded = {}

        for i = 1, #equippableItems do
                local item = equippableItems[i]
                local record = item.type.record(item)
                -- print(item.recordId)
                if alreadyAdded[item.recordId] then
                        goto continue
                else
                        alreadyAdded[item.recordId] = true
                end

                local layout = {
                        type = ui.TYPE.Image,
                        props = {
                                resource = ui.texture { path = record.icon },
                                size = util.vector2(32, 32),
                        },
                        events = {
                                focusGain = async:callback(function(_, l)
                                        l.template = g.templates.iconFrame
                                        table.insert(g.myVars.myDelayedActions, g.myVars.selectEqWindow)
                                end),
                                focusLoss = async:callback(function(_, l)
                                        l.template = nil
                                        table.insert(g.myVars.myDelayedActions, g.myVars.selectEqWindow)
                                end),
                                mousePress = async:callback(function(e)
                                        if e.button ~= 1 then
                                                g.myVars.selectEqWindow:destroy()
                                                return
                                        end

                                        if item.recordId == g.myVars.instrument then
                                                g.myVars.selectEqWindow:destroy()
                                                return
                                        end

                                        self:sendEvent('BC_SheatheInstrument',
                                                { actor = self, recordId = item.recordId })

                                        g.myVars.selectEqWindow:destroy()

                                        table.insert(g.myVars.doLater, {
                                                action = function()
                                                        if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
                                                                g.myVars.mainWindow.tabManager.contentContainer.layout.content =
                                                                    ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
                                                                g.myVars.mainWindow.tabManager.contentContainer:update()
                                                        end
                                                        -- self:sendEvent(events.loadoutsRedrawCurrentView)
                                                end,
                                                skip = 2,
                                        })
                                end)
                        }
                }

                table.insert(itemsLayouts, layout)
                table.insert(itemsLayouts, g.gui.makeInt(4, 0))
        end

        table.insert(itemsLayouts, 1, g.gui.makeInt(20, 0))
        table.insert(itemsLayouts, g.gui.makeInt(20, 0))

        if g.myVars.selectEqWindow.layout then
                g.myVars.selectEqWindow:destroy()
        end

        g.myVars.selectEqWindow = ui.create {
                layer = 'Windows',
                type = ui.TYPE.Flex,

                template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, true),

                props = {
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(0.5, 0.5),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        g.gui.makeInt(0, 20),
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                        horizontal = true
                                },
                                content = ui.content(itemsLayouts)
                        },
                        g.gui.makeInt(0, 20),
                },
                events = {
                        mouseClick = async:callback(function()
                        end),
                        focusLoss = async:callback(function()
                                -- g.myVars.selectEqWindow:destroy()
                        end),
                }
        }
        ::continue::
end


local function getItemSlotLO(icon, isMagical, eqSlot)
        return {
                type = ui.TYPE.Container,
                content = ui.content {
                        isMagical and {
                                type = ui.TYPE.Flex,
                                template = g.templates.getTemplate('none', { 0, 0, 0, 0 },
                                        true, g.textures.magicIcon),
                                props = {
                                        size = util.vector2(32, 32),
                                }
                        } or {},
                        {

                                type = ui.TYPE.Image,
                                template = g.templates.iconFrame,
                                props = {
                                        resource = ui.texture { path = icon },
                                        size = util.vector2(32, 32),
                                },
                                events = {
                                        mousePress = async:callback(function(e, l)
                                                if e.button ~= 1 then return end
                                                if g.myVars.mainWindow.tabManager.activeTab.name == 'Create' then
                                                        if eqSlot == nil then
                                                                selectInstrumentWindow()
                                                        else
                                                                selectEquipmentWindow(eqSlot)
                                                        end
                                                end
                                        end)
                                }
                        },
                }
        }
end

---@param eq MyEq
---@param secondWeapon Weapon
---@param instrument string
local function getLoadoutGraph(eq, secondWeapon, instrument)
        local slotsLOs = {}

        for _, v in pairs(myTypes.SLOTS) do
                local recordId = eq[v].recordId
                local icon = eq[v].icon
                local keepPrev = eq[v].keepPrev

                if recordId then
                        local itemInInv = types.Actor.inventory(self):find(recordId)


                        if itemInInv then
                                local isMagical = itemInInv.type.record(itemInInv).enchant
                                slotsLOs[v] = getItemSlotLO(icon, isMagical, v)
                        else
                                slotsLOs[v] = {
                                        type = ui.TYPE.Container,
                                        content = ui.content {
                                                {
                                                        type = ui.TYPE.Image,
                                                        template = g.templates.iconFrame,
                                                        props = {
                                                                resource = ui.texture { path = icon },
                                                                size = util.vector2(32, 32),
                                                        }
                                                },
                                                {

                                                        type = ui.TYPE.Image,
                                                        template = I.MWUI.templates.borders,
                                                        props = {
                                                                resource = g.textures.missing,
                                                                size = util.vector2(32, 32),
                                                        }
                                                }
                                        }
                                }
                        end
                elseif v == myTypes.SLOTS.CarriedLeft and core.contentFiles.has('dualwielding.omwscripts') == true and secondWeapon and secondWeapon:isValid() then
                        slotsLOs[v] = {
                                type = ui.TYPE.Image,
                                template = g.templates.iconFrame,

                                props = {
                                        resource = ui.texture { path = secondWeapon.type.record(secondWeapon).icon },
                                        size = util.vector2(32, 32),
                                },
                                events = {
                                        mousePress = async:callback(function()
                                                if g.myVars.mainWindow.tabManager.activeTab.name == 'Create' then
                                                        selectEquipmentWindow(v)
                                                end
                                        end)
                                }
                        }
                else
                        if keepPrev then
                                slotsLOs[v] = keepPrevEqSlot
                        else
                                -- slotsLOs[v] = emptyEquipmentSlot
                                slotsLOs[v] = {
                                        type = ui.TYPE.Image,
                                        props = {
                                                resource = g.textures.emptyEq,
                                                size = util.vector2(32, 32),
                                                alpha = 0.2,
                                        },
                                        events = {
                                                mousePress = async:callback(function()
                                                        if g.myVars.mainWindow.tabManager.activeTab.name == 'Create' then
                                                                selectEquipmentWindow(v)
                                                        end
                                                end)
                                        }
                                }
                        end
                end
        end


        local instrumentSlotLayout

        if core.contentFiles.has('Bardcraft.omwscripts') == true and g.myVars.performerInfo  then
                if instrument then
                        instrumentSlotLayout = getItemSlotLO(types.Miscellaneous.records[instrument].icon, false, nil)
                else
                        instrumentSlotLayout = {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = g.textures.emptyEq,
                                        size = util.vector2(32, 32),
                                        alpha = 0.2,
                                },
                                events = {
                                        mousePress = async:callback(function()
                                                if g.myVars.mainWindow.tabManager.activeTab.name == 'Create' then
                                                        selectInstrumentWindow()
                                                end
                                        end)
                                }
                        }
                end
        else
                instrumentSlotLayout = g.gui.emptyLO
        end




        return {

                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                -- template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, false),
                template = g.templates.iconFrame,
                props = {
                        size = util.vector2(285, 300),
                        -- relativeSize = util.vector2(1, 1),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center
                },
                content = ui.content {
                        slotsLOs[myTypes.SLOTS.Helmet],
                        g.gui.makeInt(0, gap),
                        slotsLOs[myTypes.SLOTS.Amulet],
                        g.gui.makeInt(0, gap),
                        g.gui.flexH {
                                slotsLOs[myTypes.SLOTS.LeftPauldron],
                                g.gui.makeInt(gap, 0),
                                g.gui.emptyThinLO,
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.Shirt],
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.Cuirass],
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.Robe],
                                g.gui.makeInt(gap, 0),
                                g.gui.emptyThinLO,
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.RightPauldron],
                        },
                        g.gui.makeInt(0, gap),
                        g.gui.flexH {

                                slotsLOs[myTypes.SLOTS.LeftRing],
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.LeftGauntlet],
                                g.gui.makeInt(gap, 0),
                                g.gui.emptyThinLO,
                                g.gui.makeInt(gap, 0),
                                g.gui.emptyLO,
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.Belt],
                                g.gui.makeInt(gap, 0),
                                g.gui.emptyLO,
                                g.gui.makeInt(gap, 0),
                                g.gui.emptyThinLO,
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.RightGauntlet],
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.RightRing],
                        },
                        g.gui.makeInt(0, gap),
                        g.gui.flexH {
                                instrumentSlotLayout,
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.CarriedLeft],
                                g.gui.makeInt(gap, 0),
                                g.gui.emptyThinLO,
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.Pants],
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.Greaves],
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.Skirt],
                                g.gui.makeInt(gap, 0),
                                g.gui.emptyThinLO,
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.CarriedRight],
                                g.gui.makeInt(gap, 0),
                                slotsLOs[myTypes.SLOTS.Ammunition],
                        },
                        g.gui.makeInt(0, gap),
                        slotsLOs[myTypes.SLOTS.Boots],
                }

        }
end


return getLoadoutGraph
