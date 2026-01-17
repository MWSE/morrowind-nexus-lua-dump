local types          = require('openmw.types')
local ambient        = require('openmw.ambient')
local self           = require('openmw.self')
local core           = require('openmw.core')
local async          = require('openmw.async')
local ui             = require('openmw.ui')
local I              = require('openmw.interfaces')
local util           = require('openmw.util')
local myTypes        = require("scripts.ActorInteractions.myLib.myTypes")
local toolTip        = require("scripts.ActorInteractions.myLib.toolTip")
local g              = require('scripts.ActorInteractions.myLib')
local events         = require('scripts.ActorInteractions.events')
local scrollableGrid = require('scripts.ActorInteractions.myLib.scrollableGrid')
local scrollableList = require("scripts.ActorInteractions.myLib.scrollableList")
local simpleList     = require("scripts.ActorInteractions.myLib.simpleList")
local createLoadout  = require("scripts.ActorInteractions.contents.createLoadout")
local myWindow       = require('scripts.ActorInteractions.myLib.window')

local storage        = require('openmw.storage')
local o              = require('scripts.ActorInteractions.settingsData').o
local SECTION_KEY    = require('scripts.ActorInteractions.settingsData').SECTION_KEY
local mySection      = storage.playerSection(SECTION_KEY)


local TEXT_BAR_LEN       = 50
local MAX_TRAIN_TOKENS   = 10

---@class RequiredStats
---@field disp number
---@field speech number

---@enum (key) ACTIONS
local ACTIONS            = {
        teach = 1,
        dress = 2,
        feed  = 3,
        give  = 4,
}

---@enum (key) REQ_STATS
local REQ_STATS          = {
        disp   = 1,
        speech = 2,
}

local giveawayView       = {
        ---@type ui.Element|{}
        giveItemsWindow = {},
        ---@type ScrollableList|ScrollableGrid|{}
        itemsList = {},
        ---@type SimpleList|{}
        actionsList = {},

        ---@type ui.Layout
        layout = {},

        ---@type ui.Layout
        requirementsLO = {},

        trainTokensRefillReq = nil,

        ---@type number
        trainTokens = 0,
}
---@type {give: RequiredStats, teach: RequiredStats, feed: RequiredStats, dress: RequiredStats}
giveawayView.ACTIONS_REQ = {
        give = {
                disp = 65,
                speech = 40,
        },
        teach = {
                disp = 80,
                speech = 55,
        },
        feed = {
                disp = 90,
                speech = 70,
        },
        dress = {
                disp = 100,
                speech = 50
        }
}

local CAN_EQUIP          = {
        [types.Armor] = true,
        [types.Clothing] = true,
        [types.Weapon] = true,
}

local CONSUMABLE         = {
        [types.Potion] = true,
        [types.Ingredient] = true,
}


local function updateReqLayout()
        ---@diagnostic disable-next-line: undefined-field
        giveawayView.layout.content.mainFlex.content.reqsFlex.content.reqs.content = ui.content(
                giveawayView
                .requirementsLO)
        table.insert(g.myVars.myDelayedActions, g.myVars.mainWindow.tabManager.contentContainer)
end

---@param index number
local function giveawayItemFocusGain(index)
        toolTip.currentId = nil
        if giveawayView.itemsList then
                giveawayView.itemsList:deHighlight()
                giveawayView.itemsList:highlight(index, false)
        end
end

---@param item ScrollableItem
---@param target NPC
local function mousePressTeach(item, target)
        if types.NPC.spells(target)[item.spell.id] then
                ui.showMessage(string.format('%s already knows how to %s', target.type.record(target).name, item.name))
        else
                -- print('item.spell.cost = ', item.spell.cost)
                local magickaCost = item.spell.cost * 1.5
                local fatigueCost = item.spell.cost * 2

                if types.NPC.stats.dynamic.magicka(self).current < magickaCost or types.NPC.stats.dynamic.fatigue(self).current < fatigueCost then
                        ui.showMessage(string.format('%0.2f magicka + %0.2f fatigue needed to teach that spell',
                                magickaCost, fatigueCost
                        ))

                        return
                end


                types.NPC.stats.dynamic.magicka(self).current = types.NPC.stats.dynamic.magicka(self).current -
                    magickaCost

                types.NPC.stats.dynamic.fatigue(self).current = types.NPC.stats.dynamic.fatigue(self).current -
                    fatigueCost



                core.sendGlobalEvent(events.teachSpell, { spellId = item.spell.id, target = target })
                ambient.playSoundFile(g.soundFiles.spellCreate)
        end
end

---@param item ScrollableItem
---@param target NPC
local function mousePressDelete(item, target)
        core.sendGlobalEvent(events.deleteNPCSpell, { spellId = item.spell.id, target = target })
        -- g.layouts.getConfirmLayout(function()
        --         core.sendGlobalEvent(events.deleteNPCSpell, { spellId = item.spell.id, target = target })
        -- end)
end

---@param item ScrollableItem
---@param target NPC
local function mousePressFeed(item, target)
        ---@type {object: GameObject, actor: NPC}
        local useItemData = { object = item.object, actor = target }
        core.sendGlobalEvent('UseItem', useItemData)
        table.insert(g.myVars.doLater, {
                action = function()
                        giveawayView.itemsList:updateItems()
                end,
                skip = 3
        })
end

---@param item ScrollableItem
---@param target NPC
local function mousePressGive(item, target)
        local currentWeight = types.Actor.getEncumbrance(target)
        local totalCap = types.Actor.getCapacity(target)
        local newWeight = currentWeight + item.object.type.record(item.object).weight

        if newWeight > totalCap then
                ui.showMessage('Not enough capacity')
                return
        else
                ---@type {object: GameObject, to: NPC}
                local moveItemData = { object = item.object, to = target }
                core.sendGlobalEvent(events.moveItem, moveItemData)
        end
