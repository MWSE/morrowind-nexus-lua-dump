local types          = require('openmw.types')
local core           = require('openmw.core')
local async          = require('openmw.async')
local ui             = require('openmw.ui')
local I              = require('openmw.interfaces')
local self           = require('openmw.self')
local util           = require('openmw.util')
local myTypes        = require("scripts.Loadouts.myLib.myTypes")
local g              = require('scripts.Loadouts.myLib')
local ScrollableList = require('scripts.Loadouts.myLib.scrollableList')
local selectEqWindow = require('scripts.Loadouts.contents.selectEq')

local gap            = 2
---@type ui.Element
local listEl
local RING_TYPE      = {
        [myTypes.SLOTS.LeftRing] = true,
        [myTypes.SLOTS.RightRing] = true,
}

---@param eqSlot number
---@return ui.Layout
local function getEmptyEqSlotLayout(eqSlot)
        return {
                type = ui.TYPE.Image,
                props = {
                        resource = g.textures.emptyEq,
                        size = util.vector2(32, 32),
                        -- alpha = 0.2,
                },
                events = {
                        focusGain = async:callback(function(_, l)
                                l.template = g.templates.iconFrame
                                table.insert(g.myVars.myDelayedActions, selectEqWindow.element)
                        end),
                        focusLoss = async:callback(function(_, l)
                                l.template = nil
                                table.insert(g.myVars.myDelayedActions, selectEqWindow.element)
                        end),
                        mousePress = async:callback(function(e)
                                -- mouseClick = async:callback(function(e)
                                if e.button ~= 1 then
                                        selectEqWindow.element:destroy()
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

                                selectEqWindow.element:destroy()

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

local function unEquipSlot(slot)
        local skip = 3
        local item = types.Actor.getEquipment(self, slot)
        if not item then
                if slot == myTypes.SLOTS.CarriedLeft and g.myVars.secondWeapon then
                        self:sendEvent('RemoveSecondWeaponUI')
                end
        else
                self:sendEvent('Unequip', { item = item })
                if slot == myTypes.SLOTS.CarriedRight and g.myVars.secondWeapon then
                        skip = 9
                end
        end

        selectEqWindow.element:destroy()

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
end

---@param eqSlot number
---@param equippableItems GameObject[]
---@return ui.Layout[]
local function getTextItemsLayouts(eqSlot, equippableItems)
        local dualWieldingIsInstalled = core.contentFiles.has('dualwielding.omwscripts') == true

        local emptyOption = {
                type = ui.TYPE.Flex,
                props = {
                        horizontal = true,
                        relativeSize = util.vector2(1, 0),
                },
                userData = {
                        name = 'aaaaaaaaaaaaaaaaaaaaa',
                        -- item = item,
                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = 'Empty',
                                        textSize = g.sizes.LIST_TEXT_SIZE
                                }
                        }
                },
                events = {
                        focusGain = async:callback(function(_, l)
                                selectEqWindow:deHighlight()
                                selectEqWindow:highlight(1, false)
                        end),
                        mousePress = async:callback(function(e)
                                if e and e.button ~= 1 then return end
                                unEquipSlot(eqSlot)
                                g.myVars.keepPrev[eqSlot] = false
                        end)

                }
        }
        local keepPrevOption = {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                props = {
                        horizontal = true,
                        relativeSize = util.vector2(1, 0),

                },
                userData = {
                        name = 'aaaaaaaaaaaaaaaaaaaab',
                        -- item = item,
                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = 'Keep previous',
                                        textSize = g.sizes.LIST_TEXT_SIZE
                                }
                        }
                },
                events = {
                        focusGain = async:callback(function(_, l)
                                selectEqWindow:deHighlight()
                                selectEqWindow:highlight(2, false)
                                return true
                        end),
                        mousePress = async:callback(function(e)
                                if e and e.button ~= 1 then return end
                                unEquipSlot(eqSlot)
                                g.myVars.keepPrev[eqSlot] = true
                                return true
                        end)

                }
        }

        selectEqWindow.itemsLayouts = {
                emptyOption,
                keepPrevOption,
        }

        local alreadyAdded = {}
        for i = 1, #equippableItems do
                local item = equippableItems[i]

                ---@type WeaponRecord|ArmorRecord|ClothingRecord
                local record = item.type.record(item)

                if alreadyAdded[item.recordId] then
                        goto continue
                else
                        alreadyAdded[item.recordId] = true
                end

                local extraInfo

                if record.baseArmor then
                        extraInfo = record.baseArmor
                elseif record.chopMaxDamage then
                        extraInfo = math.max(record.chopMaxDamage, record.slashMaxDamage, record.thrustMaxDamage)
                end

                local currIndex = #selectEqWindow.itemsLayouts + 1

                local icon = {
                        type = ui.TYPE.Container,
                        template = types.Actor.hasEquipped(self, item) and g.templates.iconFrame,
                        content = ui.content {
                                record.enchant and {
                                        type = ui.TYPE.Flex,
                                        template = g.templates.getTemplate('none', { 0, 0, 0, 0 },
                                                true, g.textures.magicIcon),
                                        props = {
                                                size = util.vector2(g.sizes.LIST_TEXT_SIZE, g.sizes.LIST_TEXT_SIZE),
                                        },
                                } or {},
                                {
                                        type = ui.TYPE.Image,
                                        props = {
                                                resource = ui.texture {
                                                        path = record.icon,
                                                },
                                                size = util.vector2(g.sizes.LIST_TEXT_SIZE, g.sizes.LIST_TEXT_SIZE),
                                        },
                                }
                        },
                }

                local entry = {
                        type = ui.TYPE.Flex,
                        props = {
                                horizontal = true,
                                relativeSize = util.vector2(1, 0),
                                -- size = util.vector2(200, 30),
                        },
                        userData = {
                                name = record.name:lower(),
                                -- name = record.name,
                                item = item,
                        },
                        content = ui.content {
                                icon,
                                g.gui.makeInt(4, 0),
                                {
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                                text = record.name,
                                                textSize = g.sizes.LIST_TEXT_SIZE,
                                        }
                                },
                                g.gui.makeInt(1, 0, 1, 0),
                                extraInfo and {
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                                text = tostring(extraInfo),
                                                textSize = g.sizes.LIST_TEXT_SIZE,
                                        }
                                }
                        },
                        events = {
                                focusGain = async:callback(function(_, l)
                                        selectEqWindow:deHighlight()
                                        selectEqWindow:highlight(currIndex, false)
                                end),
                                mousePress = async:callback(function(e)
                                        if e and e.button ~= 1 then return end
                                        if eqSlot == myTypes.SLOTS.CarriedLeft and dualWieldingIsInstalled and item.type == types.Weapon then
                                                self:sendEvent("EquipSecondWeapon", { Weapon = item })
                                        elseif eqSlot == myTypes.SLOTS.RightRing then
                                                local currEq = types.Actor.getEquipment(self)
                                                ---@cast currEq EquipmentTable

                                                if currEq[myTypes.SLOTS.LeftRing] == item then
                                                        currEq[myTypes.SLOTS.LeftRing] = nil
                                                end

                                                currEq[myTypes.SLOTS.RightRing] = item
                                                types.Actor.setEquipment(self, currEq)
                                        elseif eqSlot == myTypes.SLOTS.LeftRing then
                                                local currEq = types.Actor.getEquipment(self)
                                                ---@cast currEq EquipmentTable

                                                if currEq[myTypes.SLOTS.RightRing] == item then
                                                        currEq[myTypes.SLOTS.RightRing] = nil
                                                end

                                                currEq[myTypes.SLOTS.LeftRing] = item
                                                types.Actor.setEquipment(self, currEq)
                                        else
                                                core.sendGlobalEvent('UseItem',
                                                        { object = item, actor = self })
                                        end

                                        selectEqWindow.element:destroy()

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
                                                end,
                                                skip = skip,
                                        })
                                end)

                        }
                }

                table.insert(selectEqWindow.itemsLayouts, entry)

                ::continue::
        end



        return selectEqWindow.itemsLayouts
