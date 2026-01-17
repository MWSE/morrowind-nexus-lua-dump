local types          = require('openmw.types')
local core           = require('openmw.core')
local async          = require('openmw.async')
local ui             = require('openmw.ui')
local I              = require('openmw.interfaces')
local util           = require('openmw.util')
local myTypes        = require("scripts.ActorInteractions.myLib.myTypes")
local g              = require('scripts.ActorInteractions.myLib')
local ScrollableList = require('scripts.ActorInteractions.myLib.scrollableList')
local ScrollableGrid = require('scripts.ActorInteractions.myLib.scrollableGrid')
local toolTip        = require('scripts.ActorInteractions.myLib.toolTip')

local storage        = require('openmw.storage')
local o              = require('scripts.ActorInteractions.settingsData').o
local SECTION_KEY    = require('scripts.ActorInteractions.settingsData').SECTION_KEY
local mySection      = storage.playerSection(SECTION_KEY)




local gap            = 2
local selectEqWindow = {
        ---@type ui.Element|{}
        element = {},
        ---@type ScrollableList|ScrollableGrid
        selectEqList = nil
}

local RING_TYPE      = {
        [myTypes.SLOTS.LeftRing] = true,
        [myTypes.SLOTS.RightRing] = true,
}


-- local function updateParentEl()
--         g.myVars.dressUpWindow.tabManager.selectTab(1)
--         -- -- g.myVars.dressUpWindow.tabManager.contentContainer:update()
--         -- if g.myVars.dressUpWindow and g.myVars.dressUpWindow.tabManager.contentContainer then
--         --         -- g.myVars.dressUpWindow.tabManager.contentContainer.layout.content =
--         --         --     ui.content { g.myVars.dressUpWindow.tabManager.activeTab.getContent() }
--         --         -- g.myVars.dressUpWindow.tabManager
--         --         --     .contentContainer:update()
--         -- end
--         -- -- if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
--         -- --         g.myVars.mainWindow.tabManager.contentContainer.layout.content =
--         -- --             ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
--         -- --         g.myVars.mainWindow.tabManager
--         -- --             .contentContainer:update()
--         -- -- end
-- end

---@param slot number
---@param actor NPC
local function unEquipSlot(slot, actor)
        local skip = 3
        local item = types.Actor.getEquipment(actor, slot)
        if not item then
                selectEqWindow.element:destroy()
                return
                -- if slot == myTypes.SLOTS.CarriedLeft and g.myVars.secondWeapon then
                --         self:sendEvent('RemoveSecondWeaponUI')
                -- end
        else
                actor:sendEvent('Unequip', { item = item })
                -- if slot == myTypes.SLOTS.CarriedRight and g.myVars.secondWeapon then
                --         skip = 9
                -- end
        end

        selectEqWindow.element:destroy()

        table.insert(g.myVars.doLater, {
                action = function()
                        g.myVars.dressUpWindow.tabManager.selectTab(1)
                        -- updateParentEl()
                        -- if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
                        --         g.myVars.mainWindow.tabManager.contentContainer.layout.content =
                        --             ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
                        --         g.myVars.mainWindow.tabManager
                        --             .contentContainer:update()
                        -- end
                end,
                skip = skip,
        })
end

---@param item ScrollableItem
---@param actor NPC
---@param eqSlot number
---@return ui.Layout
local function getOneTextItemLayout(item, actor, index, eqSlot)
        local layout
        if not item.name then
                layout = g.layouts.getEmptyTextItemLayout()
                layout.events = {
                        focusGain = async:callback(function()
                                toolTip.currentId = nil
                                if selectEqWindow.selectEqList then
                                        selectEqWindow.selectEqList:deHighlight()
                                        selectEqWindow.selectEqList:highlight(index, false)
                                end
                                table.insert(g.myVars.myDelayedActions, selectEqWindow.element)
                                return true
                        end),
                        mousePress = async:callback(function(e)
                                if e.button ~= 1 then
                                        selectEqWindow.element:destroy()
                                        return
                                end
                                unEquipSlot(eqSlot, actor)
                        end)
                }
        else
                layout = g.layouts.getTextListItemLayout(item)
                layout.events = {
                        focusGain = async:callback(function()
                                toolTip.currentId = nil
                                if selectEqWindow.selectEqList then
                                        selectEqWindow.selectEqList:deHighlight()
                                        selectEqWindow.selectEqList:highlight(index, false)
                                end
                                table.insert(g.myVars.myDelayedActions, selectEqWindow.element)
                                return true
                        end),
                        mousePress = async:callback(function(e)
                                if e and e.button ~= 1 then return end


                                ---@type {object: GameObject, actor: NPC}
                                local useItemData = { object = item.object, actor = actor }
                                core.sendGlobalEvent('UseItem', useItemData)

                                selectEqWindow.element:destroy()

                                local skip = 2


                                table.insert(g.myVars.doLater, {
                                        action = function()
                                                g.myVars.dressUpWindow.tabManager.selectTab(1)
                                                -- updateParentEl()
                                                -- if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
                                                --         g.myVars.mainWindow.tabManager.contentContainer.layout.content =
                                                --             ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
                                                --         g.myVars.mainWindow.tabManager
                                                --             .contentContainer:update()
                                                -- end
                                        end,
                                        skip = skip,
                                })
                        end)
                }
        end

        return layout
