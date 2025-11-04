local storage = require('openmw.storage')
local sectionKey = require('scripts.inventoryManager.settings').sectionKey
local o = require('scripts.inventoryManager.settings').o
local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local events = require('scripts.inventoryManager.events')
local auxUi = require('openmw_aux.ui')
local g = require('scripts.inventoryManager.myLib')
local columns = require('scripts.inventoryManager.myTypes').columns
local filterButtons = require('scripts.inventoryManager.myTypes').filterButtons
local QuickStack = require('scripts.inventoryManager.quickStack')
local newType = require('scripts.inventoryManager.myTypes').newType
local ARMOR_TYPE = require('scripts.inventoryManager.myTypes').ARMOR_TYPE
local CLOTHING_TYPE = require('scripts.inventoryManager.myTypes').CLOTHING_TYPE
local SLOTS = require('scripts.inventoryManager.myTypes').SLOTS
local lockedStuff = require('scripts.inventoryManager.myTypes').lockedStuff
local setColumnSizes = require('scripts.inventoryManager.myTypes').setColumnSizes
local toolTip = require('scripts.inventoryManager.toolTip')
-- local sizes = require('scripts.inventoryManager.myLib.myConstants').sizes

local doLater = {}
local TEX = {}
local TABS = {
        Player = 'Player',
        Container = 'Container',
}
---@type ui.Element|{}
MainWindow = {}
---@type GameObject|nil
local currContainer
local sortBy = 1
local hasEquipped
local locked
local itemType
local itemName
local BAR_LEN = 10
local condition
local charge


local mySection = storage.playerSection(sectionKey)

local function getSettings(keyForSection, key)
        g.sizes.TEXT_SIZE = mySection:get(o.listItemTextSize.key)
        g.sizes.LABEL_SIZE = mySection:get(o.labelsSize.key)
        g.sizes.TOOLTIP_TEXT_SIZE = mySection:get(o.toolTipTextSize.key)
        g.sizes.CONTAINER_SIZE = g.sizes.TEXT_SIZE
        g.sizes.ICON_SIZE = g.sizes.TEXT_SIZE
        g.sizes.SCROLL_AMOUNT = g.sizes.TEXT_SIZE
        g.sizes.LABEL_SIZE = g.sizes.LABEL_SIZE
        g.sizes.TOOLTIP_TEXT_SIZE = g.sizes.TOOLTIP_TEXT_SIZE
        g.lists.SCROLL_AMOUNT = mySection:get(o.listScrollAmount.key)

        setColumnSizes()
end

mySection:subscribe(async:callback(getSettings))

getSettings()



local function simpleTextFilter(entry, filterText)
        if filterText == "" then return true end
        local itemText = string.lower(entry.layout.userData.name or "")
        local searchText = string.lower(filterText)
        return string.find(itemText, searchText, 1, true) ~= nil
end

