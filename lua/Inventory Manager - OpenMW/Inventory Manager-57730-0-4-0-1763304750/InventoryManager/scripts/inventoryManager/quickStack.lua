local async = require('openmw.async')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local core = require('openmw.core')
local input = require('openmw.input')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local util = require('openmw.util')
local events = require('scripts.inventoryManager.events')
local auxUi = require('openmw_aux.ui')
local g = require('scripts.inventoryManager.myLib')
local self = require('openmw.self')
local storage = require('openmw.storage')

local getType = require('scripts.inventoryManager.myLib.myTypes').getType
local lockedStuff = require('scripts.inventoryManager.myLib.myTypes').lockedStuff



local STACK_DISTANCE = 800

local QuickStack = {}

QuickStack.allContainers = {}

QuickStack.startStacking = false

function QuickStack.updateAllContainers(savedContainers)
        if savedContainers then
                QuickStack.allContainers = {}
                for _, v in ipairs(savedContainers) do
                        QuickStack.allContainers[v[1]] = {}
                        QuickStack.allContainers[v[1]].id = v[1]
                        QuickStack.allContainers[v[1]].name = v[2]
                        QuickStack.allContainers[v[1]].quickStackTarget = v[3]
                        QuickStack.allContainers[v[1]].byName = v[4]
                end
        end
end

local containersList = {}


function QuickStack.saveContainers()
        containersList = {}
        for i, v in pairs(QuickStack.allContainers) do
                table.insert(containersList, {
                        v.id,
                        v.name,
                        v.quickStackTarget,
                        v.byName
                })
        end
        return containersList
end

---@param container GameObject
function QuickStack.getContainerQuickStack(container)
        local id = container.id

        if not QuickStack.allContainers[id] then
                QuickStack.allContainers[id] = {
                        id = id,
                        name = container.type.record(container).name,
                        quickStackTarget = false,
                        byName = true,
                }
        end

        local el
        el = ui.create {
                type = ui.TYPE.Flex,
                template = g.templates.getTemplate('none', { 0, 0, 0, 0 }, false),
                external = { grow = 0, stretch = 1 },
                props = {
                        horizontal = true,
                        autoSize = false,
                        size = util.vector2(1, g.sizes.CONTAINER_SIZE),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,

                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        relativeSize = util.vector2(1, 1),
                                        text = string.format('Enabled: %s', QuickStack.allContainers[id].quickStackTarget and 'Yes' or 'No'),
                                        textSize = g.sizes.LABEL_SIZE,
                                        textColor = (QuickStack.allContainers[id].quickStackTarget and g.colors.selected) or g.colors.normal,
                                },
                                events = {
                                        mouseClick = async:callback(function(_, l)
                                                QuickStack.allContainers[id].quickStackTarget = not QuickStack
                                                    .allContainers
                                                    [id]
                                                    .quickStackTarget
                                                l.props.textColor = (QuickStack.allContainers[id].quickStackTarget and
                                                            g.colors.selected) or
                                                    g.colors.normal
                                                l.props.text = string.format('Enabled: %s',
                                                        QuickStack.allContainers[id].quickStackTarget and 'Yes' or 'No')

                                                table.insert(g.myDelayedActions, 1, el)
                                        end)
                                }
                        },
                        g.gui.makeInt(50, 0),
                        {
                                name = 'ruleTexts',
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true
                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        relativeSize = util.vector2(1, 1),
                                                        text = 'Stack by:',
                                                        textSize = g.sizes.LABEL_SIZE,
                                                },
                                        },
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        relativeSize = util.vector2(1, 1),

                                                        text = ' Name ',
                                                        textSize = g.sizes.LABEL_SIZE,
                                                        textColor = QuickStack.allContainers[id].byName and g.colors.selected or g.colors.normal,
                                                },
                                                events = {
                                                        mouseClick = async:callback(function(_, l)
                                                                QuickStack.allContainers[id].byName = true
                                                                ---@diagnostic disable-next-line: undefined-field
                                                                for _, v in ipairs(el.layout.content.ruleTexts.content) do
                                                                        v.props.textColor = g.colors.normal
                                                                end
                                                                l.props.textColor = g.colors.selected
                                                                table.insert(g.myDelayedActions, 1, el)
                                                        end)
                                                }
                                        },
                                        {
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                        relativeSize = util.vector2(1, 1),

                                                        text = ' Type ',
                                                        textSize = g.sizes.LABEL_SIZE,
                                                        textColor = QuickStack.allContainers[id].byName and g.colors.normal or g.colors.selected,
                                                },
                                                events = {
                                                        mouseClick = async:callback(function(_, l)
                                                                QuickStack.allContainers[id].byName = false
                                                                ---@diagnostic disable-next-line: undefined-field
                                                                for _, v in ipairs(el.layout.content.ruleTexts.content) do
                                                                        v.props.textColor = g.colors.normal
                                                                end
                                                                l.props.textColor = g.colors.selected
                                                                table.insert(g.myDelayedActions, 1, el)
                                                        end)
                                                }
                                        }
                                }
                        },
                }
        }

        return el
