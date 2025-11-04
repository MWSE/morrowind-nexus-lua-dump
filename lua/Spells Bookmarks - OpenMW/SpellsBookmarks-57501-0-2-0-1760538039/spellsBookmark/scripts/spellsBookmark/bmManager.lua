local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local async = require('openmw.async')
local types = require('openmw.types')
local ambient = require('openmw.ambient')
local core = require('openmw.core')
local self = require('openmw.self')

local constants = require('scripts.omw.mwui.constants')
local input = require('openmw.input')
local makeInt = require('scripts.spellsBookmark.lib.myGUI').makeInt
local setDebugText = require('scripts.spellsBookmark.lib.myUtils').setDebugText

local createListView = require('scripts.spellsBookmark.lib.scrollView').createListView
local generalScroll = require('scripts.spellsBookmark.lib.scrollView').generalScroll
local lerp = require('scripts.spellsBookmark.lib.myUtils').lerp
local throt = require('scripts.spellsBookmark.lib.myUtils').throt
local createResizableWindow = require('scripts.spellsBookmark.window').createResizableWindow
local getWindowProps = require('scripts.spellsBookmark.window').getWindowProps
local setWindowProps = require('scripts.spellsBookmark.window').setWindowProps

local toolTip = require('scripts.spellsBookmark.lib.toolTip').toolTip
local colors = require('scripts.spellsBookmark.lib.myConstants').colors
local mouse = require('scripts.spellsBookmark.lib.myUtils').mouse
local filter = require('scripts.spellsBookmark.filter').filter



local o = require('scripts.spellsBookmark.settings').o
local getSectionKey = require('scripts.spellsBookmark.settings').getSectionKey
local storage = require('openmw.storage')
local mySection = storage.playerSection(getSectionKey())

local function getSettings(sectionKey, key)
        -- print('key = ', key)
        -- print('mySection = ', mySection:get(key))
        -- print('o key = ', o[key])
        -- print('o value = ', o[key].value)
        o[key].value = mySection:get(key)
end

mySection:subscribe(async:callback(getSettings))

o.showWindowOnInterface.value = mySection:get(o.showWindowOnInterface.key)



local tFuncs = {
        arrowScroll = {
                set = nil,
                till = nil
        },
        waitBeforeDestroy = {
                set = nil,
                til = nil
        }
}


---@type string[] List of spells ids
local savedSpellsIDs = {}

local bookmarkedLookup

local filteredList = {}
local lastSelected
local Res = ui.screenSize()
-- local Reshw = Res.x / 2
-- local Reshh = Res.y / 2

local ENTRY_HEIGHT = 14
local LERP_VALUE = 0.00001



---@class UIState
local UIState = {
        ---@class ListState
        allSpells = {
                focus = false,
                ---@type ui.Layout
                expandable = nil,
                expSize = 0,
                expTargetSize = 0,
                maxSize = 0,
                ---@type ui.Layout[]
                items = {},
                arrow = { up = { focus = false, press = false }, down = { focus = false, press = false } }
        },
        ---@class ListState
        bookmarks = {
                focus = false,
                ---@type ui.Layout
                expandable = nil,
                expSize = 0,
                expTargetSize = 0,
                maxSize = 0,
                ---@type ui.Layout[]
                items = {},
                arrow = { up = { focus = false, press = false }, down = { focus = false, press = false } }
        },
        ---@class ListState
        currentLayout = nil,
        ---@type ui.Element|{}
        mainWindow = {},
}

---@param color Color
---@return Color
local function getHoverColor(color)
        local r = math.min(255, color.r * 1.5)
        local g = math.min(255, color.g * 1.5)
        local b = math.min(255, color.b * 1.5)
        return util.color.rgb(r, g, b)
end

local currColor
---@param spell Spell
---@return ui.Layout
local function getQuickEl(spell)
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


        local el = {
                template = I.MWUI.templates.textNormal,
                props = {
                        text = spell.name,
                        textColor = currColor,
                        originalColor = currColor,
                        textSize = ENTRY_HEIGHT,
                        spell = spell
                },
                events = {
                        mousePress = async:callback(function(e, l)
                                toolTip.hideToolTip()
                                if e.button ~= 1 then return end

                                local currMagicka = types.Player.stats.dynamic.magicka(self).current

                                if lastSelected then
                                        if lastSelected.props.spell.cost > currMagicka then
                                                lastSelected.props.textColor = colors.cannot
                                                lastSelected.props.originalColor = colors.cannot
                                        else
                                                lastSelected.props.textColor = colors.normal
                                                lastSelected.props.originalColor = colors.normal
                                        end
                                end

                                types.Player.setSelectedSpell(self, spell.id)

                                if l.props.spell.cost > currMagicka then
                                        l.props.textColor = colors.selectedButCannot
                                        l.props.originalColor = colors.selectedButCannot
                                else
                                        l.props.textColor = colors.selected
                                        l.props.originalColor = colors.selected
                                end


                                lastSelected = l

                                ambient.playSound('menu click')

                                UIState.mainWindow:update()
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

                                RequiresUpdate = true
                        end),

                        focusGain = async:callback(function(_, l)
                                if not toolTip.element.layout then return end
                                l.props.textColor = getHoverColor(l.props.textColor)
                                UIState.bookmarks.focus = true
                                UIState.mainWindow:update()
                        end),
                }
        }

        if currColor == colors.selected or currColor == colors.selectedButCannot then
                lastSelected = el
        end

        return el