---@param item GameObject
---@return ItemsInfo
local function getItemInfo(item)
        local record = item.type.record(item)

        ---@type ItemData
        local data = item.type.itemData(item)

        if item.type == types.Book and types.Book.records[item.recordId].isScroll then
                itemType = 'Paper'
        else
                itemType = newType[item.type] or item.type
        end

        if data.soul then
                itemName = string.format('%s - %s', record.name, data.soul)
        else
                condition = nil
                charge = nil

                if data.condition then
                        local max = record.maxCondition or record.health or record.duration

                        if not max then
                                print('NO MAX CONDITION FOR:', item.recordId)
                                itemName = record.name
                        else
                                local per = data.condition / max
                                local prog = math.floor(BAR_LEN * per)
                                local empt = BAR_LEN - prog
                                local color

                                -- if prog == BAR_LEN then
                                -- color = '#00ff00'
                                if prog == 0 then
                                        color = '#ff0000'
                                        -- else
                                        -- color = '#ffff00'
                                else
                                        color = '#73bd80'
                                end

                                condition = string.format('%s[%s%s]', color, string.rep('|', prog),
                                        string.rep(',', empt))
                        end
                end

                if data.enchantmentCharge then
                        local enchantment = core.magic.enchantments.records[record.enchant]

                        if enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect or enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
                                goto skip_enchant
                        end

                        local max = enchantment.charge

                        local per = data.enchantmentCharge / max
                        local prog = math.floor(BAR_LEN * per)
                        local empt = BAR_LEN - prog
                        local color = '#4b6c71'

                        -- if prog == BAR_LEN then
                        --         color = '#4b6c71'
                        --         -- else
                        --         -- color = '#4b6c71'
                        -- end

                        charge = string.format('%s[%s%s]', color, string.rep('|', prog),
                                string.rep(',', empt))

                        -- if data.enchantmentCharge ~= max then
                        --         charge = math.floor(100 * data.enchantmentCharge / max)
                        -- end
                end

                ::skip_enchant::



                itemName = record.name


                if condition then
                        -- itemName = string.format('%s #b8b5b9%%%s', itemName, condition)
                        itemName = string.format('%s %s', itemName, condition)
                end

                if charge then
                        itemName = string.format('%s %s', itemName, charge)
                end
        end


        hasEquipped = self.type.hasEquipped(self, item)
        locked = lockedStuff.items[item.id]

        local info = {
                object = item,
                data = data,
                id = record.id,
                icon = record.icon,
                name = itemName,
                weight = (math.floor(record.weight * 100) / 100) * item.count,
                value = record.value * item.count,
                count = item.count,
                type = itemType,
                equipped = hasEquipped,
                locked = locked and true or '',
        }
        return info
end

