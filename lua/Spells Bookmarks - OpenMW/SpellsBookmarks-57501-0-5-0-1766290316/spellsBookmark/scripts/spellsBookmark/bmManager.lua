local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local util = require('openmw.util')
local async = require('openmw.async')
local types = require('openmw.types')
local core = require('openmw.core')
local self = require('openmw.self')
local ambient = require('openmw.ambient')
local ui = require('openmw.ui')
local input = require('openmw.input')
local g = require('scripts.spellsBookmark.lib')
local toolTip = require('scripts.spellsBookmark.lib.toolTip').toolTip

local o = require('scripts.spellsBookmark.settingsData').o
local SECTION_KEY = require('scripts.spellsBookmark.settingsData').SECTION_KEY

local doLater = {}
---@type string[] List of spells ids
local savedSpellsIDs = {}
---@type myWindow
MainWindow = {
        element = {}
}
local bookmarkedLookup
local listsKeys = {
        allSpells = 'allSpells',
        savedSpells = 'savedSpells',
        scrolls = 'scrolls',
        equipment = 'equipment',

}

local mySection = storage.playerSection(SECTION_KEY)
local function getSettings(sectionKey, key)
        o.showWindowOnInterface.value = mySection:get(o.showWindowOnInterface.key)
end
mySection:subscribe(async:callback(getSettings))
getSettings()

---@param spell Spell
---@param filterText string
---@return boolean
local function filterSpell(spell, filterText)
        if filterText == "" then
                return true
        end

        filterText = string.lower(filterText)
        local name = string.lower(spell.name)

        if string.find(name, filterText, 1, true) then
                return true
        end

        for i, effect in pairs(spell.effects) do
                if string.find(effect.id, filterText, 1, true) then
                        return true
                elseif effect.affectedAttribute and string.find(effect.affectedAttribute, filterText, 1, true) then
                        return true
                elseif effect.affectedSkill and string.find(effect.affectedSkill, filterText, 1, true) then
                        return true
                end
        end

        return false
end


---@param item Item
---@param filterText string
---@return boolean
local function filterName(item, filterText)
        if filterText == '' then return true end
        filterText = string.lower(filterText)
        if string.find(item.recordId, filterText, 1, true) then
                return true
        end

        local effects = core.magic.enchantments.records[item.type.record(item).enchant].effects

        for _, effect in pairs(effects) do
                if string.find(effect.id, filterText, 1, true) then
                        return true
                elseif effect.affectedAttribute and string.find(effect.affectedAttribute, filterText, 1, true) then
                        return true
                elseif effect.affectedSkill and string.find(effect.affectedSkill, filterText, 1, true) then
                        return true
                end
        end


        return false
end



local savedSortCallback = function(a, b)
        if a.layout.userData.name ~= b.layout.userData.name then
                return a.layout.userData.name:lower() < b.layout.userData.name:lower()
        end
        return false
end
local allSpellsSortCallback = function(a, b)
        if a.layout.userData.saved ~= b.layout.userData.saved then
                return a.layout.userData.saved
        else
                if a.layout.userData.name ~= b.layout.userData.name then
                        return a.layout.userData.name:lower() < b.layout.userData.name:lower()
                end
        end
        return false
end
local scrollsSortCallback = function(a, b)
        if a.layout.userData.name ~= b.layout.userData.name then
                return a.layout.userData.name:lower() < b.layout.userData.name:lower()
        end
        return false
end


local equipmentSortCallback = function(a, b)
        if a.layout.userData.equipped ~= b.layout.userData.equipped then
                return a.layout.userData.equipped == true
        else
                if a.layout.userData.name ~= b.layout.userData.name then
                        return a.layout.userData.name:lower() < b.layout.userData.name:lower()
                end
        end

        return false
end

---@type ui.Element|{}
local lastSelectedItem = {}
---@type ui.Element|{}
local lastSelectedSpell = {}

