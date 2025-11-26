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
local colors = require('scripts.spellsBookmark.lib.myConstants').colors
local textures = require('scripts.spellsBookmark.lib.myConstants').textures
local mouse = require('scripts.spellsBookmark.lib.myUtils').mouse

local myTypes = require('scripts.spellsBookmark.lib.myTypes')


local MOD_ID = 'InventoryManager'
local prefix = 'SettingsPlayer'
local dataSectionKey = prefix .. MOD_ID .. '_DATA_'
local LOCKED_ITEMS_KEY = 'LOCKED_ITEMS_KEY'
local myDataSection = storage.playerSection(dataSectionKey)

local listsKeys = {
        allSpells = 'allSpells',
        savedSpells = 'savedSpells',
        scrolls = 'scrolls',
        equipment = 'equipment',

}


---@param item GameObject
---@return boolean
local function canSwitch(item)
        local lockedItems = myDataSection:getCopy(LOCKED_ITEMS_KEY)
        if not lockedItems then
                return true
        end

        local myEq
        local slot
        local record = item.type.record(item)
        if item.type == types.Armor then
                slot = myTypes.ARMOR_TYPE[record.type]
                myEq = types.Actor.getEquipment(self, slot)
        elseif item.type == types.Clothing then
                if record.type == 8 then --- Ring
                        myEq = types.Actor.getEquipment(self, myTypes.SLOTS.LeftRing)
                        if myEq and lockedItems[myEq.id] then
                                myEq = types.Actor.getEquipment(self,
                                        myTypes.SLOTS.RightRing)
                        end
                else
                        slot = myTypes.CLOTHING_TYPE[record.type]
                        myEq = types.Actor.getEquipment(self, slot)
                end
        elseif item.type == types.Weapon then
                myEq = types.Actor.getEquipment(self, myTypes.SLOTS.CarriedRight)
        end

        if myEq and lockedItems[myEq.id] then
                -- print(myEq, myEq.id, lockedItems[myEq.id])
                -- print('item is locked: ', myEq.id)
                ui.showMessage(string.format('Item is locked: %s', myEq.type.record(myEq).name))
                return false
        end

        return true
end

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

local o = require('scripts.spellsBookmark.settings').o
local getSectionKey = require('scripts.spellsBookmark.settings').getSectionKey
local storage = require('openmw.storage')
local mySection = storage.playerSection(getSectionKey())

local function getSettings(sectionKey, key)
        -- o[key].value = mySection:get(key)
        o.scrollDirection.value = mySection:get(o.scrollDirection.key)
        o.showWindowOnInterface.value = mySection:get(o.showWindowOnInterface.key)
        -- o.scrollDirection.value = mySection:get(o.scrollDirection.key)
end

mySection:subscribe(async:callback(getSettings))

-- o.showWindowOnInterface.value = mySection:get(o.showWindowOnInterface.key)
getSettings()

---@type string[] List of spells ids
local savedSpellsIDs = {}

---@type ui.Element|{}
MainWindow = {}
local bookmarkedLookup

---@type ui.Element|{}
local lastSelectedItem = {}
---@type ui.Element|{}
local lastSelectedSpell = {}
local Res = ui.screenSize()
local LERP_VALUE = 0.00001