end

local itemTypes = {}
local itemRecordIds = {}
local containerSearch = {}


---@type [Item, Container][]
local toBeMovedData

local stackItemsToNearbyChests = function()
        toBeMovedData = {}
        for i = 1, #nearby.containers do
                containerSearch[nearby.containers[i].id] = nearby.containers[i]
        end

        local playerItems = self.type.inventory(self.object):getAll()
        if not playerItems then return end

        for pItemIndex = 1, #playerItems do
                local item = playerItems[pItemIndex]
                if lockedStuff.items[item.id] then
                        goto next_item
                end

                if types.Actor.hasEquipped(self, item) then
                        goto next_item
                end

                if item.recordId == 'gold_001' then
                        goto next_item
                end

                for id, data in pairs(QuickStack.allContainers) do
                        ---@type GameObject
                        local obj = containerSearch[id]
                        if not obj then
                                goto next_container
                        end

                        if data.quickStackTarget ~= true then goto next_container end
                        local dist = (self.position - obj.position):length()
                        if dist > STACK_DISTANCE then goto next_container end

                        local containerItems = obj.type.inventory(obj):getAll()
                        if not containerItems then
                                goto next_container
                        end

                        if data.byName then
                                itemRecordIds = {}

                                for cItemIndex = 1, #containerItems do
                                        local cItem = containerItems[cItemIndex]
                                        if not itemRecordIds[cItem.recordId] then
                                                itemRecordIds[cItem.recordId] = true
                                        end
                                end

                                for recordId, _ in pairs(itemRecordIds) do
                                        if recordId == item.recordId then
                                                table.insert(toBeMovedData, { item, obj })

                                                goto next_item
                                        end
                                end
                        else
                                itemTypes = {}

                                for cItemIndex = 1, #containerItems do
                                        local type = getType(containerItems[cItemIndex])
                                        if not itemTypes[type] then
                                                itemTypes[type] = true
                                        end
                                end

                                for type, _ in pairs(itemTypes) do
                                        if type == getType(item) then
                                                table.insert(toBeMovedData, { item, obj })

                                                goto next_item
                                        end
                                end
                        end

                        ::next_container::
                end

                ::next_item::
        end



        if #toBeMovedData == 0 then
                return
        else
                core.sendGlobalEvent(events.batchmoveItem, { itemsInfo = toBeMovedData })
                ui.showMessage(string.format('Transfered %s items', #toBeMovedData))
        end
end


local validContainers = {}

---@type ui.Element
local text
function QuickStack.getPlayerQuickStackButtons()
        validContainers = {}
        for i = 1, #nearby.containers do
                local container = nearby.containers[i]
                local dist = (self.position - container.position):length()
                if QuickStack.allContainers[container.id]
                    and QuickStack.allContainers[container.id].quickStackTarget
                    and dist < STACK_DISTANCE then
                        table.insert(validContainers, container.recordId)
                end
        end


        text = ui.create {
                template = I.MWUI.templates.textNormal,
                props = {
                        text = string.format('Quick Stack (%s nearby)', #validContainers),
                        textSize = g.sizes.LABEL_SIZE,
                        textColor = #validContainers > 0 and g.colors.normal or g.colors.disabled,
                },
                events = {
                        mouseClick = async:callback(function()
                                if #validContainers == 0 then
                                        return
                                end
                                stackItemsToNearbyChests()
                                text.layout.props.textColor = g.colors.selected
                                table.insert(g.myDelayedActions, 1, text)
                        end),
                        focusGain = async:callback(function()
                                if #validContainers == 0 then
                                        return
                                end
                                text.layout.props.textColor = g.colors.hover
                                table.insert(g.myDelayedActions, 1, text)
                        end),
                        focusLoss = async:callback(function()
                                if #validContainers == 0 then
                                        return
                                end
                                text.layout.props.textColor = g.colors.normal
                                table.insert(g.myDelayedActions, 1, text)
                        end)
                }
        }

        local flex = {
                type = ui.TYPE.Flex,
                template = g.templates.getTemplate('none', { 0, 0, 0, 0 }, false, g.textures.inactiveTab),
                external = { grow = 0, stretch = 1 },
                props = {
                        size = util.vector2(1, g.sizes.CONTAINER_SIZE),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center

                },
                content = ui.content {
                        text
                }
        }

        return flex
end

return QuickStack