end

---@param item ScrollableItem
---@param target NPC
---@param index number
---@param mousePressCallback fun(item: ScrollableItem, target: NPC)
---@return ui.Layout
local function createListItemLayout(item, target, index, mousePressCallback)
        local layout = g.layouts.getTextListItemLayout(item)
        layout.events = {
                focusGain = async:callback(function()
                        giveawayItemFocusGain(index)
                        return true
                end),
                mousePress = async:callback(function(e)
                        if e.button ~= 1 then return end
                        mousePressCallback(item, target)
                        return true
                end)
        }

        return layout
end

---@param item ScrollableItem
---@param target NPC
---@param index number
---@param mousePressCallback fun(item: ScrollableItem, target: NPC)
---@return ui.Layout
local function createGridItemLayout(item, target, index, mousePressCallback)
        local layout = g.layouts.getGridItemLayout(item)
        layout.events = {
                focusGain = async:callback(function()
                        giveawayItemFocusGain(index)
                        return true
                end),
                mousePress = async:callback(function(e)
                        if e.button ~= 1 then return end
                        mousePressCallback(item, target)
                        return true
                end)
        }

        return layout
end

---@param target NPC
---@param mousePressAction fun()
---@return ScrollableGrid|ScrollableList
---@return fun(item: ScrollableItem, index: number): fun()
local function initScrollableInfo(target, mousePressAction)
        local scrollable
        local getLayout
        if mySection:get(o.selectWindowView.key) == 'Icon View' then
                scrollable = scrollableGrid
                getLayout = function(item, index)
                        return createGridItemLayout(item, target, index, mousePressAction)
                end
        else
                scrollable = scrollableList
                getLayout = function(item, index)
                        return createListItemLayout(item, target, index, mousePressAction)
                end
        end

        return scrollable, getLayout
end


---@param listLayout ui.Layout
local function createItemSelectionWindow(listLayout)
        if giveawayView.giveItemsWindow.layout then
                giveawayView.giveItemsWindow:destroy()
        end

        giveawayView.giveItemsWindow = ui.create {
                layer = 'Windows',
                type = ui.TYPE.Flex,
                template = g.templates.getTemplate('none', { 0, 0, 0, 0 }, true),
                props = {
                        anchor = util.vector2(0.5, 0.5),
                        relativePosition = util.vector2(0.5, 0.5),
                        -- size = util.vector2(200, 200)
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        horizontal = true,
                                        relativeSize = util.vector2(0.9, 1),
                                },
                                content = ui.content {
                                        g.gui.makeInt(2, 0),
                                        listLayout,
                                        g.gui.makeInt(2, 0),
                                }
                        }
                },
                events = {
                        mouseMove = async:callback(function(e)
                                g.util.mouse:update(e.position)
                                return true
                        end)
                }
        }
end



---@param target NPC
---@param statFun fun(actor: NPC): DynamicStat
---@return string
---@return string
local function getDynamicStat(target, statFun)
        local base = statFun(target).base
        local current = statFun(target).current
        local statText = string.format('%d / %d', current, base)
        local statBar = g.gui.makeTextBar(current, base, TEXT_BAR_LEN, false)
        return statText, statBar
end


---@param action ACTIONS
---@param stat REQ_STATS
---@return number
local function getRequirement(action, stat)
        return giveawayView.ACTIONS_REQ[action][stat] * mySection:get(o.requirementMult.key)
end

---@param target NPC
---@param stats RequiredStats
---@return boolean
function giveawayView.checkRequirements(target, stats)
        if target.type == types.NPC then
                local disp = types.NPC.getDisposition(target, self)
                local reqDisp = stats.disp * mySection:get(o.requirementMult.key)
                if disp < reqDisp then
                        ui.showMessage(string.format('Requires %d disposition', reqDisp))
                        return false
                end
        end

        local speechCraft = types.NPC.stats.skills.speechcraft(self).modified
        local reqSpeech = stats.speech * mySection:get(o.requirementMult.key)
        if speechCraft < reqSpeech then
                ui.showMessage(string.format('Requires %d speechcraft', reqSpeech))
                return false
        end

        return true
end

---@param caster NPC
local function spellCastChance(caster)
        -- print('cost:', thing.cost)
end