end


---@param item ScrollableItem
---@param actor NPC
---@param eqSlot number
---@return ui.Layout
local function getOneGridItemLayout(item, actor, index, eqSlot)
        local layout
        if not item.name then
                layout = g.layouts.getEmptyGridItemLayout()
                layout.events = {
                        focusGain = async:callback(function()
                                toolTip.currentId = nil
                                if selectEqWindow.selectEqList then
                                        selectEqWindow.selectEqList:deHighlight()
                                        selectEqWindow.selectEqList:highlight(index, false)
                                end
                                table.insert(g.myVars.myDelayedActions, selectEqWindow.element)
                                return true
                        end),
                        mousePress = async:callback(function(e)
                                if e.button ~= 1 then
                                        selectEqWindow.element:destroy()
                                        return
                                end
                                unEquipSlot(eqSlot, actor)
                        end)
                }
        else
                layout = g.layouts.getGridItemLayout(item)
                layout.events = {
                        focusGain = async:callback(function()
                                toolTip.currentId = nil
                                if selectEqWindow.selectEqList then
                                        selectEqWindow.selectEqList:deHighlight()
                                        selectEqWindow.selectEqList:highlight(index, false)
                                end
                                table.insert(g.myVars.myDelayedActions, selectEqWindow.element)
                                return true
                        end),
                        mousePress = async:callback(function(e)
                                if e and e.button ~= 1 then return end


                                ---@type {object: GameObject, actor: NPC}
                                local useItemData = { object = item.object, actor = actor }
                                core.sendGlobalEvent('UseItem', useItemData)

                                selectEqWindow.element:destroy()

                                local skip = 2


                                table.insert(g.myVars.doLater, {
                                        action = function()
                                                g.myVars.dressUpWindow.tabManager.selectTab(1)
                                                -- updateParentEl()
                                                -- if g.myVars.mainWindow and g.myVars.mainWindow.tabManager.contentContainer then
                                                --         g.myVars.mainWindow.tabManager.contentContainer.layout.content =
                                                --             ui.content { g.myVars.mainWindow.tabManager.activeTab.getContent() }
                                                --         g.myVars.mainWindow.tabManager
                                                --             .contentContainer:update()
                                                -- end
                                        end,
                                        skip = skip,
                                })
                        end)

                }
        end

        return layout
end




---@param list table
---@param item GameObject
---@param record Record
---@param actor NPC
local function addToList(list, item, record, actor)
        ---@type ScrollableItem
        local scrollableItem = {
                object = item,
                name = record.name,
                icon = record.icon,
                magical = record.enchant and true,
                count = item.count,
                equipped = types.Actor.hasEquipped(actor, item)
        }
        table.insert(list, scrollableItem)
end

---@param eqSlot number
---@param actor NPC
---@return ScrollableItem[]
local function getEquippableItems(eqSlot, actor)
        local items = types.Actor.inventory(actor):getAll()
        if not items then return {} end
        local equippableItems = {}

        for _, item in pairs(items) do
                local itemSlot

                ---@type Record
                local record = item.type.record(item)
                if item.type == types.Armor then
                        itemSlot = myTypes.ARMOR_TYPE[record.type]
                        if itemSlot == eqSlot then
                                -- table.insert(equippableItems, item)
                                addToList(equippableItems, item, record, actor)
                        end
                elseif item.type == types.Clothing then
                        if record.type == 8 and RING_TYPE[eqSlot] then
                                -- table.insert(equippableItems, item)
                                addToList(equippableItems, item, record, actor)
                        else
                                itemSlot = myTypes.CLOTHING_TYPE[record.type]
                                if itemSlot == eqSlot then
                                        -- table.insert(equippableItems, item)
                                        addToList(equippableItems, item, record, actor)
                                end
                        end
                elseif item.type == types.Weapon then
                        if myTypes.RANGED_AMMO[record.type] and eqSlot == myTypes.SLOTS.Ammunition then
                                -- table.insert(equippableItems, item)
                                addToList(equippableItems, item, record, actor)
                        elseif not myTypes.RANGED_AMMO[record.type] and eqSlot == myTypes.SLOTS.CarriedRight then
                                -- table.insert(equippableItems, item)
                                addToList(equippableItems, item, record, actor)
                        else
                                goto continue
                        end
                else
                        goto continue
                end
                ::continue::
        end

        ---@param a ScrollableItem
        ---@param b ScrollableItem
        table.sort(equippableItems, function(a, b)
                if a.equipped == b.equipped then
                        return a.name:lower() < b.name:lower()
                else
                        return a.equipped
                end
        end)

        table.insert(equippableItems, 1, 'empty')

        return equippableItems