---@param color Color
---@return Color
local function getHoverColor(color)
        local red = math.min(255, color.r * 1.5)
        local green = math.min(255, color.g * 1.5)
        local blue = math.min(255, color.b * 1.5)
        return util.color.rgb(red, green, blue)
end

---@param el ui.Element
---@param keyNav? boolean
local function focusGainCall(el, keyNav)
        if keyNav then
                g.util.debounce('showToolTip', 0.3, function()
                        if el.layout and MainWindow.element.layout then
                                toolTip.showToolTip(el.layout.userData.item, true)
                        end
                end)
        end

        el.layout.props.textColor = getHoverColor(el.layout.props.textColor)
        table.insert(g.myVars.myDelayedActions, el)
end

---@param el ui.Element
local function focusLossCall(el)
        toolTip.spellID = nil
        el.layout.props.textColor = el.layout.props.originalColor
        table.insert(g.myVars.myDelayedActions, el)
end

--- ##################################################
---
--- Single Element
---
--- ##################################################

local currColor
---@param spell Spell
---@return ui.Element
local function getSavedSpellElement(spell)
        local selectedSpell = types.Player.getSelectedSpell(self.object)
        if selectedSpell and selectedSpell.id == spell.id then
                if spell.cost > types.Player.stats.dynamic.magicka(self).current then
                        currColor = g.colors.selectedButCannot
                else
                        currColor = g.colors.selected
                end
        else
                if spell.cost > types.Player.stats.dynamic.magicka(self).current then
                        currColor = g.colors.cannot
                else
                        currColor = g.colors.normal
                end
        end

        local el
        el = ui.create {
                template = I.MWUI.templates.textNormal,
                props = {
                        text = spell.name,
                        textColor = currColor,
                        originalColor = currColor,
                        textSize = g.sizes.CONTAINER_SIZE,
                },
                userData = {
                        name = spell.name,
                        item = spell,
                },
                events = {
                        mousePress = async:callback(function(e, l)
                                toolTip.spellID = nil

                                if e.button ~= 1 then return end

                                local currMagicka = types.Player.stats.dynamic.magicka(self).current

                                if lastSelectedSpell.layout and lastSelectedSpell.layout.userData.item then
                                        if lastSelectedSpell.layout.userData.item.cost > currMagicka then
                                                lastSelectedSpell.layout.props.textColor = g.colors.cannot
                                                lastSelectedSpell.layout.props.originalColor = g.colors.cannot
                                        else
                                                lastSelectedSpell.layout.props.textColor = g.colors.normal
                                                lastSelectedSpell.layout.props.originalColor = g.colors.normal
                                        end
                                        table.insert(g.myVars.myDelayedActions, lastSelectedSpell)
                                end

                                types.Player.setSelectedSpell(self, spell.id)



                                if l.userData.item.cost > currMagicka then
                                        l.props.textColor = g.colors.selectedButCannot
                                        l.props.originalColor = g.colors.selectedButCannot
                                else
                                        l.props.textColor = g.colors.selected
                                        l.props.originalColor = g.colors.selected
                                end

                                lastSelectedSpell = el

                                ambient.playSound('menu click')

                                table.insert(g.myVars.myDelayedActions, el)

                                table.insert(doLater, {
                                        action = function()
                                                g.scrollableList.all[listsKeys.equipment].updateItems(GetEquipmentEls())
                                                g.scrollableList.all[listsKeys.scrolls].updateItems(getMagicScrollsEls())
                                        end,
                                        skip = 2
                                })
                        end),
                        mouseMove = async:callback(function(e)
                                if not MainWindow.element.layout then return end
                                g.util.mouse.x = e.position.x
                                g.util.mouse.y = e.position.y
                                toolTip.showToolTip(spell)
                        end),
                        focusLoss = async:callback(function(_, l)
                                focusLossCall(el)
                                return true
                        end),

                        focusGain = async:callback(function(_, l, keyNav)
                                focusGainCall(el, keyNav)
                                return true
                        end),
                }
        }

        if currColor == g.colors.selected or currColor == g.colors.selectedButCannot then
                lastSelectedSpell = el
        end

        return el