---@param target NPC
---@return SimpleListData
local function getViewMagicEntry(target)
        return {
                text = 'View magic effects',
                action = function()
                        giveawayView.itemsList = scrollableList:new('playerItems', {
                                updateParentElement = function()
                                        local contentEl = giveawayView.giveItemsWindow
                                        if contentEl.layout then
                                                table.insert(g.myVars.myDelayedActions, contentEl)
                                        end
                                end,
                                getItems = function()
                                        ---@type ScrollableItem[]
                                        local scrollableItemsList = {}
                                        local spells = types.Actor.activeSpells(target)
                                        ---@param spell ActiveSpell
                                        for _, spell in pairs(spells) do
                                                ---@param effect ActiveSpellEffect
                                                for _, effect in pairs(spell.effects) do
                                                        table.insert(scrollableItemsList, {
                                                                name = effect.name,
                                                                icon = core.magic.effects.records[effect.id]
                                                                    .icon,
                                                                spell = spell,
                                                                effect = effect,
                                                        })
                                                end
                                        end


                                        ---@param a ScrollableItem
                                        ---@param b ScrollableItem
                                        table.sort(scrollableItemsList, function(a, b)
                                                return a.name < b.name
                                        end)

                                        return scrollableItemsList
                                end,
                                getLayout = function(item, index)
                                        local effectStr = item.effect.name
                                        if item.effect.magnitudeThisFrame then
                                                effectStr = effectStr ..
                                                    string.format(' %d pts ', item.effect.magnitudeThisFrame)
                                        end
                                        if item.effect.durationLeft then
                                                effectStr = effectStr ..
                                                    string.format('%.2f s ',
                                                            item.effect.durationLeft)
                                                --     string.format(' Duration: %.2f s ',
                                                --             item.effect.durationLeft)
                                        end


                                        if item.spell.item then
                                                effectStr = effectStr ..
                                                    string.format('[%s]',
                                                            item.spell.item.type.record(item.spell.item)
                                                            .name)
                                        else
                                                effectStr = effectStr ..
                                                    string.format('[%s]', item.spell.name)
                                        end

                                        local layout = g.layouts.getCustomTextListItemLayout(effectStr, item
                                                .icon)
                                        layout.events = {
                                                focusGain = async:callback(function()
                                                        giveawayItemFocusGain(index)
                                                        return true
                                                end),
                                                mousePress = async:callback(function()
                                                        return true
                                                end)
                                        }

                                        return layout
                                end
                        })
                        createItemSelectionWindow(giveawayView.itemsList.element)
                end,
                onFocus = function()
                        giveawayView.requirementsLO = {
                                g.gui.makeText('-')
                        }
                        updateReqLayout()
                end
        }
end

---@param target NPC
---@return SimpleListData
local function getViewSpellsEntry(target)
        return {
                text = 'View Spells',
                action = function()
                        local scrollable = scrollableList
                        local getLayout = function(item, index)
                                return createListItemLayout(item, target, index, function() end)
                        end

                        giveawayView.itemsList = scrollable:new('playerItems', {
                                updateParentElement = function()
                                        local contentEl = giveawayView.giveItemsWindow
                                        if contentEl.layout then
                                                table.insert(g.myVars.myDelayedActions, contentEl)
                                        end
                                end,
                                getItems = function()
                                        local actorSpells = types.Actor.spells(target)

                                        ---@type ScrollableItem[]
                                        local listItems = {}
                                        for i = 1, #actorSpells do
                                                ---@type Spell
                                                local spell = actorSpells[i]
                                                if spell.type == core.magic.SPELL_TYPE.Spell then
                                                        ---@type ScrollableItem
                                                        local scrollableItem = {
                                                                spell = spell,
                                                                name = spell.name,
                                                                icon = spell.effects[1].effect.icon,
                                                        }
                                                        table.insert(listItems, scrollableItem)
                                                end
                                        end

                                        ---@param a ScrollableItem
                                        ---@param b ScrollableItem
                                        table.sort(listItems, function(a, b)
                                                return a.name < b.name
                                        end)

                                        return listItems
                                end,
                                getLayout = getLayout,
                        })

                        createItemSelectionWindow(giveawayView.itemsList.element)
                end,
                onFocus = function()
                        giveawayView.requirementsLO = {
                                g.gui.makeText('-')
                        }
                        updateReqLayout()
                end

        }
end

---@param target NPC
---@param isFollower boolean|nil
---@return SimpleListData
local function getTeachSpellsEntry(target, isFollower)
        return {
                text = 'Teach spells',
                action = function()
                        if not isFollower and giveawayView.checkRequirements(target, giveawayView.ACTIONS_REQ.teach) == false then
                                return
                        end

                        local scrollable = scrollableList
                        local getLayout = function(item, index)
                                return createListItemLayout(item, target, index, mousePressTeach)
                        end

                        giveawayView.itemsList = scrollable:new('playerItems', {
                                updateParentElement = function()
                                        local contentEl = giveawayView.giveItemsWindow
                                        if contentEl.layout then
                                                table.insert(g.myVars.myDelayedActions, contentEl)
                                        end
                                end,
                                getItems = function()
                                        local playerSpells = types.Actor.spells(self)

                                        -- local targetSpells = types.Actor.spells(target)
                                        -- for i, v in ipairs(targetSpells) do
                                        --         if playerSpells[v.id] then
                                        --                 print(v.name, v.cost, playerSpells[v.id].cost)
                                        --         end
                                        -- end

                                        ---@type ScrollableItem[]
                                        local listItems = {}
                                        for i = 1, #playerSpells do
                                                ---@type Spell
                                                local spell = playerSpells[i]
                                                if spell.type == core.magic.SPELL_TYPE.Spell then
                                                        ---@type ScrollableItem
                                                        local scrollableItem = {
                                                                spell = spell,
                                                                name = spell.name,
                                                                icon = spell.effects[1].effect.icon,
                                                        }
                                                        table.insert(listItems, scrollableItem)
                                                end
                                        end


                                        ---@param a ScrollableItem
                                        ---@param b ScrollableItem
                                        table.sort(listItems, function(a, b)
                                                return a.name < b.name
                                        end)

                                        return listItems
                                end,
                                getLayout = getLayout,
                        })

                        createItemSelectionWindow(giveawayView.itemsList.element)
                end,
                onFocus = function()
                        if isFollower then
                                giveawayView.requirementsLO = {
                                        g.gui.makeText('-'),
                                }
                        else
                                giveawayView.requirementsLO = {
                                        g.gui.makeText('Disposition: ' .. tostring(getRequirement("teach", 'disp')),
                                                g.sizes.H5),
                                        g.gui.makeText(
                                                'Speechcraft: ' .. tostring(getRequirement("teach", 'speech')),
                                                g.sizes.H5),
                                }
                        end
                        updateReqLayout()
                end
        }
