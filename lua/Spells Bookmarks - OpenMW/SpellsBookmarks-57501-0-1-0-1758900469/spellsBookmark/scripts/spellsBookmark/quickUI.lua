local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local async = require('openmw.async')
local types = require('openmw.types')
local self = require('openmw.self')
local ambient = require('openmw.ambient')
local auxUi = require('openmw_aux.ui')
local constants = require('scripts.omw.mwui.constants')
local bookmarkedSpellIds = require('scripts.spellsBookmark.quickUI_data').bookmarkedSpellIds

Res = ui.screenSize()

---@class lists
local allSpells = {
        focus = false,
        expandable = nil,
        expSize = 0,
        expTargetSize = 0,
        maxSize = 0,
        items = nil,
        arrow = {
                up = {

                        focus = false,
                        press = false,
                },
                down = {

                        focus = false,
                        press = false,
                }
        }
}
---@class lists
local bookmarks = {
        focus = false,
        expandable = nil,
        expSize = 0,
        expTargetSize = 0,
        maxSize = 0,
        items = nil,
        arrow = {
                up = {

                        focus = false,
                        press = false,
                },
                down = {

                        focus = false,
                        press = false,
                }
        }
}

local function resetExpSizes()
        allSpells.expSize = 0
        allSpells.expTargetSize = 0
        bookmarks.expSize = 0
        bookmarks.expTargetSize = 0
end

-- local flexBg = auxUi.deepLayoutCopy(I.MWUI.templates.bordersThick)
-- flexBg.type = ui.TYPE.Flex
-- table.insert(flexBg.content, 1, {
--     type = ui.TYPE.Image,
--     props = {
--         resource = constants.whiteTexture,
--         color = util.color.rgb(0, 0, 0),
--         relativeSize = util.vector2(1, 1),
--         alpha = 0.7
--     },
-- })

local function makeInt(w, h, grow, strech)
        return {
                template = I.MWUI.templates.interval,
                props = { size = util.vector2(w, h) },
                external = { grow = grow or 0, stretch = strech or 0 }
        }
end

local function lerp(from, to, ratio)
        return from + (to - from) * ratio
end

local function snap(value, to)
        return math.floor(value / to) * to
end


local SCROLL_AMOUNT = 32
local colorNormal = I.MWUI.templates.textNormal.props.textColor
local colorClicked = util.color.rgb(222 / 255, 215 / 255, 156 / 255)

local filterText = ""

-- Bookmarks Spells List
local function createBookmarksList()
        local itemsEls = {}

        for _, v in ipairs(bookmarkedSpellIds) do
                local spell = PlayerSpells[v.id]

                if spell == nil then
                        goto continue
                end

                local spellName = {
                        type = ui.TYPE.Text,
                        props = {
                                text = spell.name,
                                textColor = colorNormal,
                        },
                        template = I.MWUI.templates.textNormal,
                        events = {
                                mousePress = async:callback(function(e)
                                        if e.button ~= 1 then return end
                                        types.Player.setSelectedSpell(self, spell)
                                        ambient.playSound('menu click')
                                end)
                        },
                }

                -- local spellCost = {
                --     type = ui.TYPE.Text,
                --     props = {
                --         text = string.format('%s', spell.cost),
                --         textColor = colorNormal,
                --         -- text = 'cost',
                --     },
                --     template = I.MWUI.templates.textNormal,
                --     external = { grow = 1, stretch = 1 },
                -- }
                -- local grow = {
                --     template = I.MWUI.templates.interval,
                --     external = { grow = 1 },
                -- }
                -- local spellEffects = {
                --     type = ui.TYPE.Text,
                --     props = {
                --         text = spell.effects[1].id,
                --         textColor = colorNormal,
                --     },
                --     template = I.MWUI.templates.textNormal,
                -- }
                -- local spellEntry = {
                --     -- type = ui.TYPE.Flex,
                --     -- type = ui.TYPE.Image,
                --     template = flexBg,
                --     props = {
                --         size = util.vector2(300, 40),
                --         horizontal = true,
                --         resource = constants.whiteTexture,
                --         color = util.color.rgb(1, 0, 0),

                --     },
                --     content = ui.content { spellName, grow, spellCost }
                -- }
                -- table.insert(itemsEls, spellEntry)

                table.insert(itemsEls, spellName)
                ::continue::
        end

        return {
                type = ui.TYPE.Flex,
                template = I.MWUI.templates.borders,
                external = { grow = 1, stretch = 0.9 },
                props = { horizontal = false, relativeSize = util.vector2(0, 0) },
                content = ui.content { table.unpack(itemsEls) },
        }