end

---@param spell Spell
---@param isSaved boolean
---@return ui.Element
local function getAllSpellsElement(spell, isSaved)
        local el
        el = ui.create {
                template = I.MWUI.templates.textNormal,
                props = {
                        text = spell.name,
                        textColor = (isSaved and g.colors.saved) or g.colors.normal,
                        originalColor = (isSaved and g.colors.saved) or g.colors.normal,
                        textSize = g.sizes.CONTAINER_SIZE,
                },
                userData = {
                        saved = isSaved,
                        name = spell.name,
                        item = spell,
                },
                events = {
                        mousePress = async:callback(function(e, l)
                                -- toolTip.hideToolTip()
                                toolTip.spellID = nil

                                if e.button ~= 1 then return end

                                if not l.userData.saved then
                                        table.insert(savedSpellsIDs, spell.id)
                                        bookmarkedLookup[spell.id] = true
                                        l.userData.saved = true
                                        l.props.textColor = g.colors.saved
                                else
                                        l.userData.saved = false
                                        l.props.textColor = g.colors.normal

                                        for i, id in ipairs(savedSpellsIDs) do
                                                if id == spell.id then
                                                        table.remove(savedSpellsIDs, i)
                                                        bookmarkedLookup[spell.id] = false
                                                        ambient.playSound('menu click')
                                                        break
                                                end
                                        end
                                end

                                l.props.originalColor = l.props.textColor
                                g.scrollableList.all[listsKeys.allSpells].sortList()
                                g.scrollableList.all[listsKeys.savedSpells].updateItems(GetSavedSpellsEls())

                                table.insert(g.myVars.myDelayedActions, MainWindow.element)
                        end),
                        mouseMove = async:callback(function(e)
                                if not MainWindow.element.layout then return end
                                g.util.mouse.x = e.position.x
                                g.util.mouse.y = e.position.y
                                toolTip.showToolTip(spell)
                        end),
                        focusLoss = async:callback(function(_, l)
                                focusLossCall(el)
                                return true
                        end),

                        focusGain = async:callback(function(_, l, keyNav)
                                focusGainCall(el, keyNav)
                                return true
                        end),
                }
        }

        return el
end


---@param item GameObject
---@return ui.Element
local function getEnchItemElement(item)
        local selectedItem = types.Player.getSelectedEnchantedItem(self.object)

        if selectedItem and selectedItem.recordId == item.recordId then
                currColor = g.colors.selected
        else
                if types.Player.hasEquipped(self, item) or types.Book.objectIsInstance(item) then
                        currColor = g.colors.normal
                else
                        currColor = g.colors.disabled
                end
        end

        local el

        el = ui.create {
                template = I.MWUI.templates.textNormal,
                userData = {
                        item = item,
                        equipped = types.Player.hasEquipped(self, item),
                        name = item.type.record(item).name,
                },
                props = {
                        text = item.type.record(item).name,
                        textColor = currColor,
                        originalColor = currColor,
                        textSize = g.sizes.CONTAINER_SIZE,
                },
                events = {
                        mousePress = async:callback(function(e, l)
                                toolTip.spellID = nil
                                if e.button ~= 1 then return end

                                -- if not canSwitch(item) then
                                --         return
                                -- end

                                types.Player.setSelectedEnchantedItem(self, item)
                                ambient.playSound('menu click')

                                table.insert(doLater, {
                                        action = function()
                                                local items = GetEquipmentEls()
                                                table.sort(items, equipmentSortCallback)
                                                g.scrollableList.active.updateItems(items)
                                                g.scrollableList.all[listsKeys.savedSpells].updateItems(
                                                        GetSavedSpellsEls())
                                                g.scrollableList.all[listsKeys.scrolls].updateItems(getMagicScrollsEls())
                                        end,
                                        skip = 2
                                })
                        end),
                        mouseMove = async:callback(function(e)
                                if not MainWindow.element.layout then return end

                                g.util.mouse.x = e.position.x
                                g.util.mouse.y = e.position.y
                                toolTip.showToolTip(item)
                        end),
                        focusLoss = async:callback(function(_, l)
                                focusLossCall(el)
                                return true
                        end),

                        focusGain = async:callback(function(_, l, keyNav)
                                focusGainCall(el, keyNav)
                                return true
                        end),
                }
        }

        if currColor == g.colors.selected then
                lastSelectedItem = el
        end

        return el