end

---@param target NPC
---@param isFollower boolean|nil
---@return SimpleListData
local function getRemoveSpellsEntry(target, isFollower)
        return {
                text = 'Remove spells',
                action = function()
                        if not isFollower and giveawayView.checkRequirements(target, giveawayView.ACTIONS_REQ.teach) == false then
                                return
                        end

                        local scrollable = scrollableList
                        local getLayout = function(item, index)
                                return createListItemLayout(item, target, index, mousePressDelete)
                        end

                        giveawayView.itemsList = scrollable:new('playerItems', {
                                updateParentElement = function()
                                        local contentEl = giveawayView.giveItemsWindow
                                        if contentEl.layout then
                                                table.insert(g.myVars.myDelayedActions, contentEl)
                                        end
                                end,
                                getItems = function()
                                        local actorSpells = types.Actor.spells(target)

                                        ---@type ScrollableItem[]
                                        local listItems = {}
                                        for i = 1, #actorSpells do
                                                ---@type Spell
                                                local spell = actorSpells[i]
                                                if spell.type == core.magic.SPELL_TYPE.Spell then
                                                        ---@type ScrollableItem
                                                        local scrollableItem = {
                                                                spell = spell,
                                                                name = spell.name,
                                                                icon = spell.effects[1].effect.icon,
                                                        }
                                                        table.insert(listItems, scrollableItem)
                                                end
                                        end


                                        ---@param a ScrollableItem
                                        ---@param b ScrollableItem
                                        table.sort(listItems, function(a, b)
                                                return a.name < b.name
                                        end)

                                        return listItems
                                end,
                                getLayout = getLayout,
                        })

                        createItemSelectionWindow(giveawayView.itemsList.element)
                end,
                onFocus = function()
                        if isFollower then
                                giveawayView.requirementsLO = {
                                        g.gui.makeText('-'),
                                }
                        else
                                giveawayView.requirementsLO = {
                                        g.gui.makeText('Disposition: ' .. tostring(getRequirement("teach", 'disp')),
                                                g.sizes.H5),
                                        g.gui.makeText(
                                                'Speechcraft: ' .. tostring(getRequirement("teach", 'speech')),
                                                g.sizes.H5),
                                }
                        end
                        updateReqLayout()
                end
        }
end

---@param target NPC
---@param isFollower boolean|nil
---@return SimpleListData
local function getFeedEntry(target, isFollower)
        return {
                text = 'Feed',
                action = function()
                        if not isFollower and giveawayView.checkRequirements(target, giveawayView.ACTIONS_REQ.feed) == false then
                                return
                        end

                        local scrollable, getLayout = initScrollableInfo(target, mousePressFeed)

                        giveawayView.itemsList = scrollable:new('playerItems', {
                                updateParentElement = function()
                                        local contentEl = giveawayView.giveItemsWindow
                                        if contentEl.layout then
                                                table.insert(g.myVars.myDelayedActions, contentEl)
                                        end
                                end,
                                getItems = function()
                                        local allPlayerItems = types.Actor.inventory(self):getAll()
                                        if not allPlayerItems then
                                                return {}
                                        end
                                        ---@type ScrollableItem[]
                                        local equippable = {}
                                        for i = 1, #allPlayerItems do
                                                local item = allPlayerItems[i]
                                                if CONSUMABLE[item.type] then
                                                        -- table.insert(equippable, item)
                                                        ---@type Record
                                                        local record = item.type.record(item)
                                                        ---@type ScrollableItem
                                                        local scrollableItem = {
                                                                object = item,
                                                                name = record.name,
                                                                icon = record.icon,
                                                                magical = record.enchant and true,
                                                                equipped = types.Actor.hasEquipped(target, item),
                                                                count = item.count,
                                                        }
                                                        table.insert(equippable, scrollableItem)
                                                end
                                        end


                                        ---@param a ScrollableItem
                                        ---@param b ScrollableItem
                                        table.sort(equippable, function(a, b)
                                                return a.name < b.name
                                        end)


                                        return equippable
                                end,
                                getLayout = getLayout,
                        })

                        createItemSelectionWindow(giveawayView.itemsList.element)
                end,
                onFocus = function()
                        if isFollower then
                                giveawayView.requirementsLO = {
                                        g.gui.makeText('-'),
                                }
                        else
                                giveawayView.requirementsLO = {
                                        g.gui.makeText('Disposition: ' .. tostring(getRequirement("feed", "disp")),
                                                g.sizes.H5),
                                        g.gui.makeText('Speechcraft: ' .. tostring(getRequirement("feed", 'speech')),
                                                g.sizes.H5),
                                }
                        end
                        updateReqLayout()
                end
        }
end