end



---@param spell Spell
---@param isSaved boolean
---@return ui.Layout
local function getAllSpellsEl(spell, isSaved)
        local el
        el = {
                template = I.MWUI.templates.textNormal,
                props = {
                        text = spell.name,
                        textColor = (isSaved and colors.saved) or colors.normal,
                        originalColor = (isSaved and colors.saved) or colors.normal,
                        saved = isSaved,
                        textSize = ENTRY_HEIGHT,
                        spell = spell,
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


                                table.sort(UIState.allSpells.items, function(a, b)
                                        if a.props.isExpandable then return true end
                                        if b.props.isExpandable then return false end
                                        if a.props.saved ~= b.props.saved then
                                                return a.props.saved
                                        else
                                                return a.props.text < b.props.text
                                        end
                                end)


                                filteredList = {}
                                for i = 2, #UIState.allSpells.items do
                                        local el = UIState.allSpells.items[i]
                                        if filter.filterSpell(el.props.spell) then
                                                table.insert(filteredList, el)
                                        end
                                end
                                table.insert(filteredList, 1, UIState.allSpells.expandable)

                                UIState.mainWindow.layout.content.mainFlex.content.mainContent.content.list.content = ui
                                    .content(
                                            filteredList)

                                UIState.mainWindow:update()
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

                                RequiresUpdate = true
                        end),

                        focusGain = async:callback(function(_, l)
                                if not toolTip.element.layout then return end
                                l.props.textColor = getHoverColor(l.props.textColor)

                                UIState.allSpells.focus = true
                                UIState.mainWindow:update()
                        end),
                }
        }

        return el
end