end

---@param item any
---@return ui.Element
local function getMagicScrollElement(item)
        local selectedItem = types.Player.getSelectedEnchantedItem(self.object)

        if selectedItem and selectedItem.id == item.id then
                currColor = g.colors.selected
        else
                currColor = g.colors.normal
        end

        local el
        el = ui.create {
                template = I.MWUI.templates.textNormal,
                userData = {
                        item = item,
                        name = item.recordId,
                },
                props = {
                        text = ('%s (%d)'):format(item.type.record(item).name, item.count),
                        textColor = currColor,
                        originalColor = currColor,
                        textSize = g.sizes.CONTAINER_SIZE,
                },
                events = {
                        mousePress = async:callback(function(e, l)
                                -- toolTip.hideToolTip()
                                toolTip.spellID = nil

                                if e.button ~= 1 then return end

                                if lastSelectedItem.layout then
                                        lastSelectedItem.layout.props.textColor = g.colors.normal
                                        lastSelectedItem.layout.props.originalColor = g.colors.normal
                                        table.insert(g.myVars.myDelayedActions, lastSelectedItem)
                                end



                                types.Player.setSelectedEnchantedItem(self, item)

                                l.props.textColor = g.colors.selected
                                l.props.originalColor = g.colors.selected

                                lastSelectedItem = el

                                ambient.playSound('menu click')


                                table.insert(doLater, {
                                        action = function()
                                                g.scrollableList.all[listsKeys.equipment].updateItems(GetEquipmentEls())
                                                g.scrollableList.all[listsKeys.savedSpells].updateItems(
                                                        GetSavedSpellsEls())
                                        end,
                                        skip = 2
                                })

                                table.insert(g.myVars.myDelayedActions, el)
                        end),
                        mouseMove = async:callback(function(e)
                                if not MainWindow.element.layout then return end

                                g.util.mouse.x = e.position.x
                                g.util.mouse.y = e.position.y
                                toolTip.showToolTip(item)
                        end),
                        focusLoss = async:callback(function(_, l)
                                focusLossCall(el)
                                return true
                        end),

                        focusGain = async:callback(function(_, l, keyNav)
                                focusGainCall(el, keyNav)
                                return true
                        end),
                }
        }

        if currColor == g.colors.selected then
                lastSelectedItem = el
        end

        return el
end


--- ##################################################
---
--- Elements Lists
---
--- ##################################################



function GetSavedSpellsEls()
        local allElements = {}
        for _, spell in pairs(PlayerSpells) do
                if bookmarkedLookup[spell.id] then
                        table.insert(allElements, getSavedSpellElement(spell))
                end
        end
        table.sort(allElements, savedSortCallback)
        return allElements
end

function GetAllSpellsEls()
        local allElements = {}
        for _, spell in pairs(PlayerSpells) do
                if spell.type == core.magic.SPELL_TYPE.Spell or spell.type == core.magic.SPELL_TYPE.Power then
                        if bookmarkedLookup[spell.id] then
                                table.insert(allElements,
                                        getAllSpellsElement(spell, true))
                        else
                                table.insert(allElements,
                                        getAllSpellsElement(spell, false))
                        end
                end
        end
        table.sort(allElements, allSpellsSortCallback)
        return allElements