---@param target NPC
---@param isFollower boolean|nil
---@return SimpleListData
local function getGiveItemsEntry(target, isFollower)
        return {
                text = 'Give items',
                action = function()
                        if target.type ~= types.NPC then
                                ui.showMessage('Target not valid')
                                return
                        end

                        if not isFollower and giveawayView.checkRequirements(target, giveawayView.ACTIONS_REQ.give) == false then
                                return
                        end


                        local scrollable, getLayout = initScrollableInfo(target, mousePressGive)


                        giveawayView.itemsList = scrollable:new('playerItems', {
                                updateParentElement = function()
                                        local contentEl = giveawayView.giveItemsWindow
                                        if contentEl.layout then
                                                table.insert(g.myVars.myDelayedActions, contentEl)
                                        end
                                end,
                                getItems = function()
                                        ---@type Item[]|nil
                                        local allPlayerItems = types.Actor.inventory(self):getAll()
                                        if not allPlayerItems then
                                                return {}
                                        end
                                        ---@type ScrollableItem[]
                                        local equippable = {}
                                        for i = 1, #allPlayerItems do
                                                local item = allPlayerItems[i]
                                                if CAN_EQUIP[item.type] and types.Actor.hasEquipped(self, item) == false then
                                                        ---@type Record
                                                        local record = item.type.record(item)
                                                        ---@type ScrollableItem
                                                        local scrollableItem = {
                                                                object = item,
                                                                name = record.name,
                                                                icon = record.icon,
                                                                magical = record.enchant and true,
                                                                count = item.count,
                                                                equipped = types.Actor.hasEquipped(target, item),
                                                        }
                                                        table.insert(equippable, scrollableItem)
                                                end
                                        end

                                        return equippable
                                end,
                                getLayout = getLayout,
                        })

                        createItemSelectionWindow(giveawayView.itemsList.element)
                end,
                onFocus = function()
                        if isFollower then
                                giveawayView.requirementsLO = {
                                        g.gui.makeText('-'),
                                }
                        else
                                giveawayView.requirementsLO = {
                                        g.gui.makeText('Disposition: ' .. tostring(getRequirement("give", "disp")),
                                                g.sizes.H5),
                                        g.gui.makeText('Speechcraft: ' .. tostring(getRequirement('give', "speech")),
                                                g.sizes.H5),
                                }
                        end
                        updateReqLayout()
                end
        }
end

---@param target NPC
---@param isFollower boolean|nil
---@return SimpleListData
local function getDressUpEntry(target, isFollower)
        return {
                text = 'Dress up',
                action = function()
                        if not isFollower and giveawayView.checkRequirements(target, giveawayView.ACTIONS_REQ.dress) == false then
                                return
                        end


                        g.myVars.dressUpWindow = myWindow:new('dressup', 0, 0, {
                                {
                                        name = 'Dress up',
                                        getContent = function()
                                                ---@type ui.Layout
                                                local layout
                                                if target.type == types.NPC then
                                                        -- local req = giveawayView.checkRequirements(target,
                                                        --         giveawayView.ACTIONS_REQ
                                                        --         .dress)

                                                        -- if req == true then
                                                        --         layout = createLoadout.getCreateLoadoutLO(target)
                                                        -- else
                                                        --         local text = string.format("Low opinion/skill")
                                                        --         layout = g.gui.centerText(text)
                                                        -- end
                                                        layout = createLoadout.getCreateLoadoutLO(target)
                                                else
                                                        local text = string.format("You cannot dress up %s",
                                                                target.type.record(target).name)
                                                        layout = g.gui.centerText(text)
                                                end

                                                return layout
                                        end
                                }
                        }, true, target.type.record(target).name)

                        if g.myVars.dressUpWindow.tabManager then
                                g.myVars.dressUpWindow.tabManager.selectTab(1)
                        end

                        -- g.myVars.mainWindow.tabManager.selectTab(2)
                end,
                onFocus = function()
                        if isFollower then
                                giveawayView.requirementsLO = {
                                        g.gui.makeText('-'),
                                }
                        else
                                giveawayView.requirementsLO = {
                                        g.gui.makeText('Disposition: ' .. tostring(getRequirement("dress", "disp")),
                                                g.sizes.H5),
                                        g.gui.makeText(
                                                'Speechcraft: ' .. tostring(getRequirement("dress", "speech")),
                                                g.sizes.H5),
                                }
                        end
                        updateReqLayout()
                end
        }
end

---@param target NPC
---@return SimpleListData
local function getRepairEntry(target)
        return {
                text = 'Repair equipment',
                action = function()
                        local scrollable = scrollableList
                        local getLayout = function(item, index)
                                local object = item.object
                                local condition = types.Item.itemData(object).condition or 0

                                ---@type Record
                                local record = object.type.record(object)

                                local max = record.maxCondition or record.health or record.duration

                                local stat = g.gui.makeLabelWithBar('Condition ',
                                        g.gui.makeGUIBar(condition, max, 130, 18, 'ff0000')
                                )

                                local layout = g.layouts.getTextListItemLayout(item, stat)

                                layout.events = {
                                        focusGain = async:callback(function()
                                                giveawayItemFocusGain(index)
                                                return true
                                        end),
                                        mousePress = async:callback(function(e)
                                                if e.button ~= 1 then return end

                                                local repairTools = {}
                                                local playerItems = types.Actor.inventory(self):getAll(types
                                                        .Repair) or {}
                                                for i = 1, #playerItems do
                                                        table.insert(repairTools, playerItems[i])
                                                end
                                                if #repairTools < 1 then
                                                        ui.showMessage('No repair tools available')
                                                        return
                                                end
                                                table.sort(repairTools, function(a, b)
                                                        return a.type.record(a).quality <
                                                            b.type.record(b).quality
                                                end)
                                                -- for i, v in pairs(repairTools) do
                                                --         print(i, v, v.type.record(v).quality)
                                                -- end

                                                ---@type GameObject
                                                local tool = repairTools[1]

                                                core.sendGlobalEvent(events.repairItem, {
                                                        tool = tool,
                                                        item = item.object,
                                                        max = max,
                                                        owner = self
                                                })

                                                ambient.playSoundFile(g.soundFiles.repair)

                                                table.insert(g.myVars.doLater, {
                                                        action = function()
                                                                giveawayView.itemsList:updateItems()
                                                        end,
                                                        skip = 3
                                                })

                                                return true
                                        end)
                                }
                                return layout
                        end

                        giveawayView.itemsList = scrollable:new('playerItems', {
                                updateParentElement = function()
                                        local contentEl = giveawayView.giveItemsWindow
                                        if contentEl.layout then
                                                table.insert(g.myVars.myDelayedActions, contentEl)
                                        end
                                end,
                                getItems = function()
                                        ---@type Item[]|nil
                                        local allNPCItems = types.Actor.inventory(target):getAll()
                                        if not allNPCItems then
                                                return {}
                                        end
                                        ---@type ScrollableItem[]
                                        local equippable = {}
                                        for i = 1, #allNPCItems do
                                                local item = allNPCItems[i]

                                                local condition = types.Item.itemData(item).condition

                                                if not condition then
                                                        goto continue
                                                end

                                                ---@type Record
                                                local record = item.type.record(item)
                                                local max = record.maxCondition or record.health

                                                if condition == max then
                                                        goto continue
                                                end

                                                ---@type ScrollableItem
                                                local scrollableItem = {
                                                        object = item,
                                                        name = record.name,
                                                        icon = record.icon,
                                                        magical = record.enchant and true,
                                                        count = item.count,
                                                        equipped = types.Actor.hasEquipped(target, item),
                                                }

                                                table.insert(equippable, scrollableItem)
                                                ::continue::
                                        end

                                        return equippable
                                end,
                                getLayout = getLayout,
                        })

                        createItemSelectionWindow(giveawayView.itemsList.element)
                end,
                onFocus = function()
                        giveawayView.requirementsLO = {
                                g.gui.makeText('Any repair tool (will use lowest quality first)')
                        }
                        updateReqLayout()
                end
        }