end

-- Bookmarks Window
local function createBookmarksWindow()
        Res = ui.screenSize()

        PlayerSpells = types.Player.spells(self) or {}

        local content = {
                type = ui.TYPE.Flex,
                external = { grow = 1, stretch = 1 },
                props = { relativeSize = util.vector2(1, 1), horizontal = false, arrange = ui.ALIGNMENT.Center },
                content = ui.content {
                        makeInt(0, 10),
                        {
                                type = ui.TYPE.Text,
                                template = I.MWUI.templates.textHeader,
                                props = { text = "Bookmarked Spells" },
                        },
                        makeInt(0, 10),
                        createBookmarksList(),
                        makeInt(0, 10),
                }
        }

        local mainWindow = {
                layer = "Windows",
                type = ui.TYPE.Image,
                template = I.MWUI.templates.borders,
                -- template = I.MWUI.templates.boxTransparentThick,
                props = {
                        relativePosition = util.vector2(0.5, 0),
                        anchor = util.vector2(0.5, 0),
                        size = util.vector2(350, Res.y * 0.7),
                        resource = constants.whiteTexture,
                        color = util.color.rgb(0, 0, 0)
                },
                content = ui.content { content },
        }

        SpellWindows.quickSpells = ui.create(mainWindow)
end

-- Manager - All Spells Names
local function getSpellTextEl(spell)
        local item = {
                type = ui.TYPE.Text,
                props = { text = spell.name, textColor = colorNormal },
                template = I.MWUI.templates.textNormal,
                events = {
                        mousePress = async:callback(function(e)
                                if e.button ~= 1 then return end
                                if BookmarkedLookup[spell.id] then
                                        return
                                end
                                table.insert(bookmarkedSpellIds, { id = spell.id, spell = spell })
                                UpdateManagerWindow()
                        end)
                }
        }
        return item
end

--- #######################################
-- Manager - All Spells List
local function createAllSpellsList()
        allSpells.items = {}
        BookmarkedLookup = {}
        for _, v in ipairs(bookmarkedSpellIds) do
                BookmarkedLookup[v.id] = true
        end
        for _, spell in ipairs(PlayerSpells) do
                if spell.type == 0 and not BookmarkedLookup[spell.id] then
                        if filterText == "" or string.find(string.lower(spell.name), string.lower(filterText), 1, true) then
                                table.insert(allSpells.items, getSpellTextEl(spell))
                        end
                end
        end
end

-- Manager - Bookmarked Spells List
local function createCurrentBookmarksList()
        bookmarks.items = {}
        for i, v in ipairs(bookmarkedSpellIds) do
                if not PlayerSpells[v.id] then
                        goto continue
                end

                local spellEl = {
                        type = ui.TYPE.Text,
                        props = { text = "-" .. v.spell.name, textColor = colorClicked },
                        template = I.MWUI.templates.textNormal,
                        events = {
                                mousePress = async:callback(function(e)
                                        if e.button ~= 1 then return end
                                        table.remove(bookmarkedSpellIds, i)
                                        ambient.playSound('menu click')
                                        UpdateManagerWindow()
                                end)
                        }
                }

                table.insert(bookmarks.items, spellEl)

                ::continue::
        end
end
--- #######################################

local function createExpandable(size)
        local myInt = auxUi.deepLayoutCopy(I.MWUI.templates.interval)
        -- local myInt = auxUi.deepLayoutCopy(I.MWUI.templates.verticalLine)
        myInt.props.autoSize = false
        -- myInt.external =  { grow = 0, stretch = 0}
        myInt.props.size = util.vector2(100, size)
        -- myInt.props.size = util.vector2(100, 0)
        -- ui.updateAll()
        return myInt
end