---@param color Color
---@return Color
local function getHoverColor(color)
        local r = math.min(255, color.r * 1.5)
        local g = math.min(255, color.g * 1.5)
        local b = math.min(255, color.b * 1.5)
        return util.color.rgb(r, g, b)
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
                        currColor = colors.selectedButCannot
                else
                        currColor = colors.selected
                end
        else
                if spell.cost > types.Player.stats.dynamic.magicka(self).current then
                        currColor = colors.cannot
                else
                        currColor = colors.normal
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

                        -- spell = spell
                },
                userData = {
                        name = spell.name,
                        list = nil,
                        item = spell,


                },
                events = {
                        mousePress = async:callback(function(e, l)
                                toolTip.hideToolTip()
                                if e.button ~= 1 then return end

                                local currMagicka = types.Player.stats.dynamic.magicka(self).current

                                if lastSelectedSpell.layout and lastSelectedSpell.layout.userData.item then
                                        if lastSelectedSpell.layout.userData.item.cost > currMagicka then
                                                lastSelectedSpell.layout.props.textColor = colors.cannot
                                                lastSelectedSpell.layout.props.originalColor = colors.cannot
                                        else
                                                lastSelectedSpell.layout.props.textColor = colors.normal
                                                lastSelectedSpell.layout.props.originalColor = colors.normal
                                        end
                                        table.insert(g.myDelayedActions, lastSelectedSpell)
                                end

                                types.Player.setSelectedSpell(self, spell.id)

                                if l.userData.item.cost > currMagicka then
                                        l.props.textColor = colors.selectedButCannot
                                        l.props.originalColor = colors.selectedButCannot
                                else
                                        l.props.textColor = colors.selected
                                        l.props.originalColor = colors.selected
                                end


                                lastSelectedSpell = el

                                ambient.playSound('menu click')

                                table.insert(g.myDelayedActions, el)
                        end),
                        mouseMove = async:callback(function(e)
                                mouse.x = e.position.x
                                mouse.y = e.position.y
                                toolTip.showToolTip(spell)
                        end),
                        focusLoss = async:callback(function(_, l)
                                if spell.id == toolTip.spellID then
                                        toolTip.hideToolTip()
                                end

                                l.props.textColor = l.props.originalColor

                                -- RequiresUpdate = true
                                el.layout.userData.list.focus = false

                                table.insert(g.myDelayedActions, el)
                        end),

                        focusGain = async:callback(function(_, l)
                                if not toolTip.element.layout then return end
                                l.props.textColor = getHoverColor(l.props.textColor)
                                -- UIState.bookmarks.focus = true
                                el.layout.userData.list.focus = true

                                table.insert(g.myDelayedActions, el)
                        end),
                }
        }

        if currColor == colors.selected or currColor == colors.selectedButCannot then
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
                        textColor = (isSaved and colors.saved) or colors.normal,
                        originalColor = (isSaved and colors.saved) or colors.normal,
                        saved = isSaved,
                        textSize = g.sizes.CONTAINER_SIZE,
                        spell = spell,
                },
                userData = {
                        list = nil,
                        name = spell.name,
                        item = spell,



                },
                events = {
                        mousePress = async:callback(function(e, l)
                                toolTip.hideToolTip()
                                if e.button ~= 1 then return end


                                if not l.props.saved then
                                        table.insert(savedSpellsIDs, spell.id)
                                        bookmarkedLookup[spell.id] = true
                                        l.props.saved = true
                                        l.props.textColor = colors.saved
                                else
                                        l.props.saved = false
                                        l.props.textColor = colors.normal

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

                                g.scrollableList.all[listsKeys.savedSpells].updateItems(getSavedSpellsEls())

                                table.insert(g.myDelayedActions, MainWindow)
                        end),
                        mouseMove = async:callback(function(e)
                                mouse.x = e.position.x
                                mouse.y = e.position.y
                                toolTip.showToolTip(spell)
                        end),
                        focusLoss = async:callback(function(_, l)
                                if spell.id == toolTip.spellID then
                                        toolTip.hideToolTip()
                                end
                                l.props.textColor = l.props.originalColor

                                -- RequiresUpdate = true
                                el.layout.userData.list.focus = false

                                table.insert(g.myDelayedActions, el)
                        end),

                        focusGain = async:callback(function(_, l)
                                if not toolTip.element.layout then return end
                                l.props.textColor = getHoverColor(l.props.textColor)

                                -- UIState.allSpells.focus = true
                                el.layout.userData.list.focus = true
                                table.insert(g.myDelayedActions, el)
                        end),
                }
        }

        return el
end


---@param item GameObject
---@return ui.Element
local function getEnchItemElement(item)
        local selectedItem = types.Player.getSelectedEnchantedItem(self.object)

        if selectedItem and selectedItem.id == item.id then
                currColor = colors.selected
        else
                if types.Player.hasEquipped(self, item) or types.Book.objectIsInstance(item) then
                        currColor = colors.normal
                else
                        currColor = colors.disabled
                end
        end

        local el

        el = ui.create {
                template = I.MWUI.templates.textNormal,
                userData = {
                        item = item,

                        name = item.recordId,
                        list = nil,

                },
                props = {
                        text = item.type.record(item).name,
                        textColor = currColor,
                        originalColor = currColor,
                        textSize = g.sizes.CONTAINER_SIZE,
                        -- spell = item
                },
                events = {
                        mousePress = async:callback(function(e, l)
                                toolTip.hideToolTip()
                                if e.button ~= 1 then return end

                                -- if not canSwitch(item) then
                                --         return
                                -- end

                                if lastSelectedItem.layout then
                                        lastSelectedItem.layout.props.textColor = colors.normal
                                        lastSelectedItem.layout.props.originalColor = colors.normal
                                        table.insert(g.myDelayedActions, lastSelectedItem)
                                end

                                types.Player.setSelectedEnchantedItem(self, item)

                                l.props.textColor = colors.selected
                                l.props.originalColor = colors.selected

                                -- lastSelectedItem = l
                                lastSelectedItem = el

                                ambient.playSound('menu click')

                                table.insert(g.myDelayedActions, el)
                        end),
                        mouseMove = async:callback(function(e)
                                mouse.x = e.position.x
                                mouse.y = e.position.y
                                toolTip.showToolTip(item)
                        end),
                        focusLoss = async:callback(function(_, l)
                                if item.id == toolTip.spellID then
                                        toolTip.hideToolTip()
                                end

                                l.props.textColor = l.props.originalColor
                                el.layout.userData.list.focus = false


                                table.insert(g.myDelayedActions, el)
                        end),

                        focusGain = async:callback(function(_, l)
                                if not toolTip.element.layout then return end
                                l.props.textColor = getHoverColor(l.props.textColor)
                                el.layout.userData.list.focus = true
                                table.insert(g.myDelayedActions, el)
                        end),
                }
        }

        if currColor == colors.selected then
                lastSelectedItem = el
        end

        return el