end

---@param target NPC
---@return SimpleListData
local function getRechargeEntry(target)
        return {
                text = 'Recharge enchanted items',
                action = function()
                        local soulGems = {}
                        local playerItems = types.Actor.inventory(self):getAll(types.Miscellaneous) or {}
                        -- if not playerItems then return end
                        for _, v in pairs(playerItems) do
                                local soul = types.Item.itemData(v).soul
                                if soul then
                                        local soulValue = types.Creature.records[soul].soulValue

                                        table.insert(soulGems, {
                                                gem = v,
                                                soulValue = soulValue,
                                        })
                                end
                        end

                        if #soulGems < 1 then
                                ui.showMessage('No soul gems available')
                                return
                        end

                        table.sort(soulGems, function(a, b)
                                return a.soulValue < b.soulValue
                        end)

                        local scrollable = scrollableList
                        local getLayout = function(item, index)
                                local object = item.object
                                local charge = types.Item.itemData(object).enchantmentCharge or 0

                                ---@type Record
                                local record = object.type.record(object)

                                ---@type Enchantment
                                local enchantment = core.magic.enchantments.records
                                    [record.enchant]

                                local stat = g.gui.makeLabelWithBar('Charge ',
                                        g.gui.makeGUIBar(charge, enchantment.charge, 130, 18, 'ff0000')
                                )

                                local layout = g.layouts.getTextListItemLayout(item, stat)

                                layout.events = {
                                        focusGain = async:callback(function()
                                                giveawayItemFocusGain(index)
                                                return true
                                        end),
                                        mousePress = async:callback(function(e)
                                                if e.button ~= 1 then return end
                                                -- (0.75 + %Fatigue) × (Enchant + Intelligence/5 + Luck/10 - 3 × "Enchantment points")
                                                -- local fatigue = types.Actor.stats.dynamic.fatigue(self).current
                                                -- local enchantSkill = types.Actor.stats.skills.enchant(self).modified
                                                -- local int = types.Actor.stats.attributes.intelligence(self).modified
                                                -- local luck = types.Actor.stats.attributes.luck(self).modified
                                                if #soulGems < 1 then
                                                        return
                                                end

                                                local data = table.remove(soulGems, 1)
                                                core.sendGlobalEvent(events.chargeItem,
                                                        {
                                                                gem = data.gem,
                                                                item = item.object,
                                                                max = enchantment
                                                                    .charge
                                                        })

                                                table.insert(g.myVars.doLater, {
                                                        action = function()
                                                                giveawayView.itemsList:updateItems()
                                                        end,
                                                        skip = 3
                                                })

                                                return true
                                        end)
                                }
                                return layout
                        end

                        giveawayView.itemsList = scrollable:new('playerItems', {
                                updateParentElement = function()
                                        local contentEl = giveawayView.giveItemsWindow
                                        if contentEl.layout then
                                                table.insert(g.myVars.myDelayedActions, contentEl)
                                        end
                                end,
                                getItems = function()
                                        ---@type Item[]|nil
                                        local allNPCItems = types.Actor.inventory(target):getAll()
                                        if not allNPCItems then
                                                return {}
                                        end
                                        ---@type ScrollableItem[]
                                        local equippable = {}
                                        for i = 1, #allNPCItems do
                                                local item = allNPCItems[i]

                                                local charge = types.Item.itemData(item).enchantmentCharge

                                                if not charge then
                                                        goto continue
                                                end

                                                ---@type Record
                                                local record = item.type.record(item)

                                                ---@type Enchantment
                                                local enchantment = core.magic.enchantments.records
                                                    [record.enchant]

                                                if charge == enchantment.charge then
                                                        goto continue
                                                end

                                                ---@type ScrollableItem
                                                local scrollableItem = {
                                                        object = item,
                                                        name = record.name,
                                                        icon = record.icon,
                                                        magical = record.enchant and true,
                                                        count = item.count,
                                                        equipped = types.Actor.hasEquipped(target, item),
                                                }

                                                table.insert(equippable, scrollableItem)
                                                ::continue::
                                        end

                                        return equippable
                                end,
                                getLayout = getLayout,
                        })

                        createItemSelectionWindow(giveawayView.itemsList.element)
                end,
                onFocus = function()
                        giveawayView.requirementsLO = {
                                g.gui.makeText('Any gem with soul (will use lowest value first)')
                        }
                        updateReqLayout()
                end
        }