---@param sign number
---@param whichWindow lists
local function generalScroll(sign, whichWindow)
        if (whichWindow.expTargetSize > whichWindow.maxSize) and sign > 0 then
                return
        end

        if (whichWindow.expTargetSize * -1 > whichWindow.maxSize) and sign < 0 then
                return
        end

        local newSize = whichWindow.expTargetSize + SCROLL_AMOUNT * sign

        whichWindow.expTargetSize = newSize
end


local function getScrollButtonsEvents(dir)
        return {
                mousePress = async:callback(function(e)
                        if e.button == 1 then
                                dir.press = true
                        end
                end),
                mouseRelease = async:callback(function(e)
                        dir.press = false
                end),
                focusGain = async:callback(function(e)
                        dir.focus = true
                end),
                focusLoss = async:callback(function(e)
                        dir.focus = false
                end)
        }
end

--- Manager - Lists
---@param whichWindow lists
local function createList(whichWindow)
        -- print('whichWindow.expSize = ', whichWindow.expSize)
        whichWindow.expandable = createExpandable(whichWindow.expSize)
        -- print('whichWindow.expandable.size = ', whichWindow.expandable.props.size)
        table.insert(whichWindow.items, whichWindow.expandable)
        -- table.insert(whichWindow.items, 1, whichWindow.expandable)

        local list = {
                type = ui.TYPE.Flex,
                template = I.MWUI.templates.borders,
                props = {
                        horizontal = false,
                        autoSize = false,
                        align = ui.ALIGNMENT.Center
                },
                external = { grow = 1, stretch = 0.9 },
                content = ui.content { table.unpack(whichWindow.items) },
                -- content = ui.content { table.unpack(visibleItems) },
                events = {
                        focusGain = async:callback(function()
                                whichWindow.focus = true
                        end),
                        focusLoss = async:callback(function()
                                whichWindow.focus = false
                        end)
                },
        }


        local scrollControls = {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
                external = { stretch = 0.9 },
                content = ui.content({
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = ui.texture { path = 'textures/omw_menu_scroll_up.dds' },
                                        size = util.vector2(20, 20),
                                },
                                events = getScrollButtonsEvents(whichWindow.arrow.up)
                        },
                        {
                                type = ui.TYPE.Image,
                                props = {
                                        resource = ui.texture { path = 'textures/omw_menu_scroll_down.dds' },
                                        size = util.vector2(20, 20),
                                },
                                events = getScrollButtonsEvents(whichWindow.arrow.down)


                        },
                })
        }


        return {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                props = { arrange = ui.ALIGNMENT.Center },
                external = { grow = 1, stretch = 1 },
                content = ui.content {
                        list,
                        makeInt(0, 10),
                        scrollControls,
                }
        }
end