end

---@param item any
---@return ui.Element
local function getMagicScrollElement(item)
        local selectedItem = types.Player.getSelectedEnchantedItem(self.object)

        if selectedItem and selectedItem.id == item.id then
                currColor = colors.selected
        else
                currColor = colors.normal
        end

        local el
        el = ui.create {
                template = I.MWUI.templates.textNormal,
                userData = {
                        item = item,
                        name = item.recordId,
                        list = nil,
                },
                props = {
                        text = ('%s (%d)'):format(item.type.record(item).name, item.count),
                        textColor = currColor,
                        originalColor = currColor,
                        textSize = g.sizes.CONTAINER_SIZE,
                        -- spell = item
                },
                events = {
                        mousePress = async:callback(function(e, l)
                                toolTip.hideToolTip()
                                if e.button ~= 1 then return end

                                if lastSelectedItem.layout then
                                        lastSelectedItem.layout.props.textColor = colors.normal
                                        lastSelectedItem.layout.props.originalColor = colors.normal
                                        table.insert(g.myDelayedActions, lastSelectedItem)
                                end

                                types.Player.setSelectedEnchantedItem(self, item)

                                l.props.textColor = colors.selected
                                l.props.originalColor = colors.selected

                                lastSelectedItem = el

                                ambient.playSound('menu click')

                                table.insert(g.myDelayedActions, el)
                        end),
                        mouseMove = async:callback(function(e)
                                mouse.x = e.position.x
                                mouse.y = e.position.y
                                toolTip.showToolTip(item)
                        end),
                        focusLoss = async:callback(function(_, l)
                                if item.id == toolTip.spellID then
                                        toolTip.hideToolTip()
                                end

                                l.props.textColor = l.props.originalColor
                                el.layout.userData.list.focus = false


                                table.insert(g.myDelayedActions, el)
                                -- RequiresUpdate = true
                        end),

                        focusGain = async:callback(function(_, l)
                                if not toolTip.element.layout then return end
                                l.props.textColor = getHoverColor(l.props.textColor)
                                el.layout.userData.list.focus = true
                                -- UIState.bookmarks.focus = true
                                table.insert(g.myDelayedActions, el)
                        end),
                }
        }

        if currColor == colors.selected then
                lastSelectedItem = el
        end

        return el
end


--- ##################################################
---
--- Elements Lists
---
--- ##################################################


local savedSortCallback = function(a, b)
        if a.layout.userData.name ~= b.layout.userData.name then
                return a.layout.userData.name < b.layout.userData.name
        end
        return false
end
local allSpellsSortCallback = function(a, b)
        if a.layout.props.saved ~= b.layout.props.saved then
                return a.layout.props.saved
        else
                if a.layout.userData.name ~= b.layout.userData.name then
                        return a.layout.userData.name < b.layout.userData.name
                end
        end
        return false
end
local scrollsSortCallback = function(a, b)
        if a.layout.userData.name ~= b.layout.userData.name then
                return a.layout.userData.name < b.layout.userData.name
        end
        return false
end
local equipmentSortCallback = function(a, b)
        if a.layout.userData.name ~= b.layout.userData.name then
                return a.layout.userData.name < b.layout.userData.name
        end
        return false
end


function getSavedSpellsEls()
        local allElements = {}
        for _, spell in pairs(PlayerSpells) do
                if bookmarkedLookup[spell.id] then
                        table.insert(allElements, getSavedSpellElement(spell))
                end
        end
        table.sort(allElements, savedSortCallback)
        return allElements
end