end

---@param target NPC
---@return SimpleListData
local function getTrainSkillsEntry(target)
        return {
                text = 'Train skills',
                action = function()
                        giveawayView.itemsList = scrollableList:new('playerItems', {
                                updateParentElement = function()
                                        local contentEl = giveawayView.giveItemsWindow
                                        if contentEl.layout then
                                                table.insert(g.myVars.myDelayedActions, contentEl)
                                        end
                                end,
                                getItems = function()
                                        ---@type ScrollableItem[]
                                        local scrollableItemsList = {}

                                        ---@param skillName string
                                        ---@param skillStat fun(target: NPC): SkillStat
                                        for skillName, skillStat in pairs(types.NPC.stats.skills) do
                                                local text = string.format("%s - %s",
                                                        toolTip.affectedAttrSkill[skillName],
                                                        skillStat(target).base
                                                -- skillStat(self).base
                                                )


                                                table.insert(scrollableItemsList, {
                                                        skill = skillName,
                                                        name = text,
                                                        icon = core.stats.Skill.records[skillName].icon,
                                                })
                                        end

                                        ---@param a ScrollableItem
                                        ---@param b ScrollableItem
                                        table.sort(scrollableItemsList, function(a, b)
                                                return a.skill < b.skill
                                        end)

                                        return scrollableItemsList
                                end,
                                getLayout = function(item, index)
                                        local layout = g.layouts.getCustomTextListItemLayout(item.name, item
                                                .icon)
                                        layout.events = {
                                                focusGain = async:callback(function()
                                                        giveawayItemFocusGain(index)
                                                        return true
                                                end),
                                                mousePress = async:callback(function(e)
                                                        if e.button ~= 1 then return end
                                                        if giveawayView.trainTokens < 1 then
                                                                ui.showMessage('You have no tokens')
                                                                return
                                                        end

                                                        local skillName = toolTip.affectedAttrSkill[item.skill]

                                                        ---@type SkillStat
                                                        local playerSkill = types.NPC.stats.skills[item.skill](
                                                                self).base

                                                        ---@type SkillStat
                                                        local npcSkill = types.NPC.stats.skills[item.skill](
                                                                target).base

                                                        if playerSkill <= npcSkill then
                                                                ui.showMessage(string.format(
                                                                        "Your base %s (%d) needs to be higher than %s's %s (%d)",
                                                                        skillName,
                                                                        playerSkill,
                                                                        target.type.record(target).name,
                                                                        skillName,
                                                                        npcSkill
                                                                ))
                                                                return
                                                        end


                                                        ambient.playSoundFile(g.soundFiles.levelUp)

                                                        giveawayView.trainTokens = giveawayView.trainTokens - 1

                                                        target:sendEvent(events.trainNPCSkill,
                                                                { skill = item.skill, target = target })

                                                        table.insert(g.myVars.doLater, {
                                                                action = function()
                                                                        g.myVars.mainWindow.tabManager.selectTab(2)
                                                                        giveawayView.itemsList:updateItems()
                                                                        ui.showMessage(string.format(
                                                                                "%s's %s skill increased to %d",
                                                                                target.type.record(target).name,
                                                                                skillName,
                                                                                types.NPC.stats.skills
                                                                                [item.skill](target).base))
                                                                end,
                                                                skip = 2,
                                                        })
                                                        return true
                                                end)
                                        }

                                        return layout
                                end
                        })
                        createItemSelectionWindow(giveawayView.itemsList.element)
                end,
                onFocus = function()
                        giveawayView.requirementsLO = {
                                g.gui.makeText('1 training tokens per skill point'),
                                g.gui.makeText("Base skill higher than the npc's"),
                        }

                        updateReqLayout()
                end
        }
end