end

local function getTextInstrumentsLayouts(equippableItems)
        local emptyOption = {
                type = ui.TYPE.Flex,
                props = {
                        horizontal = true,
                        relativeSize = util.vector2(1, 0),
                },
                userData = {
                        name = 'aaaaaaaaaaaaaaaaaaaaa',
                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = 'Empty',
                                        textSize = g.sizes.LIST_TEXT_SIZE
                                }
                        }
                },
                events = {
                        focusGain = async:callback(function(_, l)
                                selectEqWindow:deHighlight()
                                selectEqWindow:highlight(1, false)
                        end),
                        mousePress = async:callback(function(e)
                                if e and e.button ~= 1 then return end
                                selectEqWindow.element:destroy()
                                self:sendEvent('BC_SheatheInstrument',
                                        { actor = self, recordId = g.myVars.instrument })
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
        }
        -- local keepPrevOption = {
        --         type = ui.TYPE.Flex,
        --         -- template = I.MWUI.templates.borders,
        --         props = {
        --                 horizontal = true,
        --                 relativeSize = util.vector2(1, 0),

        --         },
        --         userData = {
        --                 name = 'aaaaaaaaaaaaaaaaaaaab',
        --                 -- item = item,
        --         },
        --         content = ui.content {
        --                 {
        --                         template = I.MWUI.templates.textNormal,
        --                         props = {
        --                                 text = 'Keep previous',
        --                                 textSize = g.sizes.LIST_TEXT_SIZE
        --                         }
        --                 }
        --         },
        --         events = {
        --                 focusGain = async:callback(function(_, l)
        --                         selectEqWindow:deHighlight()
        --                         selectEqWindow:highlight(2)
        --                         return true
        --                 end),
        --                 mousePress = async:callback(function(e)
        --                         if e and e.button ~= 1 then return end
        --                         unEquipSlot(eqSlot)
        --                         g.myVars.keepPrev[eqSlot] = true
        --                         return true
        --                 end)

        --         }
        -- }

        selectEqWindow.itemsLayouts = {
                emptyOption,
                -- keepPrevOption,
        }

        local alreadyAdded = {}
        for i = 1, #equippableItems do
                local item = equippableItems[i]

                ---@type WeaponRecord|ArmorRecord|ClothingRecord
                local record = item.type.record(item)

                if alreadyAdded[item.recordId] then
                        goto continue
                else
                        alreadyAdded[item.recordId] = true
                end


                local currIndex = #selectEqWindow.itemsLayouts + 1

                local icon = {
                        type = ui.TYPE.Image,
                        template = types.Actor.hasEquipped(self, item) and g.templates.iconFrame,
                        props = {
                                resource = ui.texture {
                                        path = record.icon,
                                },
                                size = util.vector2(g.sizes.LIST_TEXT_SIZE, g.sizes.LIST_TEXT_SIZE),
                        },
                }

                local entry = {
                        type = ui.TYPE.Flex,
                        props = {
                                horizontal = true,
                                relativeSize = util.vector2(1, 0),
                        },
                        userData = {
                                name = record.name:lower(),
                                item = item,
                        },
                        content = ui.content {
                                icon,
                                g.gui.makeInt(4, 0),
                                {
                                        template = I.MWUI.templates.textNormal,
                                        props = {
                                                text = record.name,
                                                textSize = g.sizes.LIST_TEXT_SIZE,
                                        }
                                },
                        },
                        events = {
                                focusGain = async:callback(function(_, l)
                                        selectEqWindow:deHighlight()
                                        selectEqWindow:highlight(currIndex, false)
                                end),
                                mousePress = async:callback(function(e)
                                        if e and e.button ~= 1 then return end


                                        if item.recordId == g.myVars.instrument then
                                                selectEqWindow.element:destroy()
                                                return
                                        end

                                        self:sendEvent('BC_SheatheInstrument',
                                                { actor = self, recordId = item.recordId })

                                        selectEqWindow.element:destroy()

                                        table.insert(g.myVars.doLater, {
                                                action = function()
                                                        if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
                                                                g.myVars.mainWindow.tabManager.contentContainer.layout.content =
                                                                    ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
                                                                g.myVars.mainWindow.tabManager.contentContainer:update()
                                                        end
                                                end,
                                                skip = 2,
                                        })
                                end)

                        }
                }

                table.insert(selectEqWindow.itemsLayouts, entry)

                ::continue::
        end



        return selectEqWindow.itemsLayouts
end

local function getGridItemsLayouts(eqSlot, equippableItems)
        local itemsLayouts = {
                --- First row
                {
                        type = ui.TYPE.Flex,
                        props = { horizontal = true },
                        content = ui.content {
                                g.gui.makeInt(20, 0),
                                -- getEmptyEqSlotLayout(eqSlot),
                                -- g.gui.makeInt(4, 0)

                                --- TODO : Add keepPrev slot layout
                                --- getKeepPrevEqSlotLayout(eqSlot)

                        },
                },
        }

        selectEqWindow.itemsLayouts = {}

        local ROW_LEN = 10
        local alreadyAdded = {}
        for i = 1, #equippableItems do
                local item = equippableItems[i]
                local record = item.type.record(item)

                if alreadyAdded[item.recordId] then
                        goto continue
                else
                        alreadyAdded[item.recordId] = true
                end


                local currIndex = #selectEqWindow.itemsLayouts + 1

                local layout = {
                        type = ui.TYPE.Container,
                        userData = {
                                item = item,
                        },
                        content = ui.content {
                                record.enchant and {
                                        type = ui.TYPE.Flex,
                                        template = g.templates.getTemplate('none', { 0, 0, 0, 0 },
                                                true, g.textures.magicIcon),
                                        props = {
                                                size = util.vector2(32, 32),
                                        },
                                } or {},
                                {
                                        type = ui.TYPE.Image,
                                        props = {
                                                resource = ui.texture {
                                                        path = record.icon,
                                                },
                                                size = util.vector2(32, 32),
                                        },
                                }
                        },
                        events = {
                                focusGain = async:callback(function(_, l)
                                        selectEqWindow:highlight(currIndex, false)
                                end),
                                focusLoss = async:callback(function(_, l)
                                        selectEqWindow:deHighlight(currIndex)
                                end),

                        }
                }


                table.insert(selectEqWindow.itemsLayouts, layout)

                itemsLayouts[#itemsLayouts].content:add(layout)
                itemsLayouts[#itemsLayouts].content:add(g.gui.makeInt(4, 0))

                if i % ROW_LEN == 0 then
                        itemsLayouts[#itemsLayouts].content:add(g.gui.makeInt(20, 0))
                        --- Next row
                        table.insert(itemsLayouts, {
                                type = ui.TYPE.Flex,
                                props = { horizontal = true },
                                content = ui.content {
                                        g.gui.makeInt(20, 0)
                                }
                        })
                end

                ::continue::
        end

        itemsLayouts[#itemsLayouts].content:add(getEmptyEqSlotLayout(eqSlot))
        itemsLayouts[#itemsLayouts].content:add(g.gui.makeInt(20, 0))

        table.insert(itemsLayouts, 1, g.gui.makeInt(0, 20))
        table.insert(itemsLayouts, g.gui.makeInt(0, 20))

        return itemsLayouts
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

        ---@param a GameObject
        ---@param b GameObject
        table.sort(equippableItems, function(a, b)
                if types.Actor.hasEquipped(self, a) == types.Actor.hasEquipped(self, b) then
                        return a.type.record(a).name:lower() < b.type.record(b).name:lower()
                else
                        return types.Actor.hasEquipped(self, a)
                end
        end)


        local itemsLayouts = getTextItemsLayouts(eqSlot, equippableItems)


        if itemsLayouts[3] then
                selectEqWindow.index = 3
        else
                selectEqWindow.index = 1
        end


        listEl = ScrollableList:new('itemsList', itemsLayouts)

        if selectEqWindow.element.layout then
                selectEqWindow.element:destroy()
        end

        selectEqWindow.element = ui.create {
                layer = 'Windows',
                type = ui.TYPE.Flex,
                template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, true),
                props = {
                        relativePosition = util.vector2(0.5, 0),
                        anchor = util.vector2(0.5, 0),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                        size = util.vector2(460, 1),
                        horizontal = true,
                },
                content = ui.content {
                        {
                                name = 'contentFlex',
                                type = ui.TYPE.Flex,
                                template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, true),
                                external = { grow = 1 },
                                props = {

                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                },
                                content = ui.content {
                                        g.gui.makeInt(0, 4),
                                        listEl.element,
                                        g.toolTip.emptyLayout,
                                        g.gui.makeInt(0, 4),

                                }

                        },
                },
                events = {
                        -- focusGain = async:callback(function()
                        --         ---@diagnostic disable-next-line: undefined-field
                        --         selectEqWindow.element.layout.content.contentFlex.content.toolTip = g.toolTip
                        --             .emptyLayout
                        --         table.insert(g.myVars.myDelayedActions, selectEqWindow.element)
                        --         return true
                        -- end),
                        mouseMove = async:callback(function(e)
                                g.util.mouse:update(e.position)
                                return true
                        end)
                }
        }


        selectEqWindow:highlight(nil, true)
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

        ---@param a GameObject
        ---@param b GameObject
        table.sort(equippableItems, function(a, b)
                if a.recordId ~= b.recordId then
                        return a.type.record(a).name:lower() < b.type.record(b).name:lower()
                else
                        return a.recordId == g.myVars.instrument
                end
        end)


        local itemsLayouts = getTextInstrumentsLayouts(equippableItems)


        if itemsLayouts[3] then
                selectEqWindow.index = 3
        else
                selectEqWindow.index = 1
        end


        listEl = ScrollableList:new('itemsList', itemsLayouts)

        if selectEqWindow.element.layout then
                selectEqWindow.element:destroy()
        end

        selectEqWindow.element = ui.create {
                layer = 'Windows',
                type = ui.TYPE.Flex,
                template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, true),
                props = {
                        relativePosition = util.vector2(0.5, 0),
                        anchor = util.vector2(0.5, 0),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                        size = util.vector2(460, 1),
                        horizontal = true,
                },
                content = ui.content {
                        -- g.gui.makeInt(2, 0),
                        {
                                name = 'contentFlex',
                                type = ui.TYPE.Flex,
                                template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, true),
                                external = { grow = 1 },
                                props = {

                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                },
                                content = ui.content {
                                        g.gui.makeInt(0, 4),
                                        listEl.element,
                                        g.toolTip.emptyLayout,
                                        g.gui.makeInt(0, 4),

                                }

                        },
                        -- g.gui.makeInt(2, 0),
                },
                events = {
                        focusGain = async:callback(function()
                                ---@diagnostic disable-next-line: undefined-field
                                selectEqWindow.element.layout.content.contentFlex.content.toolTip = g.toolTip
                                    .emptyLayout
                                table.insert(g.myVars.myDelayedActions, selectEqWindow.element)
                                return true
                        end),
                }
        }


        selectEqWindow:highlight(nil, true)
end

local function getKeepPrevSlotLO()
        return {
                type = ui.TYPE.Image,
                props = {
                        resource = g.textures.keepPrevEq,
                        size = util.vector2(32, 32),
                },
        }
end

local function getEmptySlotLO()
        return {
                type = ui.TYPE.Image,
                props = {
                        resource = g.textures.emptyEq,
                        size = util.vector2(32, 32),
                },
        }
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
                        {
                                name = 'overlay',
                                type = ui.TYPE.Widget,
                                props = {
                                        size = util.vector2(32, 32),
                                        alpha = 0.7
                                }

                        }
                },
        }