end

---@param eqSlot number
---@param actor NPC
local function createSelectEquipmentWindow(eqSlot, actor)
        local equippableItems = getEquippableItems(eqSlot, actor)
        if not equippableItems then return end

        local scrollable
        local layoutGetter
        if mySection:get(o.selectWindowView.key) == 'Icon View' then
                ---@type ScrollableGrid
                scrollable = ScrollableGrid
                layoutGetter = function(item, index)
                        return getOneGridItemLayout(item, actor, index, eqSlot)
                end
        else
                ---@type ScrollableList
                scrollable = ScrollableList
                layoutGetter = function(item, index)
                        return getOneTextItemLayout(item, actor, index, eqSlot)
                end
        end

        selectEqWindow.selectEqList = scrollable:new('itemsList', {
                updateParentElement = function()
                        if selectEqWindow.element.layout then
                                table.insert(g.myVars.myDelayedActions, selectEqWindow.element)
                        end
                end,

                getItems = function()
                        return getEquippableItems(eqSlot, actor)
                end,
                getLayout = layoutGetter,
        })


        if selectEqWindow.element.layout then
                selectEqWindow.element:destroy()
        end

        selectEqWindow.element = ui.create {
                layer = 'Windows',
                type = ui.TYPE.Flex,
                template = g.templates.getTemplate('thick', { 0, 0, 0, 0 }, true),
                -- external = { grow = 1, stretch = 1 },
                props = {
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(0.5, 0.5),

                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                        horizontal = true,
                },
                content = ui.content {
                        {
                                name = 'contentFlex',
                                type = ui.TYPE.Flex,
                                external = { grow = 1, stretch = 1 },
                                props = {
                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                        relativeSize = util.vector2(0.8, 1),

                                },
                                content = ui.content {
                                        {
                                                type = ui.TYPE.Flex,
                                                -- template = g.templates.getTemplate('thin', { 0, 0, 0, 0 }, true),
                                                external = { grow = 1, stretch = 1, },
                                                props = {
                                                        align = ui.ALIGNMENT.Center,
                                                        arrange = ui.ALIGNMENT.Center,
                                                        horizontal = true,
                                                },
                                                content = ui.content {
                                                        g.gui.makeInt(2, 0, 0, 0),
                                                        selectEqWindow.selectEqList.element,
                                                        g.gui.makeInt(2, 0, 0, 0),
                                                }
                                        },
                                }

                        },
                },
                events = {
                        mouseMove = async:callback(function(e)
                                g.util.mouse:update(e.position)
                                return true
                        end)
                }
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


---@param icon string
---@param isMagical boolean
---@param eqSlot number
---@param actor NPC
---@return ui.Layout
local function getItemSlotLO(icon, isMagical, eqSlot, actor)
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
                                                createSelectEquipmentWindow(eqSlot, actor)
                                                -- if g.myVars.mainWindow.tabManager.activeTab.name == 'Create' then
                                                --         if eqSlot == nil then
                                                --                 -- selectInstrumentWindow()
                                                --         else
                                                --                 createSelectEquipmentWindow(eqSlot, actor)
                                                --         end
                                                -- end
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


---@param eq any
---@param nav any
---@param actor NPC
---@return table
local function getLoadoutGraph(eq, nav, actor)
        ---@type table<number, ui.Layout>
        local slotsLOs = {}

        for _, v in pairs(myTypes.SLOTS) do
                local recordId = eq[v].recordId
                local icon = eq[v].icon

                if recordId then
                        local itemInInv = types.Actor.inventory(actor):find(recordId)


                        if itemInInv then
                                local isMagical = itemInInv.type.record(itemInInv).enchant
                                slotsLOs[v] = getItemSlotLO(icon, isMagical, v, actor)
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
                else
                        slotsLOs[v] = getEmptySlotLO()
                end


                if nav then
                        slotsLOs[v].events = {
                                mousePress = async:callback(function()
                                        createSelectEquipmentWindow(v, actor)
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

        local instrumentSlotLayout = g.gui.emptyLO



        return {

                type = ui.TYPE.Flex,
                userData = {
                        slotsLOs = slotsLOs,
                        instrumentLO = instrumentSlotLayout,
                },
                props = {
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center
                },
                content = ui.content {
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
                }

        }
end

return {
        getLoadoutGraph = getLoadoutGraph,
        createSelectEquipmentWindow = createSelectEquipmentWindow,
        selectEqWindow = selectEqWindow,
}