---@param target NPC
---@return SimpleListData
local function getRechargeTrainingTokensEntry(target)
        return {
                text = 'Recharge training tokens',
                action = function()
                        for i, v in pairs(giveawayView.trainTokensRefillReq) do
                                if #types.Actor.inventory(self):findAll(i) < v then
                                        ui.showMessage(string.format('Not enough %s',
                                                types.Potion.records[i].name))
                                        return
                                end
                        end


                        core.sendGlobalEvent(events.refillTrainTokens,
                                { items = giveawayView.trainTokensRefillReq })
                        giveawayView.trainTokens = MAX_TRAIN_TOKENS
                        ambient.playSoundFile(g.soundFiles.potion)
                        ambient.playSoundFile(g.soundFiles.enchant)
                        giveawayView.trainTokensRefillReq = nil
                end,
                onFocus = function()
                        giveawayView.requirementsLO = {}

                        if not giveawayView.trainTokensRefillReq then
                                local allItems = myTypes.TOKENS_REFILL_BASE
                                -- local allItems = {}
                                local count = math.random(3, 7)
                                -- local count = math.random(1, 3)
                                -- local count = 1
                                for _ = 1, count do
                                        local random = math.random(1, #myTypes.TOKENS_REFILL_EXTRA)
                                        local recordId = myTypes.TOKENS_REFILL_EXTRA[random]
                                        local item = types.Potion.records[recordId]
                                        -- print(random, recordId, item)
                                        if not allItems[item.id] then
                                                allItems[item.id] = 0
                                        end

                                        allItems[item.id] = allItems[item.id] + 1
                                end
                                giveawayView.trainTokensRefillReq = allItems
                        end


                        ---@param recordId string
                        for recordId, count in pairs(giveawayView.trainTokensRefillReq) do
                                local record = types.Potion.records[recordId]
                                local textStr = string.format('(%d/%d) %s',
                                        #types.Actor.inventory(self):findAll(record.id),
                                        count,
                                        record.name
                                )

                                local layout = {
                                        type = ui.TYPE.Flex,
                                        userData = {
                                                recordId = recordId,
                                        },
                                        -- template = I.MWUI.templates.borders,
                                        props = {
                                                horizontal = true,
                                                align = ui.ALIGNMENT.Center,
                                        },
                                        content = ui.content {
                                                {
                                                        type = ui.TYPE.Image,
                                                        -- template = I.MWUI.templates.borders,
                                                        props = {
                                                                resource = ui.texture { path = record.icon },
                                                                size = util.vector2(g.sizes.H5, g.sizes.H5)
                                                        }
                                                },
                                                g.gui.makeInt(4, 0),
                                                {
                                                        template = I.MWUI.templates.textNormal,
                                                        props = {
                                                                text = textStr,
                                                                textSize = g.sizes.H5,
                                                        }
                                                }
                                        }
                                }


                                table.insert(giveawayView.requirementsLO, layout)
                        end



                        table.sort(giveawayView.requirementsLO, function(a, b)
                                return a.userData.recordId < b.userData.recordId
                        end)

                        updateReqLayout()
                end
        }
end

---@param target NPC
---@param isFollower boolean|nil
function giveawayView.getItemsLO(target, isFollower)
        ---@type SimpleListData[]
        local listData = {
                getViewMagicEntry(target),
                getViewSpellsEntry(target),
                getTeachSpellsEntry(target, isFollower),
                getRemoveSpellsEntry(target, isFollower),
                getFeedEntry(target, isFollower),
                target.type == types.NPC and getGiveItemsEntry(target, isFollower) or {},
                target.type == types.NPC and getDressUpEntry(target, isFollower) or {},
                target.type == types.NPC and getRepairEntry(target) or {},
                target.type == types.NPC and getRechargeEntry(target) or {},
                target.type == types.NPC and getTrainSkillsEntry(target) or {},
                (target.type == types.NPC and giveawayView.trainTokens < 1) and getRechargeTrainingTokensEntry(target) or
                {},
        }

        -- giveawayView.actionsList = simpleList:new(listData, 'Action', 'Min Disposition/Speechcraft')
        giveawayView.actionsList = simpleList:new(listData, 'Actions')

        local enc = types.Actor.getEncumbrance(target)
        local cap = types.Actor.getCapacity(target)

        local disp
        if target.type == types.NPC then
                ---@cast target NPC
                disp = types.NPC.getDisposition(target, self)
        else
                disp = 0
        end

        local layout = {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                props = {
                        -- relativeSize = util.vector2(1, 1),
                        horizontal = false,
                        -- align = ui.ALIGNMENT.Center,
                        -- arrange = ui.ALIGNMENT.Center,
                },
                external = { stretch = 1, grow = 1 },
                content = ui.content {
                        g.gui.makeInt(0, 8),
                        {
                                name = 'mainFlex',
                                type = ui.TYPE.Flex,
                                -- template = I.MWUI.templates.borders,
                                -- external = { stretch = 1, grow = 1 },
                                props = {
                                        -- align = ui.ALIGNMENT.Center,
                                        -- arrange = ui.ALIGNMENT.Center,
                                        horizontal = true
                                },
                                content = ui.content {
                                        g.gui.makeInt(8, 0),
                                        {
                                                type = ui.TYPE.Flex,
                                                -- template = I.MWUI.templates.borders,
                                                content = ui.content {
                                                        g.gui.makeLabelWithBar('Training Tokens', g.gui.makeGUIBar(giveawayView.trainTokens, MAX_TRAIN_TOKENS, 130, 18, 'ff0000')),
                                                        g.gui.makeLabelWithBar('Disposition', g.gui.makeGUIBar(disp, 100, 130, 18, '3333bb')),
                                                        g.gui.makeLabelWithBar('Capacity', g.gui.makeGUIBar(enc, cap, 130, 18, '3333bb')),
                                                        g.gui.makeInt(0, 8),
                                                        giveawayView.actionsList.layout,
                                                }
                                        },
                                        g.gui.makeInt(10, 0),
                                        -- {
                                        --         template = I.MWUI.templates.verticalLine,
                                        -- },
                                        -- g.gui.makeInt(8, 0),
                                        -- g.gui.makeInt(0, 10),
                                        {
                                                name = 'reqsFlex',
                                                type = ui.TYPE.Flex,
                                                -- template = I.MWUI.templates.borders,
                                                -- external = { stretch = 1, grow = 1 },

                                                content = ui.content {
                                                        {

                                                                template = I.MWUI.templates.textHeader,
                                                                props = {
                                                                        text = "Requirements",
                                                                        textSize = g.sizes.H5,
                                                                },
                                                        },
                                                        g.gui.makeInt(0, 10),

                                                        {

                                                                name = 'reqs',
                                                                type = ui.TYPE.Flex,
                                                                -- template = I.MWUI.templates.borders,
                                                                content = ui.content(giveawayView.requirementsLO)
                                                        }


                                                }
                                                -- content = ui.content(giveawayView.requirementsLO)

                                        }

                                }
                        },
                        g.gui.makeInt(0, 8),


                }
        }

        giveawayView.layout = layout

        giveawayView.actionsList:highlight()

        return layout
end

return giveawayView