end

---@param eq MyEq
---@param secondWeapon Weapon
---@param instrument string
local function getLoadoutGraph(eq, secondWeapon, instrument, nav)
        ---@type table<number, ui.Layout>
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
                                                },
                                                {
                                                        name = 'overlay',
                                                        type = ui.TYPE.Widget,
                                                        props = {
                                                                size = util.vector2(32, 32),
                                                                alpha = 0.7
                                                        }

                                                }
                                        },
                                }
                        end
                elseif v == myTypes.SLOTS.CarriedLeft and core.contentFiles.has('dualwielding.omwscripts') == true and secondWeapon and secondWeapon:isValid() then
                        local isMagical = secondWeapon.type.record(secondWeapon).enchant
                        slotsLOs[v] = {
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
                                                        resource = ui.texture { path = secondWeapon.type.record(secondWeapon).icon },
                                                        size = util.vector2(32, 32),
                                                },
                                        },
                                        {
                                                name = 'overlay',
                                                type = ui.TYPE.Widget,
                                                props = {
                                                        size = util.vector2(32, 32),
                                                        alpha = 0.7
                                                }

                                        }
                                },
                        }
                else
                        if keepPrev then
                                slotsLOs[v] = getKeepPrevSlotLO()
                        else
                                slotsLOs[v] = getEmptySlotLO()
                        end
                end


                if nav then
                        slotsLOs[v].events = {
                                mousePress = async:callback(function()
                                        selectEquipmentWindow(v)
                                        return true
                                end),
                                focusGain = async:callback(function()
                                        nav:deHighlight()
                                        nav:highlight(myTypes.SLOT_GRAPH_TO_LIST[v] + 1)
                                        return true
                                end)
                        }
                end
        end

        local instrumentSlotLayout

        if core.contentFiles.has('Bardcraft.omwscripts') == true and g.myVars.performerInfo then
                if instrument then
                        instrumentSlotLayout = getItemSlotLO(types.Miscellaneous.records[instrument].icon, false, nil)
                else
                        instrumentSlotLayout = getEmptySlotLO()
                end

                if nav then
                        instrumentSlotLayout.events = {
                                mousePress = async:callback(function()
                                        selectInstrumentWindow()
                                        return true
                                end),
                                focusGain = async:callback(function()
                                        nav:deHighlight()
                                        nav:highlight(20)
                                        return true
                                end)
                        }
                end
        else
                instrumentSlotLayout = g.gui.emptyLO
        end


        return {

                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                userData = {
                        slotsLOs = slotsLOs,
                        instrumentLO = instrumentSlotLayout,
                },
                props = {
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center
                },
                content = ui.content {
                        -- g.gui.makeInt(0, 10),
                        {
                                name = 'currEqName',
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = '',
                                        textSize = 20,
                                }
                        },
                        g.gui.makeInt(0, 40),
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
                        -- g.gui.makeInt(0, 10),

                }

        }
end

return {
        getLoadoutGraph = getLoadoutGraph,
        selectEquipmentWindow = selectEquipmentWindow,
        selectInstrumentWindow = selectInstrumentWindow,
}
