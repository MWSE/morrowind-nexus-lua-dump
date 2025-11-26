local storage = require('openmw.storage')
local sectionKey = require('scripts.inventoryManager.settings_stuff').sectionKey
local dataSectionKey = require('scripts.inventoryManager.settings_stuff').dataSectionKey
local o = require('scripts.inventoryManager.settings_stuff').o
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
local QuickStack = require('scripts.inventoryManager.quickStack')

local toolTip = require('scripts.inventoryManager.toolTip')
local lists = require('scripts.inventoryManager.myLib.myConstants').lists
local calendar = require('openmw_aux.calendar')


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
-- local lists.SORT_BY = 1
local BAR_LEN = 10

MyDataSection = storage.playerSection(dataSectionKey)
local WINDOW_PROPS_KEY = 'WINDOW_PROPS_KEY'
local QS_CONTAINERS_KEY = 'QS_CONTAINERS'
local LOCKED_ITEMS_KEY = 'LOCKED_ITEMS_KEY'

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

        g.sizes.BOOK_PREVIEW_LENGTH = mySection:get(o.bookPreviewLength.key)
        g.sizes.BOOK_PREVIEW_WORDS_PER_LINE = mySection:get(o.bookPreviewWordsPerLine.key)

        local scrollDir
        if mySection:get(o.scrollDirection.key) == 'Reversed' then
                scrollDir = 1
        else
                scrollDir = -1
        end
        g.lists.SCROLL_AMOUNT = mySection:get(o.listScrollAmount.key) * scrollDir



        g.types.columns[2].layout.props.arrange = ui.ALIGNMENT[mySection:get(o.listAlignNumbers.key)]
        g.types.columns[3].layout.props.arrange = ui.ALIGNMENT[mySection:get(o.listAlignNumbers.key)]
        g.types.columns[4].layout.props.arrange = ui.ALIGNMENT[mySection:get(o.listAlignNumbers.key)]




        g.types.setColumnSizes()
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
---@return ItemInfo
local function getItemInfo(item)
        local itemName
        local itemType
        local hasEquipped
        local condition
        local charge
        local locked

        local record = item.type.record(item)

        ---@type ItemData
        local data = item.type.itemData(item)

        if item.type == types.Book and types.Book.records[item.recordId].isScroll then
                itemType = 'Paper'
        else
                itemType = g.types.newType[item.type] or item.type
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

                                local prog
                                if per >= 0.1 then
                                        prog = math.floor(BAR_LEN * per)
                                else
                                        prog = math.ceil(BAR_LEN * per)
                                end

                                local empt = BAR_LEN - prog
                                local color

                                if prog < 3 then
                                        color = '#FF7373'
                                elseif prog < 6 then
                                        color = '#bdbd73'
                                else
                                        color = '#73bd80'
                                end

                                condition = string.format('#73bd80[%s%s%s#73bd80]',
                                        color,
                                        string.rep('|', prog),
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

                        local prog
                        if per >= 0.1 then
                                prog = math.floor(BAR_LEN * per)
                        else
                                prog = math.ceil(BAR_LEN * per)
                        end

                        local empt = BAR_LEN - prog
                        local color

                        if prog < 3 then
                                color = '#FF7373'
                        elseif prog < 6 then
                                color = '#bdbd73'
                        else
                                color = '#4b6c71'
                        end

                        charge = string.format('#4b6c71[%s%s%s#4b6c71]',
                                color,
                                string.rep('|', prog),
                                string.rep(',', empt))
                end

                ::skip_enchant::



                itemName = record.name


                if condition then
                        itemName = string.format('%s %s', itemName, condition)
                end

                if charge then
                        itemName = string.format('%s %s', itemName, charge)
                end
        end


        hasEquipped = self.type.hasEquipped(self, item)
        locked = g.types.lockedStuff.items[item.id]

        local weight = (math.floor(record.weight * 100) / 100) * item.count

        local info = {
                object = item,
                data = data,
                id = record.id,
                icon = record.icon,
                name = itemName,
                weight = weight,
                -- weight = string.format('%.2f', weight),
                value = record.value * item.count,
                count = item.count,
                type = itemType,
                equipped = hasEquipped,
                locked = locked and true or '',
        }
        return info
end


---@param info ItemInfo
local function lockItem(info)
        if info.object.parentContainer.type == types.Container then return end

        g.types.lockedStuff.items[info.object.id] =
            not g.types.lockedStuff.items[info.object.id]

        MyDataSection:set(LOCKED_ITEMS_KEY, g.types.lockedStuff.items)
        -- UpdateLists()
        g.scrollableList.all[TABS.Player].updateItems(getItemsListEls(self))
end

---@param info ItemInfo
local function useItem(info)
        if not info.object then
                error('Could not find item: ' .. info.name)
        end

        if info.object.parentContainer.type ~= types.Player then
                return
        end

        if types.Actor.hasEquipped(self, info.object) then
                self:sendEvent('Unequip', { item = info.object })
        else
                local myEq
                local slot
                local record = info.object.type.record(info.object)
                if info.object.type == types.Armor then
                        slot = g.types.ARMOR_TYPE[record.type]
                        myEq = types.Actor.getEquipment(self, slot)
                elseif info.object.type == types.Clothing then
                        if record.type == 8 then --- Ring
                                myEq = types.Actor.getEquipment(self,
                                        g.types.SLOTS.LeftRing)
                                if myEq and g.types.lockedStuff.items[myEq.id] then
                                        myEq = types.Actor.getEquipment(self,
                                                g.types.SLOTS.RightRing)
                                end
                        else
                                slot = g.types.CLOTHING_TYPE[record.type]
                                myEq = types.Actor.getEquipment(self, slot)
                        end
                elseif info.object.type == types.Weapon then
                        myEq = types.Actor.getEquipment(self, g.types.SLOTS.CarriedRight)
                end

                if myEq and g.types.lockedStuff.items[myEq.id] then
                        ui.showMessage(string.format('Item is locked: %s',
                                myEq.type.record(myEq).name))

                        return
                end


                core.sendGlobalEvent('UseItem',
                        { object = info.object, actor = self })
        end

        table.insert(doLater, { action = UpdateLists, skip = 2 })
end

---@param info ItemInfo
local function moveItem(info)
        if not currContainer then return false end
        local eventData
        local count

        if input.isAltPressed() then
                count = 1
        else
                count = info.object.count
        end

        if info.object.parentContainer.type == types.Player then
                if info.locked == true then
                        ui.showMessage(string.format('Item is locked: %s',
                                info.object.type.record(info.object).name))
                        return
                end
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

---@return ui.Layout
local function getTopRow()
        local allEls = {}

        for index = 1, #g.types.columns do
                local value = g.types.columns[index]
                local textEl = {
                        template = I.MWUI.templates.textNormal,
                        type = ui.TYPE.Text,
                        props = {
                                text = tostring(value.header),
                                -- text = string.format('%s', tostring(value.header)),
                                textSize = g.sizes.LABEL_SIZE,
                                -- textShadow = true,
                                -- textShadowColor = util.color.rgb(0, 0, 0),
                        },
                }

                local textContainer = {
                        type = ui.TYPE.Flex,
                        -- template = I.MWUI.templates.borders,
                        props = value.headerlayout.props,
                        external = value.headerlayout.external,
                        content = ui.content { textEl },
                        events = {
                                mouseClick = async:callback(function()
                                        if lists.SORT_BY ~= index then
                                                lists.SORT_BY = index
                                                g.types.columns[lists.SORT_BY].sort.ascending = false
                                        else
                                                g.types.columns[lists.SORT_BY].sort.ascending = not g.types.columns
                                                    [lists.SORT_BY].sort
                                                    .ascending
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

        return entryContainer
end

---@param info ItemInfo
---@return ui.Element
local function getItemEntryEl(info)
        local allEls = {}

        for i = 1, #g.types.columns do
                local value = g.types.columns[i]

                local textEl

                if value.key == 'locked' then
                        textEl = {
                                -- template = I.MWUI.templates.textNormal,
                                type = ui.TYPE.Image,
                                props = {
                                        resource = info.locked == true and g.textures.lockedTrue or
                                            g.textures.lockedFalse,
                                        size = util.vector2(g.sizes.ICON_SIZE - 4, g.sizes.ICON_SIZE - 4)
                                },
                                events = {
                                        mouseClick = async:callback(function()
                                                lockItem(info)
                                        end)
                                }
                        }
                else
                        textEl = {
                                template = I.MWUI.templates.textNormal,
                                type = ui.TYPE.Text,
                                props = {
                                        text = tostring(info[value.key]),
                                        -- text = string.format('%s  ', tostring(info[value.key])),
                                        textSize = g.sizes.TEXT_SIZE,
                                },
                        }
                end


                local textContainer = {
                        -- template = I.MWUI.templates.borders,
                        type = ui.TYPE.Flex,
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
                                type = ui.TYPE.Widget,
                                props = {
                                        size = util.vector2(g.sizes.ICON_SIZE, g.sizes.ICON_SIZE),
                                },
                                content = ui.content {
                                        {
                                                template = g.templates.getTemplate(info.equipped and 'thin' or 'none', { 0, 0, 0, 0 },
                                                        true, TEX[info.id]),
                                                props = {
                                                        size = util.vector2(g.sizes.ICON_SIZE, g.sizes.ICON_SIZE),
                                                }
                                        },
                                }
                        }
                        if info.object.type.record(info.object).enchant then
                                icon.content:insert(1, {
                                        template = g.templates.getTemplate('none', { 0, 0, 0, 0 },
                                                true, g.textures.magicIcon),
                                        props = {
                                                size = util.vector2(g.sizes.ICON_SIZE, g.sizes.ICON_SIZE),
                                                alpha = 0.5
                                        }
                                })
                        end

                        textContainer.content:insert(1, g.gui.makeInt(6, 0))
                        textContainer.content:insert(1, icon)
                        textContainer.content:insert(1, g.gui.makeInt(12, 0))
                end

                table.insert(allEls, 1, textContainer)
        end

        local parentWidget
        parentWidget = ui.create {
                type = ui.TYPE.Flex,
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
                        horizontal = true,
                        align = ui.ALIGNMENT.Start,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        -- entryContainer,
                        unpack(allEls),

                        --- No need for parentContainer ???
                        -- {
                        --         type = ui.TYPE.Image,
                        --         props = {
                        --                 relativeSize = util.vector2(1, 1),
                        --         }

                        -- },
                },
                events = {
                        mouseMove = async:callback(function(e)
                                g.util.mouse.x = e.position.x
                                g.util.mouse.y = e.position.y
                                g.util.debounce('showToolTip', mySection:get(o.toolTipDelay.key), function()
                                        toolTip.showToolTip(info.object)
                                end)
                                -- g.util.debounce('showToolTip', 0.18, function()
                                --         toolTip.showToolTip(info.object)
                                -- end)
                        end),
                        focusGain = async:callback(function()
                                toolTip.currentId = info.object.id

                                parentWidget.layout.userData.list.focus = true
                                parentWidget.layout.template = g.templates.entryHighlight
                                table.insert(g.myDelayedActions, 1, parentWidget)
                        end),
                        focusLoss = async:callback(function()
                                -- toolTip.hideToolTip()
                                toolTip.currentId = nil

                                parentWidget.layout.userData.list.focus = false
                                parentWidget.layout.template = g.templates.entryNormal
                                table.insert(g.myDelayedActions, 1, parentWidget)
                        end),
                        mouseClick = async:callback(function()
                                if input.isCtrlPressed() then
                                        if info.object.parentContainer.type == types.Player and info.locked == true then
                                                ui.showMessage(string.format('Item is locked: %s',
                                                        info.object.type.record(info.object).name))
                                                return
                                        end

                                        if not info.object then
                                                error('Could not find item: ' .. info.name)
                                        end

                                        core.sendGlobalEvent(events.dropItem, {
                                                item = info.object,
                                        })
                                elseif input.isShiftPressed() then
                                        useItem(info)
                                elseif input.isSuperPressed() then
                                        lockItem(info)
                                else
                                        moveItem(info)
                                end
                        end),

                }
        }
        return parentWidget
end

---@param object GameObject
---@return ui.Element[]
function getItemsListEls(object)
        local items = object.type.inventory(object):getAll()

        ---@type ItemInfo[]
        local itemsInfoList = {}
        for i = 1, #items do
                table.insert(itemsInfoList, getItemInfo(items[i]))
        end

        table.sort(itemsInfoList, g.types.columns[lists.SORT_BY].sort.callback)

        ---@type ui.Element[]
        local allItemsEls = {}
        for i = 1, #itemsInfoList do
                table.insert(allItemsEls, getItemEntryEl(itemsInfoList[i]))
        end

        return allItemsEls
end

---@param obj GameObject|nil
---@return GameObject|nil
local function getOpenedContainer(obj)
        -- local obj = data.arg
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
        end

        local invRecord = types.Container.record(obj)
        if invRecord.isOrganic or invRecord.isRespawning then
                return
        end

        return obj
end

---@param container GameObject|nil
local function showPlayerInventory(container)
        toolTip.gv.Year = calendar.formatGameTime("%Y", core.getGameTime())
        toolTip.gv.PCNAME = self.type.record(self).name
        toolTip.gv.pcname = self.type.record(self).name
        toolTip.gv.PCName = self.type.record(self).name
        toolTip.gv.PCClass = types.NPC.classes.records[self.type.record(self).class].name
        toolTip.gv.PCRace = types.NPC.races.records[self.type.record(self).race].name

        local list = g.scrollableList.create(TABS.Player, getItemsListEls(self), {
                header = getTopRow(),
                filterFunction = simpleTextFilter,
                filterButtons = g.types.filterButtons,
                quickStackButtons = QuickStack.getPlayerQuickStackButtons,
        })

        local tabs = {
                {
                        name = TABS.Player,
                        getContent = list.createLayout,
                },
        }


        if container then
                currContainer = getOpenedContainer(container)

                if currContainer then
                        local containerList = g.scrollableList.create(TABS.Container, getItemsListEls(currContainer),
                                {
                                        header = getTopRow(),
                                        filterFunction = simpleTextFilter,
                                        filterButtons = g.types.filterButtons,
                                        quickStackButtons = QuickStack.getContainerQuickStack,
                                        container = currContainer

                                })

                        table.insert(tabs, {
                                name = currContainer.type.record(container).name,
                                getContent = containerList.createLayout,
                        })
                else
                        return
                end
        end

        MainWindow = g.window.createResizableWindow({
                title = 'Interface',
                tabs = tabs,
                default = tabs[1].name,
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
        -- for i, v in pairs(QuickStack.allContainers) do
        --         table.insert(cList, string.format('id:%s active:%s byName:%s Name:%s',
        --                 v.id,
        --                 v.quickStackTarget,
        --                 v.byName,
        --                 v.name
        --         ))
        -- end
        -- g.util.setDebugText(table.concat(cList, '\n'))

        if not MainWindow.layout then return end

        for i = #doLater, 1, -1 do
                local entry = doLater[i]
                if entry.skip <= 0 then
                        table.remove(doLater, i)
                        if entry.action then entry.action() end
                else
                        entry.skip = entry.skip - 1
                end
        end

        while #g.myDelayedActions > 0 do
                table.remove(g.myDelayedActions):update()
        end

        for _, list in pairs(g.scrollableList.all) do
                list.onFrame()
        end


        toolTip.update()
end

function SortLists()
        g.scrollableList.all[TABS.Player].sortList(g.types.columns[lists.SORT_BY].sort.callback)
        if currContainer then
                g.scrollableList.all[TABS.Container].sortList(g.types.columns[lists.SORT_BY].sort.callback)
        end
end

function UpdateLists()
        g.scrollableList.all[TABS.Player].updateItems(getItemsListEls(self))
        if currContainer then
                g.scrollableList.all[TABS.Container].updateItems(getItemsListEls(currContainer))
        end
end

local function onLoad()
        g.window.getWindowProps(MyDataSection:getCopy(WINDOW_PROPS_KEY))
        QuickStack.updateAllContainers(MyDataSection:getCopy(QS_CONTAINERS_KEY))
        local locakedItems = MyDataSection:getCopy(LOCKED_ITEMS_KEY)
        g.types.lockedStuff.items = locakedItems
end

local function onSave()
        MyDataSection:set(WINDOW_PROPS_KEY, g.window.saveWindowProps())
        MyDataSection:set(QS_CONTAINERS_KEY, QuickStack.saveContainers())
        MyDataSection:set(LOCKED_ITEMS_KEY, g.types.lockedStuff.items)
end

local function hideAll()
        if MainWindow.layout then
                auxUi.deepDestroy(MainWindow)
        end
        currContainer = nil
        for _, v in pairs(g.scrollableList.all) do
                v.focus = false
        end
        toolTip.hideToolTip()
        toolTip.currentId = nil
end


local showInvKeyHandler = function(a, b)
        if not MainWindow.layout then
                showPlayerInventory(nil)
                I.UI.setMode('Interface')
        else
                hideAll()
                I.UI.removeMode('Interface')
        end
end

input.registerTriggerHandler(o.showWindowKey.argument.key, async:callback(showInvKeyHandler))

local function newUiModeChanged(data)
        if data.newMode == I.UI.MODE.Interface or data.newMode == I.UI.MODE.Container then
                if I.UI.isWindowVisible then
                        if I.UI.isWindowVisible(I.UI.WINDOW.Inventory) and not MainWindow.layout then
                                showPlayerInventory(data.arg)
                        end
                else
                        if not MainWindow.layout then
                                showPlayerInventory(data.arg)
                        end
                end
        else
                if MainWindow.layout then
                        hideAll()
                end
        end
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
                UiModeChanged = newUiModeChanged,
        },
}