end

function getMagicScrollsEls()
        ---@type ui.Element[]
        local itemsInfo = {}

        ---@type GameObject[]|nil
        local items = types.Player.inventory(self):getAll()

        if not items then
                return {}
        end

        for _, item in pairs(items) do
                local ench = item.type.record(item).enchant

                if ench then
                        ---@type Enchantment
                        local record = core.magic.enchantments.records[ench]

                        if record.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
                                table.insert(itemsInfo, getMagicScrollElement(item))
                        end
                end
        end

        table.sort(itemsInfo, scrollsSortCallback)

        return itemsInfo
end

function GetEquipmentEls()
        ---@type ui.Element[]
        local itemsInfo = {}

        ---@type GameObject[]|nil
        local items = types.Player.inventory(self):getAll()

        if not items then
                return {}
        end

        for _, item in pairs(items) do
                local ench = item.type.record(item).enchant

                if ench then
                        ---@type Enchantment
                        local record = core.magic.enchantments.records[ench]
                        if record.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then
                                table.insert(itemsInfo, getEnchItemElement(item))
                        end
                end
        end

        table.sort(itemsInfo, equipmentSortCallback)
        return itemsInfo
end

---@param savedSpellsIDs string[]
---@param max? boolean
---@return myWindow
local function createMagicWindow(savedSpellsIDs, max)
        ---@type Spell[]
        PlayerSpells = types.Player.spells(self) or {}

        bookmarkedLookup = {}
        for _, id in ipairs(savedSpellsIDs) do
                bookmarkedLookup[id] = true
        end

        local savedSpellsList = g.scrollableList.create(listsKeys.savedSpells, GetSavedSpellsEls(), {
                filterFunction = filterSpell,
                sortCallback = savedSortCallback,
        })
        local allSpellsList = g.scrollableList.create(listsKeys.allSpells, GetAllSpellsEls(), {
                filterFunction = filterSpell,
                sortCallback = allSpellsSortCallback,
        })
        local scrollsList = g.scrollableList.create(listsKeys.scrolls, getMagicScrollsEls(), {
                filterFunction = filterName,
                sortCallback = scrollsSortCallback,
        })
        local equipmentList = g.scrollableList.create(listsKeys.equipment, GetEquipmentEls(), {
                filterFunction = filterName,
                sortCallback = equipmentSortCallback
        })


        local tabs = {
                {
                        name = 'Saved Spells',
                        icon = g.textures.bookmarksTab,
                        getContent = savedSpellsList.createLayout,
                },
                {
                        name = 'Add/Remove',
                        icon = g.textures.addOrRemoveTab,
                        getContent = allSpellsList.createLayout,
                },
                {
                        name = 'Scrolls',
                        icon = g.textures.scroll,
                        getContent = scrollsList.createLayout,
                },
                {
                        name = 'Equipment',
                        icon = g.textures.enchItem,
                        getContent = equipmentList.createLayout,
                },
        }


        local window = g.window:new('Magic Window', 0, 0, tabs, max)

        return window
end

local activeWindows

---@param max? boolean
local function ShowWindow(max)
        local screenSize = ui.screenSize()
        g.myVars.scale = screenSize.x / ui.layers[1].size.x
        g.myVars.res = screenSize / g.myVars.scale

        if not MainWindow.element.layout then
                MainWindow = createMagicWindow(savedSpellsIDs, max)
                activeWindows = {}
                for _, window in pairs(I.UI.getWindowsForMode(I.UI.MODE.Interface)) do
                        if I.UI.isWindowVisible and I.UI.isWindowVisible(window) then
                                table.insert(activeWindows, window)
                        end
                end


                I.UI.setMode('Interface', { windows = activeWindows })
                return true
        else
                HideWindow()
        end
end