local function getQuickSpellsContent()
        UIState.currentLayout = UIState.bookmarks

        UIState.bookmarks.items = {}

        for _, spell in pairs(PlayerSpells) do
                if bookmarkedLookup[spell.id] then
                        table.insert(UIState.bookmarks.items, getQuickEl(spell))
                end
        end

        table.sort(UIState.bookmarks.items, function(a, b)
                if a.props.isExpandable then return true end
                if b.props.isExpandable then return false end

                return a.props.text < b.props.text
        end)

        UIState.bookmarks.maxSize = -(#UIState.bookmarks.items - 1) * ENTRY_HEIGHT

        local bookmarksListView = createListView(UIState.bookmarks, UIState)

        return bookmarksListView
end

local function getManagerContent()
        UIState.currentLayout = UIState.allSpells
        UIState.allSpells.items = {}
        filter.setFilterText('')



        for _, spell in pairs(PlayerSpells) do
                if spell.type == core.magic.SPELL_TYPE.Spell or spell.type == core.magic.SPELL_TYPE.Power then
                        if bookmarkedLookup[spell.id] then
                                table.insert(UIState.allSpells.items,
                                        getAllSpellsEl(spell, true))
                        else
                                table.insert(UIState.allSpells.items,
                                        getAllSpellsEl(spell, false))
                        end
                end
        end

        table.sort(UIState.allSpells.items, function(a, b)
                if a.props.isExpandable then return true end
                if b.props.isExpandable then return false end

                if a.props.saved ~= b.props.saved then
                        return a.props.saved
                else
                        return a.props.text < b.props.text
                end
        end)

        UIState.allSpells.maxSize = -(#UIState.allSpells.items - 1) * ENTRY_HEIGHT

        local allSpellsListView = createListView(UIState.allSpells, UIState)

        return allSpellsListView
end

local function createMagicWindow(savedSpellsIDs)
        UIState.allSpells.focus = false
        UIState.bookmarks.focus = false
        UIState.allSpells.expSize = 0
        UIState.bookmarks.expSize = 0
        UIState.allSpells.expTargetSize = 0
        UIState.bookmarks.expTargetSize = 0
        UIState.filterText = ''

        ---@type Spell[]
        PlayerSpells = types.Player.spells(self) or {}

        bookmarkedLookup = {}
        for _, id in ipairs(savedSpellsIDs) do
                bookmarkedLookup[id] = true
        end

        local window = createResizableWindow({
                title = 'Magic Window',
                tabs = {
                        {
                                name = 'Saved Spells',
                                getContent = getQuickSpellsContent,
                        },
                        {
                                name = 'Add/Remove',
                                getContent = getManagerContent,
                        },
                }
        })

        return window
end




local arrows = {
        { UIState.allSpells.arrow.up,   function() generalScroll(-1, UIState.allSpells) end },
        { UIState.allSpells.arrow.down, function() generalScroll(1, UIState.allSpells) end },
        { UIState.bookmarks.arrow.up,   function() generalScroll(-1, UIState.bookmarks) end },
        { UIState.bookmarks.arrow.down, function() generalScroll(1, UIState.bookmarks) end }
}

local debugText = ''

local EPSILON = 0.5

-- -@type Spell
-- for i, spell in pairs(core.magic.spells.records) do
--         -- if spell.type == core.magic.SPELL_TYPE.Spell and #spell.effects == 1 then
--         for i, v in pairs(spell.effects) do
--                 -- if v.affectedAttribute or v.affectedSkill then
--                 --         local search = v.affectedAttribute or v.affectedSkill
--                 --         if not myspells[search] then
--                 --                 myspells[search] = true
--                 --                 print(search)
--                 --         end
--                 --         -- print(v.affectedAttribute, v.affectedSkill)
--                 --         goto continue
--                 -- end
--         end
--         ::continue::
--         -- end
-- end


---Delayed Action error fix
RequiresUpdate = false

local expTargetSize
local function onFrame()
        -- debugText = 'getMode:' .. (I.UI.getMode() or '-') ..
        --     '\nmodes:' .. (#I.UI.modes or '-')
        -- for i, v in pairs(I.UI.WINDOW) do
        --         -- print(i, v)
        --         if I.UI.isWindowVisible(v) then
        --                 debugText = debugText .. '\n' .. v
        --         end
        -- end
        -- setDebugText(debugText)

        if not UIState.mainWindow.layout then return end

        toolTip.update()

        expTargetSize = UIState.currentLayout.expTargetSize
        if expTargetSize > UIState.currentLayout.expSize + EPSILON or expTargetSize < UIState.currentLayout.expSize - EPSILON then
                UIState.currentLayout.expSize = lerp(UIState.currentLayout.expSize, expTargetSize, LERP_VALUE)
                UIState.currentLayout.expandable.props.size = util.vector2(0, UIState.currentLayout.expSize)
                UIState.mainWindow:update()
        end

        for _, arrow in ipairs(arrows) do
                if arrow[1].focus and arrow[1].press then
                        throt(tFuncs.arrowScroll, 0.02, arrow[2])
                end
        end


        if RequiresUpdate then
                RequiresUpdate = false
                UIState.mainWindow:update()
        end

        -- setDebugText(types.Player.stats.dynamic.magicka(self).modifier .. ' : ' ..
        --         types.Player.stats.dynamic.magicka(self).current)
end



-- NewUIMode = nil
local function onUiModeChanged(data)
        -- print(data.arg)
        -- NewUIMode = data.oldMode



        if o.showWindowOnInterface.value then
                if data.newMode == 'Interface' then
                        if I.UI.isWindowVisible then
                                if I.UI.isWindowVisible(I.UI.WINDOW.Inventory) then
                                        if not UIState.mainWindow.layout then
                                                UIState.mainWindow = createMagicWindow(savedSpellsIDs)
                                        end
                                end
                        else
                                if not UIState.mainWindow.layout then
                                        UIState.mainWindow = createMagicWindow(savedSpellsIDs)
                                end
                        end
                else
                        if UIState.mainWindow.layout then
                                UIState.mainWindow:destroy()
                        end
                end
        end

        if toolTip.element.layout then
                toolTip.element:destroy()
        end
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


        setWindowProps(data.props)
end

local function onSave()
        local p = getWindowProps()
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



function HideWindow()
        if UIState.mainWindow.layout then
                UIState.mainWindow:destroy()
                I.UI.removeMode('Interface')
        end

        if toolTip.element.layout then
                toolTip.element:destroy()
        end
end

local activeWindows
function ShowWindow()
        if not UIState.mainWindow.layout then
                UIState.mainWindow = createMagicWindow(savedSpellsIDs)
                activeWindows = {}
                for _, window in pairs(I.UI.getWindowsForMode(I.UI.MODE.Interface)) do
                        if I.UI.isWindowVisible and I.UI.isWindowVisible(window) then
                                table.insert(activeWindows, window)
                        end
                end

                I.UI.addMode('Interface', { windows = activeWindows })
        else
                HideWindow()
        end
end

input.registerTriggerHandler(o.showMagicWindow.key, async:callback(ShowWindow))

return {
        engineHandlers = {
                onLoad = onLoad,
                onSave = onSave,
                onFrame = onFrame,
                onMouseWheel = function(v, h)
                        if UIState.mainWindow.layout then
                                if v == -1 then
                                        generalScroll(-1, UIState.currentLayout)
                                elseif v == 1 then
                                        generalScroll(1, UIState.currentLayout)
                                end
                        end
                end
        },
        eventHandlers = {
                UiModeChanged = onUiModeChanged
        },
        UIState = UIState,
}