---@return ui.Layout
local function getTopRow()
        local allEls = {}

        for index = 1, #columns do
                local value = columns[index]
                local textEl = {
                        template = I.MWUI.templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                                text = tostring(value.header),
                                textSize = g.sizes.LABEL_SIZE,
                                -- textShadow = true,
                                -- textShadowColor = util.color.rgb(0, 0, 0),
                        },
                }

                local textContainer = {
                        type = ui.TYPE.Flex,
                        -- template = I.MWUI.templates.borders,
                        props = value.layout.props,
                        external = value.layout.external,
                        content = ui.content { textEl },
                        -- events = containerEvents
                        events = {
                                mouseClick = async:callback(function()
                                        if sortBy ~= index then
                                                sortBy = index
                                                columns[sortBy].sort.ascending = false
                                        else
                                                columns[sortBy].sort.ascending = not columns[sortBy].sort.ascending
                                        end

                                        SortLists()
                                end)
                        }
                }

                table.insert(allEls, 1, textContainer)
        end

        local entryContainer = {
                type = ui.TYPE.Flex,
                external = { grow = 0, stretch = 1 },
                -- template = I.MWUI.templates.borders,
                props = {
                        size = util.vector2(1, g.sizes.TEXT_SIZE),
                        horizontal = true,
                        align = ui.ALIGNMENT.Start,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content { unpack(allEls) },
        }

        -- entryContainer.content = ui.content { table.unpack(allEls) }
        return entryContainer
end


---@param info ItemsInfo
---@return ui.Element
local function getItemEntryEl(info)
        local allEls = {}

        for i = 1, #columns do
                local value = columns[i]
                local textEl = {
                        template = I.MWUI.templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                                text = tostring(info[value.key]),
                                textSize = g.sizes.TEXT_SIZE,
                        },
                }

                local textContainer = {
                        type = ui.TYPE.Flex,
                        -- template = I.MWUI.templates.borders,
                        props = value.layout.props,
                        external = value.layout.external,
                        content = ui.content { textEl },

                }

                if value.key == 'name' then
                        if not TEX[info.id] then
                                TEX[info.id] = ui.texture {
                                        path = info.icon,
                                }
                        end

                        local icon = {
                                -- type = ui.TYPE.Flex,
                                template = g.templates.getTemplate(info.equipped and 'thin' or 'none', { 0, 0, 0, 0 },
                                        true, TEX[info.id]),
                                props = {
                                        size = util.vector2(g.sizes.ICON_SIZE, g.sizes.ICON_SIZE),
                                }
                        }

                        textContainer.content:insert(1, g.gui.makeInt(6, 0))
                        textContainer.content:insert(1, icon)
                        -- text
                end

                table.insert(allEls, 1, textContainer)
        end

        local entryContainer = {
                type = ui.TYPE.Flex,
                template = g.templates.entryNormal,
                props = {
                        horizontal = true,
                        align = ui.ALIGNMENT.Start,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        unpack(allEls),
                },
        }

        local parentWidget
        parentWidget = ui.create {
                template = g.templates.entryNormal,
                userData = {
                        ---@type ScrollableList
                        list = nil,
                        object = info.object,
                        data = info.data,
                        id = info.id,
                        name = info.name,
                        count = info.count,
                        weight = info.weight,
                        value = info.value,
                        type = info.type,
                        equipped = info.equipped,
                        locked = info.locked
                },
                props = {
                        size = util.vector2(1, g.sizes.ICON_SIZE),
                        relativeSize = util.vector2(1, 0),
                },
                content = ui.content {
                        entryContainer,
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        relativeSize = util.vector2(1, 1),
                                }

                        },
                },
                events = {
                        mouseMove = async:callback(function(e)
                                g.util.mouse.x = e.position.x
                                g.util.mouse.y = e.position.y
                                g.util.debounce('showToolTip', 0.18, function()
                                        toolTip.showToolTip(info.object)
                                end)
                        end),
                        focusGain = async:callback(function()
                                toolTip.currentId = info.object.id

                                parentWidget.layout.userData.list.focus = true
                                parentWidget.layout.template = g.templates.entryHighlight
                                table.insert(g.myDelayedActions, 1, parentWidget)
                        end),
                        focusLoss = async:callback(function()
                                toolTip.hideToolTip()
                                toolTip.currentId = nil
                                -- toolTip.hideToolTip()

                                parentWidget.layout.userData.list.focus = false
                                parentWidget.layout.template = g.templates.entryNormal
                                table.insert(g.myDelayedActions, 1, parentWidget)
                        end),
                        mouseClick = async:callback(function()
                                if input.isCtrlPressed() then
                                        if info.object.parentContainer.type == types.Player and info.locked == true then return end

                                        if not info.object then
                                                error('Could not find item: ' .. info.name)
                                        end

                                        core.sendGlobalEvent(events.dropItem, {
                                                item = info.object,
                                        })
                                elseif input.isShiftPressed() then
                                        if not info.object then
                                                error('Could not find item: ' .. info.name)
                                        end

                                        if info.object.parentContainer.type ~= types.Player then
                                                return
                                        end



                                        if types.Actor.hasEquipped(self, info.object) then
                                                if info.locked == true then return end
                                                self:sendEvent('Unequip', { item = info.object })
                                        else
                                                local myEq
                                                local slot
                                                local record = info.object.type.record(info.object)
                                                if info.object.type == types.Armor then
                                                        slot = ARMOR_TYPE[record.type]
                                                        myEq = types.Actor.getEquipment(self, slot)
                                                elseif info.object.type == types.Clothing then
                                                        if record.type == 8 then --- Ring
                                                                myEq = types.Actor.getEquipment(self, SLOTS.LeftRing)
                                                                if myEq and lockedStuff.items[myEq.id] then
                                                                        myEq = types.Actor.getEquipment(self,
                                                                                SLOTS.RightRing)
                                                                        -- if myEq and lockedStuff.items[myEq.id] then
                                                                        --         return
                                                                        -- end
                                                                end
                                                        else
                                                                slot = CLOTHING_TYPE[record.type]
                                                                myEq = types.Actor.getEquipment(self, slot)
                                                        end
                                                elseif info.object.type == types.Weapon then
                                                        myEq = types.Actor.getEquipment(self, SLOTS.CarriedRight)
                                                        -- if myEq and lockedStuff.items[myEq.id] then
                                                        --         return
                                                        -- end
                                                end

                                                if myEq and lockedStuff.items[myEq.id] then
                                                        print(myEq, myEq.id, lockedStuff.items[myEq.id])
                                                        print('item is locked')
                                                        return
                                                end


                                                core.sendGlobalEvent('UseItem',
                                                        { object = info.object, actor = self })
                                        end

                                        table.insert(doLater, { action = UpdateLists, skip = 2 })
                                elseif input.isSuperPressed() then
                                        if info.object.parentContainer.type == types.Container then return end

                                        if lockedStuff.items[info.object.id] == nil then
                                                lockedStuff.items[info.object.id] = false
                                        end
                                        lockedStuff.items[info.object.id] = not lockedStuff.items[info.object.id]
                                        UpdateLists()
                                else
                                        if not currContainer then return false end
                                        local eventData
                                        local count

                                        if input.isAltPressed() then
                                                count = 1
                                        else
                                                count = info.object.count
                                        end

                                        if info.object.parentContainer.type == types.Player then
                                                -- print(info.locked == true)
                                                if info.locked == true then return end
                                                eventData = {
                                                        item = info.object,
                                                        from = self.object,
                                                        to = currContainer,
                                                        count = count,
                                                }
                                                core.sendGlobalEvent(events.moveItem, eventData)
                                        elseif info.object.parentContainer.type == types.Container then
                                                eventData = {
                                                        item = info.object,
                                                        from = currContainer,
                                                        to = self.object,
                                                        count = count
                                                }
                                                core.sendGlobalEvent(events.moveItem, eventData)
                                        else
                                                UpdateLists()
                                                print("Conainer not found")
                                        end
                                end
                        end),

                }
        }
        return parentWidget