function HideWindow()
        if MainWindow.element.layout then
                MainWindow.element:destroy()
                I.UI.removeMode('Interface')
        end

        toolTip.spellID = nil
        if toolTip.element.layout then
                toolTip.element:destroy()
        end
end

input.registerTriggerHandler(o.showMagicWindow.argument.key, async:callback(ShowWindow))
input.registerTriggerHandler(o.showMagicWindowMax.argument.key, async:callback(function()
        ShowWindow(true)
end))


local function keyActions()
        -- if not MainWindow.max then return end

        g.controls.checkKey("up", function()
                g.scrollableList.active.nextItem(-1)
                toolTip.spellID = nil
        end, true)
        g.controls.checkKey("down", function()
                g.scrollableList.active.nextItem(1)
                toolTip.spellID = nil
        end, true)

        g.controls.checkKey("select", function()
                g.scrollableList.active.selectCurrent()
                toolTip.spellID = nil
        end, false)

        g.controls.checkKey("left", function()
                MainWindow.tabManager.prevTab()
                toolTip.spellID = nil
        end, false)

        g.controls.checkKey("right", function()
                MainWindow.tabManager.nextTab()
                toolTip.spellID = nil
        end, false)
end

local function onFrame()
        if not MainWindow.element.layout then return end

        keyActions()

        for _, v in pairs(g.scrollableList.all) do
                v.onFrame()
        end

        for i = #doLater, 1, -1 do
                local entry = doLater[i]
                if entry.skip <= 0 then
                        table.remove(doLater, i)
                        if entry.action then entry.action() end
                else
                        entry.skip = entry.skip - 1
                end
        end

        for _ = 1, #g.myVars.myDelayedActions do
                table.remove(g.myVars.myDelayedActions):update()
        end

        toolTip.update()
end

local function onLoad(data)
        if not data then return end
        savedSpellsIDs = {}
        for _, id in ipairs(data.savedSpellsIDs) do
                local spell = types.Player.spells(self)[id]
                if spell then
                        table.insert(savedSpellsIDs, id)
                end
        end


        if data.windowsProps then
                g.window.windowsProps = data.windowsProps
        end
end

local function onSave()
        return { savedSpellsIDs = savedSpellsIDs, windowsProps = MainWindow.windowsProps }
end


local function onUiModeChanged(data)
        if data.newMode == 'Interface' then
                if o.showWindowOnInterface.value == true then
                        if I.UI.isWindowVisible then
                                if I.UI.isWindowVisible(I.UI.WINDOW.Inventory) then
                                        if not MainWindow.element.layout then
                                                MainWindow = createMagicWindow(savedSpellsIDs)
                                        end
                                end
                        else
                                if not MainWindow.element.layout then
                                        MainWindow = createMagicWindow(savedSpellsIDs)
                                end
                        end
                end
        else
                HideWindow()
        end


        if toolTip.element.layout then
                toolTip.element:destroy()
        end
end


return {
        interfaceName = "spellsBookmark",
        interface = {
                version = 1,
                oneKeyActionsListData = {
                        {
                                getName = function()
                                        return 'Open Spells Bookmarks Window'
                                end,
                                action = function()
                                        g.controls.resetKeys()
                                        return ShowWindow(true)
                                end,
                        }
                },
        },



        engineHandlers = {
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
                onMouseWheel = function(v, h)
                        if not MainWindow.element.layout then return end
                        for _, list in pairs(g.scrollableList.all) do
                                if list.onMouseWheel(v) then
                                        list.element:update()
                                end
                        end
                end,

                onControllerButtonPress = function(id)
                        g.controls.handlePress(id, true)
                end,
                onControllerButtonRelease = function(id)
                        g.controls.handlePress(id, nil)
                end,
                onKeyPress = function(e)
                        g.controls.handlePress(e.code, true)
                end,
                onKeyRelease = function(e)
                        g.controls.handlePress(e.code, nil)
                end
        },
        eventHandlers = {
                UiModeChanged = onUiModeChanged
        },
}