-- Manager - Window
local function createBookmarkManagerWindowLayout()
        createAllSpellsList()
        createCurrentBookmarksList()

        allSpells.maxSize = (#allSpells.items / 2) * 32
        bookmarks.maxSize = (#bookmarks.items / 2) * 32

        local filterInput = {
                name = "filterInput",
                template = I.MWUI.templates.textEditLine,
                props = { text = filterText },
                events = {
                        textChanged = async:callback(function(newText)
                                -- allSpells.expSize = 0
                                -- allSpells.expandable.props.size = util.vector2(0, 0)
                                -- SpellWindows.bmManager:update()
                                -- SpellWindows.quickSpells:update()
                                -- ui.updateAll()

                                filterText = newText
                                allSpells.expTargetSize = 0
                                UpdateManagerWindow()
                        end)
                }
        }

        local filterBlock = {
                type = ui.TYPE.Flex,
                -- template = I.MWUI.templates.borders,
                external = { grow = 0, stretch = 0.9 },
                props = {
                        arrange = ui.ALIGNMENT.Center,
                        align = ui.ALIGNMENT.Start,
                        horizontal = true,
                        size = util.vector2(100, 0)
                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = 'Filter: ',

                                }
                        },
                        {
                                template = I.MWUI.templates.box,
                                content = ui.content { filterInput }
                        },
                }

        }

        local stuff = {
                -- Left Column: All Player Spells
                {
                        -- name = 'SpellsEl',
                        -- template = I.MWUI.templates.borders,
                        type = ui.TYPE.Flex,
                        props = { horizontal = false, arrange = ui.ALIGNMENT.Center },
                        external = { grow = 0.7, stretch = 1 },
                        content = ui.content {
                                makeInt(0, 10),
                                {
                                        type = ui.TYPE.Text,
                                        props = { text = "Player Spells" },
                                        template = I.MWUI.templates.textHeader
                                },
                                makeInt(0, 10),
                                filterBlock,
                                makeInt(0, 10),
                                createList(allSpells),
                                makeInt(0, 10),

                        }
                },

                -- Right Column: Bookmarked Spells
                {
                        type = ui.TYPE.Flex,
                        props = { horizontal = false, arrange = ui.ALIGNMENT.Center },
                        external = { grow = 1, stretch = 1 },
                        -- props = { horizontal = false },
                        content = ui.content {
                                makeInt(0, 10),
                                {
                                        type = ui.TYPE.Text,
                                        props = { text = "Bookmarked" },
                                        template = I.MWUI.templates.textHeader
                                },
                                makeInt(0, 40),
                                createList(bookmarks),
                                makeInt(0, 10),
                        }
                }

        }

        return {
                layer = "Windows",
                type = ui.TYPE.Image,
                -- type = ui.TYPE.Flex,
                template = I.MWUI.templates.borders,
                props = {
                        horizontal = true,
                        size = util.vector2(math.min(Res.x, 700), 390),
                        relativePosition = util.vector2(0.5, 0.05),
                        anchor = util.vector2(0.5, 0),
                        resource = constants.whiteTexture,
                        color = util.color.rgb(0, 0, 0)
                },
                -- external = { grow = 1, stretch = 1 },
                content = ui.content {
                        {
                                type = ui.TYPE.Flex,
                                -- template = I.MWUI.templates.borders,
                                props = { horizontal = true, relativeSize = util.vector2(1, 1) },
                                content = ui.content { table.unpack(stuff) }
                        }

                },
        }
end

local function createBookmarkManagerWindow()
        allSpells.focus = false
        bookmarks.focus = false
        resetExpSizes()

        filterText = ''
        PlayerSpells = types.Player.spells(self) or {}

        local layout = createBookmarkManagerWindowLayout()
        SpellWindows.bmManager = ui.create(layout)
end

function UpdateManagerWindow()
        SpellWindows.bmManager.layout = createBookmarkManagerWindowLayout()
        SpellWindows.bmManager:update()
end

local function scrollUp()
        if allSpells.focus then
                generalScroll(-1, allSpells)
        elseif bookmarks.focus then
                generalScroll(-1, bookmarks)
        end
end

local function scrollDown()
        if allSpells.focus then
                generalScroll(1, allSpells)
        elseif bookmarks.focus then
                generalScroll(1, bookmarks)
        end
end

local onFrame = function()
        if not SpellWindows.bmManager then return end

        if allSpells.expTargetSize ~= allSpells.expSize then
                allSpells.expSize = lerp(allSpells.expSize, allSpells.expTargetSize, 0.3)
                allSpells.expandable.props.size = util.vector2(0, allSpells.expSize)
                SpellWindows.bmManager:update()
        end

        if bookmarks.expTargetSize ~= bookmarks.expSize then
                bookmarks.expSize = lerp(bookmarks.expSize, bookmarks.expTargetSize, 0.3)
                bookmarks.expandable.props.size = util.vector2(0, bookmarks.expSize)
                SpellWindows.bmManager:update()
        end



        if allSpells.arrow.up.focus and allSpells.arrow.up.press then
                generalScroll(-1, allSpells)
        elseif allSpells.arrow.down.focus and allSpells.arrow.down.press then
                generalScroll(1, allSpells)
        elseif bookmarks.arrow.up.focus and bookmarks.arrow.up.press then
                generalScroll(-1, bookmarks)
        elseif bookmarks.arrow.down.focus and bookmarks.arrow.down.press then
                generalScroll(1, bookmarks)
        end
end

return {
        createBookmarksWindow = createBookmarksWindow,
        createBookmarkManagerWindow = createBookmarkManagerWindow,
        scrollDown = scrollDown,
        scrollUp = scrollUp,
        onFrame = onFrame,
}