end


---@param object GameObject
---@return ui.Element[]
local function getItemsListEls(object)
        local items = object.type.inventory(object):getAll()

        ---@type ItemsInfo[]
        local itemsInfoList = {}
        -- for _, item in pairs(items) do
        for i = 1, #items do
                -- local item =
                -- local info = getItemInfo(items[i])
                table.insert(itemsInfoList, getItemInfo(items[i]))
        end

        -- print('sortby = ', sortBy)
        table.sort(itemsInfoList, columns[sortBy].sort.callback)


        ---@type ui.Element[]
        local allItemsEls = {}
        -- for _, item in pairs(itemsInfoList) do
        for i = 1, #itemsInfoList do
                -- local itemEl =
                table.insert(allItemsEls, getItemEntryEl(itemsInfoList[i]))
        end

        return allItemsEls
end


---@param container GameObject|nil
local function showPlayerInventory(container, defaultTab)
        local list = g.scrollableList.create(TABS.Player, getItemsListEls(self), {
                header = getTopRow(),
                filterFunction = simpleTextFilter,
                filterButtons = filterButtons,
                quickStackButtons = QuickStack.getPlayerQuickStackButtons,
        })

        local tabs = {
                {
                        name = TABS.Player,
                        getContent = list.createLayout,
                },
        }

        if container then
                local containerList = g.scrollableList.create(TABS.Container, getItemsListEls(container),
                        -- local containerList = g.scrollableList.create(container.id, getItemsListEls(container),
                        {
                                header = getTopRow(),
                                filterFunction = simpleTextFilter,
                                filterButtons = filterButtons,
                                quickStackButtons = QuickStack.getContainerQuickStack,
                                container = container

                        })

                table.insert(tabs, {
                        name = container.type.record(container).name,
                        getContent = containerList.createLayout,
                })
        end

        MainWindow = g.window.createResizableWindow({
                title = 'Interface',
                tabs = tabs,
                default = defaultTab,
        })
end

local function onMouseWheel(vertical)
        if not MainWindow.layout then return end
        for _, list in pairs(g.scrollableList.all) do
                list.onMouseWheel(vertical)
        end
end

-- local cList = {}
local function onFrame(dt)
        -- cList = {}
        -- for i, v in pairs(nearby.containers) do
        --         if QuickStack.allContainers[v.id] then
        --            table.insert(cList, v.recordId)
        --         end
        -- end
        -- cList = {}
        -- for i, v in pairs(QuickStack.allContainers) do
        --         table.insert(cList, string.format('id:%s active:%s byName:%s Name:%s',
        --                 v.id,
        --                 v.quickStackTarget,
        --                 v.byName,
        --                 v.name
        --         ))
        -- end

        -- for i, v in pairs(g.scrollableList.all) do
        --         if v.focus then
        --                 table.insert(cList, v.key)
        --         end
        -- end
        -- g.util.setDebugText(#cList)
        -- g.util.setDebugText(table.concat(cList, '\n'))

        if not MainWindow.layout then return end



        for i = 1, #doLater do
                if doLater[i].skip <= 0 then
                        table.remove(doLater, i).action()
                else
                        doLater[i].skip = doLater[i].skip - 1
                end
        end

        for i = 1, #g.myDelayedActions do
                table.remove(g.myDelayedActions):update()
        end




        for _, list in pairs(g.scrollableList.all) do
                list.onFrame()
        end


        toolTip.update()
end


function SortLists()
        g.scrollableList.all[TABS.Player].sortList(columns[sortBy].sort.callback)
        if currContainer then
                g.scrollableList.all[TABS.Container].sortList(columns[sortBy].sort.callback)
        end
end

function UpdateLists()
        g.scrollableList.all[TABS.Player].updateItems(getItemsListEls(self))
        if currContainer then
                g.scrollableList.all[TABS.Container].updateItems(getItemsListEls(currContainer))
        end
end

local function onLoad(data)
        if not data then return end

        g.window.setWindowProps(data.props)

        QuickStack.updateAllContainers(data.allContainers)

        if data.locked then
                -- print('data.locked = ', data.locked)
                lockedStuff.items = data.locked
        end
end

local function onSave()
        local p = g.window.getWindowProps()
        local props = {
                p.pos.x,
                p.pos.y,
                p.size.x,
                p.size.y,
                p.anchor.x,
                p.anchor.y,
        }


        -- lockedStuff.items

        return { props = props, allContainers = QuickStack.saveContainers(), locked = lockedStuff.items }
end

return {
        engineHandlers = {
                onMouseWheel = onMouseWheel,
                onSave = onSave,
                onLoad = onLoad,
                onFrame = onFrame,
                onUpdate = function()
                        for key, v in pairs(g.util.currentDebounces) do
                                if core.getRealTime() > v[1] then
                                        v[2]()
                                        g.util.currentDebounces[key] = nil
                                end
                        end
                end,

                -- onKeyPress = function(e)
                --         if e.code == input.KEY.Z then

                --         end
                -- end,
        },
        eventHandlers = {
                [events.itemMoved] = function()
                        UpdateLists()
                end,
                UiModeChanged = function(data)
                        -- if data.newMode == I.UI.MODE.Container or data.newMode == I.UI.MODE.Interface then
                        if data.newMode == I.UI.MODE.Container then
                                if not MainWindow.layout then
                                        ---@type GameObject
                                        local obj = data.arg
                                        if not obj then return end
                                        if obj.type == types.NPC then return end
                                        if obj.type == types.Creature then return end
                                        if obj.owner then
                                                if obj.owner.recordId then return end
                                                if obj.owner.factionId then
                                                        local playerRank = types.NPC.getFactionRank(self, obj.owner
                                                                .factionId)
                                                        if obj.owner.factionRank > playerRank then return end
                                                end
                                                -- if obj.owner.factionRank then
                                                -- end
                                        end

                                        -- local inv = obj.type.inventory(obj).record(obj)

                                        local invRecord = types.Container.record(obj)
                                        if invRecord.isOrganic or invRecord.isRespawning then
                                                return
                                        end

                                        currContainer = obj
                                        showPlayerInventory(obj)
                                end
                        elseif data.newMode == I.UI.MODE.Interface then
                                showPlayerInventory(nil)
                        else
                                if MainWindow.layout then
                                        auxUi.deepDestroy(MainWindow)
                                        -- MainWindow:destroy()
                                end
                                currContainer = nil
                                for _, v in pairs(g.scrollableList.all) do
                                        v.focus = false
                                end
                                toolTip.hideToolTip()
                                toolTip.currentId = nil
                        end
                end
        },
}