function getAllSpellsEls()
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

local function getMagicScrollsEls()
        ---@type ui.Element[]
        local itemsInfo = {}

        ---@type GameObject[]
        local items = types.Player.inventory(self):getAll()

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

local function getEquipmentEls()
        ---@type ui.Element[]
        local itemsInfo = {}

        ---@type GameObject[]
        local items = types.Player.inventory(self):getAll()

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

local function createMagicWindow(savedSpellsIDs)
        ---@type Spell[]
        PlayerSpells = types.Player.spells(self) or {}

        bookmarkedLookup = {}
        for _, id in ipairs(savedSpellsIDs) do
                bookmarkedLookup[id] = true
        end

        local savedSpellsList = g.scrollableList.create(listsKeys.savedSpells, getSavedSpellsEls(), {
                filterFunction = filterSpell,
                sortCallback = savedSortCallback,
        })
        local allSpellsList = g.scrollableList.create(listsKeys.allSpells, getAllSpellsEls(), {
                filterFunction = filterSpell,
                sortCallback = allSpellsSortCallback,
        })
        local scrollsList = g.scrollableList.create(listsKeys.scrolls, getMagicScrollsEls(), {
                filterFunction = filterName,
                sortCallback = scrollsSortCallback,
        })
        local equipmentList = g.scrollableList.create(listsKeys.equipment, getEquipmentEls(), {
                filterFunction = filterName,
                sortCallback = equipmentSortCallback
        })


        local tabs = {
                {
                        name = 'Saved Spells',
                        icon = textures.bookmarksTab,
                        getContent = savedSpellsList.createLayout,
                },
                {
                        name = 'Add/Remove',
                        icon = textures.addOrRemoveTab,
                        getContent = allSpellsList.createLayout,
                },
                {
                        name = 'Scrolls',
                        icon = textures.scroll,
                        getContent = scrollsList.createLayout,
                },
                {
                        name = 'Equipment',
                        icon = textures.enchItem,
                        getContent = equipmentList.createLayout,
                },
        }


        local window = g.window.createResizableWindow({
                title = 'Magic Window',
                tabs = tabs,
                defaultTab = tabs[1].name,
        })

        return window
end

local activeWindows
function ShowWindow()
        if not MainWindow.layout then
                MainWindow = createMagicWindow(savedSpellsIDs)
                activeWindows = {}
                for _, window in pairs(I.UI.getWindowsForMode(I.UI.MODE.Interface)) do
                        if I.UI.isWindowVisible and I.UI.isWindowVisible(window) then
                                table.insert(activeWindows, window)
                        end
                end


                I.UI.setMode('Interface')
        else
                HideWindow()
        end
end

function HideWindow()
        if MainWindow.layout then
                MainWindow:destroy()
                I.UI.removeMode('Interface')
        end

        if toolTip.element.layout then
                toolTip.element:destroy()
        end
end

input.registerTriggerHandler(o.showMagicWindow.key, async:callback(ShowWindow))

local function onFrame()
        if not MainWindow.layout then return end


        for _, v in pairs(g.scrollableList.all) do
                v.onFrame()
        end

        for _ = 1, #g.myDelayedActions do
                table.remove(g.myDelayedActions):update()
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


        g.window.setWindowProps(data.props)
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

        return { savedSpellsIDs = savedSpellsIDs, props = props }
end


local function onUiModeChanged(data)
        if o.showWindowOnInterface.value then
                if data.newMode == 'Interface' then
                        if I.UI.isWindowVisible then
                                if I.UI.isWindowVisible(I.UI.WINDOW.Inventory) then
                                        if not MainWindow.layout then
                                                MainWindow = createMagicWindow(savedSpellsIDs)
                                        end
                                end
                        else
                                if not MainWindow.layout then
                                        MainWindow = createMagicWindow(savedSpellsIDs)
                                end
                        end
                else
                        if MainWindow.layout then
                                MainWindow:destroy()
                        end
                end
        end

        if toolTip.element.layout then
                toolTip.element:destroy()
        end
end


local scrollDir
return {
        engineHandlers = {
                onSave = onSave,
                onLoad = onLoad,
                onFrame = onFrame,
                onMouseWheel = function(v, h)
                        if not MainWindow.layout then return end
                        scrollDir = o.scrollDirection.value == 'Reversed' and 1 or -1
                        for _, list in pairs(g.scrollableList.all) do
                                if list.onMouseWheel(v * scrollDir) then
                                        list.element:update()
                                end
                        end
                end
        },
        eventHandlers = {
                UiModeChanged = onUiModeChanged
        },
}
