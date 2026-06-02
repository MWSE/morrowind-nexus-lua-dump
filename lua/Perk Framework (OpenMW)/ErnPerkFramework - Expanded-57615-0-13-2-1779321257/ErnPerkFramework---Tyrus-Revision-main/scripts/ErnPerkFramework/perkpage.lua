--[[
ErnPerkFramework for OpenMW.
opyright (C) 2026 See AUTHORS.txt

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local interfaces = require("openmw.interfaces")
local storage = require('openmw.storage')
local pself = require("openmw.self")
local types = require("openmw.types")
local input = require("openmw.input")
local log = require("scripts.ErnPerkFramework.log")
local util = require('openmw.util')
local MOD_NAME = require("scripts.ErnPerkFramework.settings").MOD_NAME
local settings = require("scripts.ErnPerkFramework.settings")
local ui = require('openmw.ui')
local aux_util = require('openmw_aux.util')
local myui = require('scripts.ErnPerkFramework.pcp.myui')
local list = require('scripts.ErnPerkFramework.list')
local core = require("openmw.core")
local localization = core.l10n(MOD_NAME)

local DEBOUNCE_FRAMES = 5
local TAB_BAR_WIDTH = 700
local TAB_BUTTON_WIDTH = 90
local TAB_NAV_BUTTON_WIDTH = 28
local TAB_GAP = 4
local MAX_VISIBLE_TABS = 6

-- ============================================================
--  OBTAINED PERK COLOUR
--
--  Perks the player already has are shown in a muted light green
--  rather than grey, making it immediately obvious which perks
--  are owned vs locked.  Group headers and tabs where every perk
--  is already obtained are tinted the same colour.
--
--  These are literal colour values rather than myui named keys;
--  createObtainedButton() handles the three interaction states
--  (default, over, pressed) using slight brightness variations.
-- ============================================================

local COLOUR_OBTAINED         = util.color.rgb(0.45, 0.75, 0.45)  -- resting green
local COLOUR_OBTAINED_OVER    = util.color.rgb(0.60, 0.90, 0.60)  -- lighter on hover
local COLOUR_OBTAINED_PRESSED = util.color.rgb(0.35, 0.60, 0.35)  -- darker on click

-- Creates a borderless text button using the obtained (green) colour set.
-- Mirrors myui.createTextButtonBorderless but accepts literal colour values
-- instead of a named key, so it works without modifying myui.lua.
local function createObtainedButton(parent, label, name, buttonFunction, args)
    local overlayResource = ui.texture { path = 'icons/default icon.dds', size = util.vector2(0, 0) }
    local buttonLayout = {
        name = name,
        type = ui.TYPE.Container,
        props = {},
        userData = {},
        content = ui.content {
            {
                name = 'vFlex',
                type = ui.TYPE.Flex,
                props = {},
                content = ui.content {
                    {
                        name = 'hFlex',
                        type = ui.TYPE.Flex,
                        props = { horizontal = true },
                        content = ui.content {
                            { name = 'padding', props = { size = util.vector2(8, 0) } },
                            {
                                name = 'text',
                                type = ui.TYPE.Text,
                                template = interfaces.MWUI.templates.textNormal,
                                props = {
                                    text = label,
                                    textColor = COLOUR_OBTAINED,
                                },
                            },
                            { name = 'padding', props = { size = util.vector2(8, 0) } },
                        },
                    },
                    { name = 'padding', props = { size = util.vector2(0, 1) } },
                },
            },
            {
                name = 'overlay',
                type = ui.TYPE.Image,
                props = { size = util.vector2(129, 17), alpha = 0, resource = overlayResource },
            },
        },
    }

    local async = require('openmw.async')
    local ambient = require('openmw.ambient')
    buttonLayout.events = {
        mousePress = async:callback(function(mouseEvent, data)
            if mouseEvent.button == 1 then
                data.content.vFlex.content.hFlex.content.text.props.textColor = COLOUR_OBTAINED_PRESSED
                ambient.playSound('Menu Click')
                parent:update()
            end
        end),
        mouseRelease = async:callback(function(mouseEvent, data)
            if mouseEvent.button == 1 then
                data.content.vFlex.content.hFlex.content.text.props.textColor = COLOUR_OBTAINED_OVER
                if buttonFunction then
                    buttonFunction(table.unpack(args or {}))
                end
                parent:update()
            end
        end),
        focusGain = async:callback(function(_, data)
            data.content.vFlex.content.hFlex.content.text.props.textColor = COLOUR_OBTAINED_OVER
            parent:update()
        end),
        focusLoss = async:callback(function(_, data)
            data.content.vFlex.content.hFlex.content.text.props.textColor = COLOUR_OBTAINED
            parent:update()
        end),
    }

    return buttonLayout
end

-- Maximum characters per description page before automatic pagination kicks in.
-- You can also force a page break at any point by inserting a form-feed
-- character (\f) directly in the localizedDescription string.
local DESCRIPTION_PAGE_SIZE = 520

-- A content list can contain both Elements and Layouts.
-- Elements are what you get when you call ui.create().
-- Elements are passed by reference, so you can update them without needing to
-- mess with parent layouts that use them.
--
-- https://openmw.readthedocs.io/en/stable/reference/lua-scripting/widgets/widget.html#properties
-- https://openmw.readthedocs.io/en/stable/reference/lua-scripting/openmw_ui.html##(Template)

local remainingPoints = 0

local menu = nil
local perkList = nil
local perkDetailElement = ui.create {
    name = "detailLayout",
    type = ui.TYPE.Flex,
}

local haveThisPerk = ui.create {
    template = interfaces.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    alignment = ui.ALIGNMENT.Center,
    props = {
        visible = false,
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
        text = localization("havePerk", {}),
    },
}

-- Remaining points display, sits just above the action buttons.
local remainingPointsElement = ui.create {
    template = interfaces.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
        textAlignH   = ui.ALIGNMENT.Center,
        textAlignV   = ui.ALIGNMENT.Center,
        -- relativeSize(1,0): inherit full width from parent so centering
        -- works correctly and the element doesn't push the flex out of shape.
        relativeSize = util.vector2(1, 0),
        text = "",
    },
}

-- Cost display for the currently selected perk, shown below the
-- remaining-points line and above the buttons.
local perkPointCostElement = ui.create {
    template = interfaces.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
        textAlignH   = ui.ALIGNMENT.Center,
        textAlignV   = ui.ALIGNMENT.Center,
        relativeSize = util.vector2(1, 0),
        text = "",
    },
}

-- ============================================================
--  CATEGORY / TAB STATE
--
--  activeTabType  - the currently selected top-level tab name,
--                   or the synthetic "All" value (TAB_ALL).
--  expandedGroups - set of group names currently expanded
--                   (map of groupName -> true). Multiple groups
--                   may be open at the same time.
--  TAB_ALL        - sentinel string for the "show everything"
--                   tab that is always appended to the right.
-- ============================================================

local TAB_ALL = "All"
local activeTabType  = TAB_ALL
local tabPageIndex = 1
-- expandedGroups is a set (map of groupName -> true) rather than a single
-- string, so multiple dropdowns can be open simultaneously.
local expandedGroups = {}

-- Cached tab names from the last redraw().
-- Used by onFrame() to support keyboard/controller tab navigation without
-- needing to rebuild the category tree every frame.
local cachedTabNames = {}

-- ============================================================
--  IMMEDIATE PICK TRACKING
--
--  justPickedPerks records perk IDs picked in the current
--  session before the addPerk event has been processed by the
--  player script. This gives instant visual feedback (grey out)
--  without waiting a frame for getPlayerPerks() to update.
--  Cleared at the start of every showPerkUI call.
-- ============================================================

local justPickedPerks = {}

-- ============================================================
--  DESCRIPTION PAGINATION STATE
--
--  descriptionPagesByPerkID  - cache of paginated page arrays, keyed by perk ID.
--                              Built lazily the first time a perk is viewed.
--  activeDescriptionPageByPerkID - the page number the player is currently
--                              viewing for each perk, keyed by perk ID.
--                              Persists for the duration of the UI session.
--
--  Pagination rules (see paginateDescription below):
--   1. If the description contains any \f (form-feed) characters, those are
--      treated as explicit page breaks and the string is split at those points.
--      This gives perk authors full control: one \f per effect creates one
--      effect-per-page.
--   2. Otherwise, the description is automatically paginated by character count
--      (DESCRIPTION_PAGE_SIZE), preferring to break at paragraph or word
--      boundaries.
-- ============================================================

local descriptionPagesByPerkID = {}
local activeDescriptionPageByPerkID = {}

-- ============================================================
--  CATEGORY HELPERS
--
--  buildCategoryTree() scans all registered perks once and
--  returns a tree:
--    tree[typeName][groupName] = { perkID, perkID, ... }
--  sorted by the per-perk sort order (category[3]).
--
--  getTabNames() returns an ordered list of top-level type
--  names, with TAB_ALL always first on the left, then the rest
--  in alphabetical order.
-- ============================================================

local function buildCategoryTree()
    local tree = {}
    for _, id in ipairs(interfaces.ErnPerkFramework.getPerkIDs()) do
        local perkObj = interfaces.ErnPerkFramework.getPerks()[id]
        local cat = perkObj:category()
        if cat then
            local typeName  = cat[1]
            local groupName = cat[2]
            if not tree[typeName] then tree[typeName] = {} end
            if not tree[typeName][groupName] then tree[typeName][groupName] = {} end
            table.insert(tree[typeName][groupName], id)
        end
    end
    -- Sort each group's perk list by sort order (category[3])
    for _, groups in pairs(tree) do
        for _, ids in pairs(groups) do
            table.sort(ids, function(a, b)
                local ca = interfaces.ErnPerkFramework.getPerks()[a]:category()
                local cb = interfaces.ErnPerkFramework.getPerks()[b]:category()
                return (ca and ca[3] or 0) < (cb and cb[3] or 0)
            end)
        end
    end
    return tree
end

local function getTabNames(tree)
    -- Type-specific tabs are sorted alphabetically and shown first (leftmost).
    -- TAB_ALL is always last (rightmost) so it reads as a catch-all fallback.
    local names = {}
    local sorted = {}
    for typeName, _ in pairs(tree) do
        table.insert(sorted, typeName)
    end
    table.sort(sorted)
    for _, n in ipairs(sorted) do
        table.insert(names, n)
    end
    table.insert(names, TAB_ALL)
    return names
end

local function clampTabPage(tabCount)
    local maxPage = math.max(1, tabCount - MAX_VISIBLE_TABS + 1)
    tabPageIndex = math.max(1, math.min(tabPageIndex, maxPage))
end

local function keepActiveTabVisible(tabNames)
    for i, tabName in ipairs(tabNames) do
        if tabName == activeTabType then
            if i < tabPageIndex then
                tabPageIndex = i
            elseif i > tabPageIndex + MAX_VISIBLE_TABS - 1 then
                tabPageIndex = i - MAX_VISIBLE_TABS + 1
            end
            break
        end
    end
    clampTabPage(#tabNames)
end

-- ============================================================
--  PERK LIST CONSTRUCTION
--
--  getPerkIDs() was replaced by buildListEntries().
--
--  When activeTabType == TAB_ALL:
--    Flat weighted+alphabetical list identical to original.
--
--  When a specific type tab is active:
--    Groups are shown as collapsible header rows. The expanded
--    group shows its perks in category sort order.
--    Perks already taken stay in place and are greyed out.
--
--  List entries are tables:
--    { kind = "perk",   id = perkID }
--    { kind = "header", group = groupName, expanded = bool }
-- ============================================================

local satisfiedCache = {}
local function satisfied(perkID)
    if type(perkID) ~= "string" then
        perkID = perkID:id()
    end
    if satisfiedCache[perkID] ~= nil then
        return satisfiedCache[perkID]
    else
        local ok = interfaces.ErnPerkFramework.getPerks()[perkID]:evaluateRequirements().satisfied
        satisfiedCache[perkID] = ok
        return ok
    end
end

-- visiblePerks is a map of perkid -> true, or nil (no filter).
local visiblePerks = nil

-- Flat list of entries displayed in the perk list panel.
-- Each entry is { kind="perk", id=... } or { kind="header", group=..., expanded=... }
local currentListEntries = {}

local function buildListEntries()
    local entries = {}
    local allPerks = interfaces.ErnPerkFramework.getPerks()

    local function isVisible(id)
        if visiblePerks ~= nil then
            return visiblePerks[id] ~= nil
        end
        local perkObj = allPerks[id]
        return perkObj:active() or (not perkObj:hidden())
    end

    if activeTabType == TAB_ALL then
        -- No category filtering: flat weighted+alphabetical list (original behaviour)
        local weightsCache = {}
        local function weight(id)
            if weightsCache[id] ~= nil then return weightsCache[id] end
            local perkObj = allPerks[id]
            local w
            if perkObj:active() or justPickedPerks[id] then
                w = 100
            elseif not satisfied(id) then
                w = 50
            elseif perkObj:cost() > remainingPoints then
                w = 25
            else
                w = 0
            end
            weightsCache[id] = w
            return w
        end

        local ids = {}
        for _, id in ipairs(interfaces.ErnPerkFramework.getPerkIDs()) do
            if isVisible(id) then
                table.insert(ids, id)
            end
        end
        table.sort(ids, function(a, b)
            local wa, wb = weight(a), weight(b)
            if wa ~= wb then return wa < wb end
            return allPerks[a]:name() < allPerks[b]:name()
        end)
        for _, id in ipairs(ids) do
            table.insert(entries, { kind = "perk", id = id })
        end
    else
        -- Category tab: header rows + perks inside expanded group
        local tree = buildCategoryTree()
        local groups = tree[activeTabType]
        if groups then
            local groupNames = {}
            for g, _ in pairs(groups) do table.insert(groupNames, g) end
            table.sort(groupNames)

            for _, groupName in ipairs(groupNames) do
                local expanded = expandedGroups[groupName] == true
                table.insert(entries, {
                    kind     = "header",
                    group    = groupName,
                    expanded = expanded,
                })
                if expanded then
                    for _, id in ipairs(groups[groupName]) do
                        if isVisible(id) then
                            -- indented = true flags this row for left-padding
                            -- in the renderer, visually nesting it under its header.
                            table.insert(entries, { kind = "perk", id = id, indented = true })
                        end
                    end
                end
            end
        end
    end

    currentListEntries = entries
    return entries
end

-- ============================================================
--  SELECTION HELPERS
-- ============================================================

local function getSelectedIndex()
    if perkList ~= nil then
        return perkList.selectedIndex
    end
    return 1
end

-- Returns the perk object for the currently selected list entry,
-- or nil if the selection is on a header row.
local function getSelectedPerk()
    local entry = currentListEntries[getSelectedIndex()]
    if not entry or entry.kind ~= "perk" then return nil end
    return interfaces.ErnPerkFramework.getPerks()[entry.id]
end

-- ============================================================
--  TEXT SANITIZATION
--
--  sanitizeText() strips control characters that are valid in Lua
--  string literals but cause MyGUI's text renderer to hard-crash.
--  It mirrors the same helper in perk.lua.
--
--  Applied to every page returned by paginateDescription() as a
--  final safety net, even though correct use of \f page-breaks
--  means no form-feed should reach a page string.
-- ============================================================

local function sanitizeText(text)
    if type(text) ~= "string" then
        text = tostring(text or "")
    end
    -- Strip form-feed characters (page-break sentinels).
    -- NOTE: string.gsub returns (result, count). The outer parentheses
    -- discard the count so callers always receive exactly one value.
    -- Without this, table.insert(pages, sanitizeText(x)) expands to
    -- table.insert(pages, str, count) which errors: "number expected".
    return (text:gsub("\f", ""))
end

-- ============================================================
--  DESCRIPTION PAGINATION
--
--  paginateDescription(text) -> list of page strings
--
--  Two modes:
--   a) Explicit \f breaks: if the description contains any \f characters,
--      those are the page boundaries.  This gives full authorial control —
--      e.g. put \f between each effect description for one effect per page.
--   b) Automatic: splits at the nearest paragraph or word boundary before
--      DESCRIPTION_PAGE_SIZE characters.
--
--  sanitizeText() is called on every page before it is returned, so even
--  if a \f somehow survives into a page string, it is stripped before it
--  can reach a MyGUI text widget and crash the game.
--
--  getDescriptionPages / getCurrentDescriptionPage retrieve the cached
--  pages and the player's current page index for a given perk.
-- ============================================================

local function paginateDescription(text)
    text = tostring(text or "")

    -- Mode (a): explicit \f page breaks
    -- If any form-feed characters exist, use them as the sole split points.
    if text:find("\f") then
        local pages = {}
        for page in (text .. "\f"):gmatch("(.-)\f") do
            local trimmed = page:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmed ~= "" then
                -- sanitizeText() is a last-resort safety net: each page
                -- should be clean after splitting on \f, but strip any
                -- that survived (e.g. the \n+spaces+\f pattern the author
                -- used in the hasTamrielData conditional block).
                table.insert(pages, sanitizeText(trimmed))
            end
        end
        if #pages > 0 then
            return pages
        end
        -- Fall through if every segment was whitespace-only
    end

    -- Mode (b): automatic pagination by character count.
    -- Strip any stray \f characters first so they don't reach a widget.
    text = sanitizeText(text)
    local pages = {}
    while #text > DESCRIPTION_PAGE_SIZE do
        local splitAt = DESCRIPTION_PAGE_SIZE
        -- Prefer splitting at a paragraph break (\n\n) within the window
        local paragraphBreak = text:sub(1, DESCRIPTION_PAGE_SIZE):match("^.*()\n\n")
        if paragraphBreak and paragraphBreak > 1 then
            splitAt = paragraphBreak
        else
            -- Fall back to nearest whitespace
            local whitespace = text:sub(1, DESCRIPTION_PAGE_SIZE):match("^.*()%s+")
            if whitespace and whitespace > DESCRIPTION_PAGE_SIZE * 0.6 then
                splitAt = whitespace
            end
        end

        -- gsub returns (result, count); parentheses discard the count so
        -- table.insert receives exactly one value, not two.
        table.insert(pages, (text:sub(1, splitAt):gsub("%s+$", "")))
        text = text:sub(splitAt + 1):gsub("^%s+", "")
    end

    table.insert(pages, text)
    return pages
end

local function getDescriptionPages(perk)
    local perkID = perk:id()
    if descriptionPagesByPerkID[perkID] == nil then
        descriptionPagesByPerkID[perkID] = paginateDescription(perk:description())
    end
    return descriptionPagesByPerkID[perkID]
end

local function getCurrentDescriptionPage(perk)
    local pages = getDescriptionPages(perk)
    local perkID = perk:id()
    local page = activeDescriptionPageByPerkID[perkID] or 1
    page = math.max(1, math.min(page, #pages))
    activeDescriptionPageByPerkID[perkID] = page
    return page, pages
end

-- Returns the text for the currently-visible description page of the
-- selected perk, with a "(page/total)" suffix appended only when
-- there are multiple pages.  Returns nil when nothing is selected.
local function selectedDescriptionText()
    local selectedPerk = getSelectedPerk()
    if selectedPerk == nil then return nil end
    local page, pages = getCurrentDescriptionPage(selectedPerk)
    local text = pages[page]
    if #pages > 1 then
        text = text .. "\n\n(" .. tostring(page) .. "/" .. tostring(#pages) .. ")"
    end
    return text
end

local function hasPerk(idx)
    local entry = currentListEntries[idx]
    if not entry or entry.kind ~= "perk" then return false end
    local testID = entry.id
    -- Check local "just picked" tracking first so the perk greys out
    -- immediately without waiting for the addPerk event to be processed.
    if justPickedPerks[testID] then return true end
    for _, foundID in ipairs(interfaces.ErnPerkFramework.getPlayerPerks()) do
        if foundID == testID then return true end
    end
    return false
end

-- perkAvailable returns true if the player does not have the perk
-- and meets all requirements and can afford it.
local function perkAvailable(perk)
    if perk == nil then
        log(nil, "perkAvailable(nil)")
        return false
    end
    local foundPerk = perk
    local perkId
    if type(perk) == "string" then
        perkId   = perk
        foundPerk = interfaces.ErnPerkFramework.getPerks()[perk]
    else
        perkId = perk:id()
    end
    -- A perk picked this session is not available again
    if justPickedPerks[perkId] then return false end
    return satisfied(foundPerk) and (not foundPerk:active()) and foundPerk:cost() <= remainingPoints
end

-- ============================================================
--  AVAILABILITY HELPERS
--
--  Defined here, after perkAvailable(), so they can call it.
--  Used to decide whether tabs and group headers should be
--  greyed out and non-interactive.
--
--  groupHasAvailablePerk(tree, typeName, groupName)
--    Returns true if at least one perk in the specific group
--    passes perkAvailable().
--
--  tabHasAvailablePerk(tree, typeName)
--    Returns true if any group in the tab has an available perk.
--    TAB_ALL always returns true (it never blocks navigation).
--
--  Both read satisfiedCache via perkAvailable(), so repeated
--  calls within the same redraw are cheap.
-- ============================================================

local function groupHasAvailablePerk(tree, typeName, groupName)
    local groups = tree[typeName]
    if not groups then return false end
    local ids = groups[groupName]
    if not ids then return false end
    for _, id in ipairs(ids) do
        if perkAvailable(id) then return true end
    end
    return false
end

local function tabHasAvailablePerk(tree, typeName)
    if typeName == TAB_ALL then return true end
    local groups = tree[typeName]
    if not groups then return false end
    for groupName, _ in pairs(groups) do
        if groupHasAvailablePerk(tree, typeName, groupName) then
            return true
        end
    end
    return false
end

-- ============================================================
--  OBTAINED STATE HELPERS
--
--  groupAllObtained / tabAllObtained return true when every
--  visible perk in the group / tab has already been picked.
--  Used to colour the header/tab green as a clear visual signal
--  that the player has completed that section.
-- ============================================================

-- Returns true if at least one visible perk in the group is obtained,
-- AND every visible perk in the group is obtained.
-- "Visible" means: either already active/obtained, or not hidden.
-- Hidden perks that are not yet obtained are excluded from the check,
-- but if ALL perks are hidden-and-unobtained the function returns false
-- (nothing obtained = not a completed group).
local function groupAllObtained(tree, typeName, groupName)
    local groups = tree[typeName]
    if not groups then return false end
    local ids = groups[groupName]
    if not ids or #ids == 0 then return false end

    local anyObtained = false
    for _, id in ipairs(ids) do
        local perkObj  = interfaces.ErnPerkFramework.getPerks()[id]
        local obtained = perkObj:active() or (justPickedPerks[id] == true)
        -- A perk is "visible" if it is obtained OR not hidden.
        -- Perks that are hidden AND unobtained are invisible and excluded.
        local visible  = obtained or (not perkObj:hidden())
        if visible then
            if obtained then
                anyObtained = true
            else
                -- At least one visible perk is not yet obtained
                return false
            end
        end
    end
    -- Only green if we actually found at least one obtained perk
    return anyObtained
end

-- Returns true if every group in the tab has all its visible perks obtained
-- AND at least one perk anywhere in the tab is obtained.
-- TAB_ALL is never considered "all obtained" — it spans everything.
local function tabAllObtained(tree, typeName)
    if typeName == TAB_ALL then return false end
    local groups = tree[typeName]
    if not groups then return false end
    local anyGroup = false
    for groupName, _ in pairs(groups) do
        if not groupAllObtained(tree, typeName, groupName) then
            return false
        end
        anyGroup = true
    end
    return anyGroup  -- false if there were no groups at all
end

-- ============================================================
--  TAB BAR UI
--
--  A horizontal row of text buttons, one per tab name.
--  The active tab is highlighted. Clicking a tab sets
--  A horizontal row of text buttons, one per tab name.
--  The active tab is highlighted. Tabs with no acquirable perks
--  are greyed and non-interactive. Clicking a live tab sets
--  activeTabType, collapses all expandedGroups, resets list
--  selection, and triggers a redraw via the internal event.
-- ============================================================

local tabBarElement = ui.create {
    type = ui.TYPE.Flex,
    props = { horizontal = true },
}

-- buildTabBar now takes the pre-built tree so it can check per-tab
-- availability without rebuilding it a second time.
local function buildTabBar(tabNames, tree)
    local content = ui.content {}

    keepActiveTabVisible(tabNames)

    local tabCount = #tabNames
    local hasOverflow = tabCount > MAX_VISIBLE_TABS

    local function addTabPageButton(label, enabled, delta)
        local btn = ui.create {}
        local color = enabled and 'normal' or 'disabled'
        local clickFn = function() end
        if enabled then
            clickFn = function()
                tabPageIndex = tabPageIndex + delta
                clampTabPage(tabCount)
                pself:sendEvent(MOD_NAME .. "_internalRedraw", {})
            end
        end
        btn.layout = myui.createTextButtonBorderless(
            btn,
            label,
            color,
            'tabPage_' .. label,
            {},
            util.vector2(TAB_NAV_BUTTON_WIDTH, 17),
            clickFn,
            {})
        btn:update()
        content:add(btn)
        content:add(myui.padWidget(TAB_GAP, 0))
    end

    if hasOverflow then
        addTabPageButton("<", tabPageIndex > 1, -1)
    end

    local firstTab = hasOverflow and tabPageIndex or 1
    local lastTab = hasOverflow and math.min(tabCount, firstTab + MAX_VISIBLE_TABS - 1) or tabCount

    for i = firstTab, lastTab do
        local tabName   = tabNames[i]
        local isActive  = (tabName == activeTabType)
        local hasAvail  = tabHasAvailablePerk(tree, tabName)
        local allDone   = tabAllObtained(tree, tabName)

        -- Colour priority:
        --   active   = currently selected tab
        --   obtained = all perks in this tab are already owned (green)
        --   normal   = selectable, has acquirable perks
        --   disabled = no acquirable perks right now
        local btn = ui.create {}
        local capturedTab = tabName
        local clickFn
        if hasAvail and not isActive then
            clickFn = function()
                activeTabType  = capturedTab
                expandedGroups = {}
                if perkList then perkList.selectedIndex = 1 end
                pself:sendEvent(MOD_NAME .. "_internalRedraw", {})
            end
        else
            clickFn = function() end
        end

        if allDone and not isActive then
            -- All perks obtained: use the green obtained button
            btn.layout = createObtainedButton(
                btn,
                capturedTab,
                'tab_' .. capturedTab,
                clickFn,
                {})
        else
            local color
            if isActive then
                color = 'active'
            elseif hasAvail then
                color = 'normal'
            else
                color = 'disabled'
            end
            btn.layout = myui.createTextButtonBorderless(
                btn,
                capturedTab,
                color,
                'tab_' .. capturedTab,
                {},
                util.vector2(TAB_BUTTON_WIDTH, 17),
                clickFn,
                {})
        end
        btn:update()
        content:add(btn)
        content:add(myui.padWidget(TAB_GAP, 0))
    end

    if hasOverflow then
        addTabPageButton(">", lastTab < tabCount, 1)
    end

    tabBarElement.layout = {
        type  = ui.TYPE.Flex,
        props = {
            horizontal   = true,
            relativeSize = util.vector2(1, 0),
            autoSize     = false,
            size         = util.vector2(TAB_BAR_WIDTH, 20),
        },
        content = content,
    }
    tabBarElement:update()
end

-- ============================================================
--  PERK LIST RENDERER
--
--  Each slot in the perkList is one entry from currentListEntries.
--  Header rows show a > / v toggle for the group name.
--  Perk rows show the perk name button, greyed if taken/locked.
-- ============================================================

local function viewPerk(perkID, idx)
    if type(idx) ~= "number" then
        error("idx must be a number")
    end
    local foundPerk = perkID
    if type(perkID) == "string" then
        if perkID == "" then
            error("viewPerk() supplied an empty perkID")
            return
        end
        foundPerk = interfaces.ErnPerkFramework.getPerks()[perkID]
    end
    if foundPerk == nil then
        error("bad perk: " .. tostring(perkID))
        return
    end

    -- Update the selected index so the list re-renders with the correct
    -- highlighted row, and so getSelectedPerk() returns the right perk.
    if perkList ~= nil then
        perkList.selectedIndex = idx
    end

    log(nil, "Showing detail for perk " .. foundPerk:name())

    -- Update the detail panel and "have this perk" notice directly — these
    -- are safe to call from inside a UI callback because they are separate
    -- elements not currently being rendered.
    perkDetailElement.layout = foundPerk:detailLayout(selectedDescriptionText())
    perkDetailElement:update()

    haveThisPerk.layout.props.visible = hasPerk(getSelectedIndex())
    haveThisPerk:update()

    -- Defer the list re-render and pick-button cost update to the next tick
    -- via _internalRedraw. Calling element:update() on elements that are
    -- part of the currently-firing button event causes re-entrancy issues
    -- in OpenMW's UI system (frozen input, disappearing widgets).
    pself:sendEvent(MOD_NAME .. "_internalRedraw", {})
end

-- Renders one row in the perkList.
-- tree is passed in from redraw() so we can call the availability helpers
-- without rebuilding it for every row.
local function renderListEntry(idx, isSelected, tree)
    local entry = currentListEntries[idx]
    if not entry then
        return ui.create { type = ui.TYPE.Widget, props = { size = util.vector2(0, 17) } }
    end

    if entry.kind == "header" then
        -- Group header row.
        -- Check whether this group has any acquirable perks, and whether
        -- all its perks are already obtained, for colour selection.
        local hasAvail   = groupHasAvailablePerk(tree, activeTabType, entry.group)
        local allDone    = groupAllObtained(tree, activeTabType, entry.group)
        local isExpanded = expandedGroups[entry.group] == true
        local arrow      = isExpanded and "v " or "> "
        local label      = arrow .. entry.group
        local capturedGroup = entry.group

        local clickFn
        if hasAvail or allDone then
            -- Allow expanding even when all perks are obtained, so the player
            -- can still view the perks they have.
            clickFn = function()
                if expandedGroups[capturedGroup] then
                    expandedGroups[capturedGroup] = nil
                else
                    expandedGroups[capturedGroup] = true
                end
                pself:sendEvent(MOD_NAME .. "_internalRedraw", {})
            end
        else
            clickFn = function() end
        end

        local btn = ui.create {}
        if isSelected then
            -- Keyboard/controller cursor is on this header: always use 'active'
            -- so the player can see where they are regardless of obtained state.
            btn.layout = myui.createTextButtonBorderless(
                btn, label, 'active',
                'header_' .. capturedGroup, {},
                util.vector2(129, 17), clickFn, {})
        elseif allDone then
            -- Every perk in this group is obtained: show in green
            btn.layout = createObtainedButton(
                btn,
                label,
                'header_' .. capturedGroup,
                clickFn,
                {})
        else
            local color = hasAvail and 'normal' or 'disabled'
            btn.layout = myui.createTextButtonBorderless(
                btn,
                label,
                color,
                'header_' .. capturedGroup,
                {},
                util.vector2(129, 17),
                clickFn,
                {})
        end
        btn:update()
        return btn
    else
        -- Perk row.
        -- Colour priority:
        --   active   = currently selected in the list
        --   obtained = player already has this perk (green)
        --   disabled = requirements not met (or not yet satisfiable)
        --   normal   = available to pick
        local perkObj    = interfaces.ErnPerkFramework.getPerks()[entry.id]
        local isObtained = hasPerk(idx)
        local capturedId  = entry.id
        local capturedIdx = idx
        local btn = ui.create {}

        if isSelected then
            -- Selected row always uses 'active' regardless of obtained state
            btn.layout = myui.createTextButtonBorderless(
                btn, perkObj:name(), 'active',
                'selectButton_' .. capturedId, {},
                util.vector2(129, 17), viewPerk, { capturedId, capturedIdx })
        elseif isObtained then
            -- Already obtained: green button, still clickable to view details
            btn.layout = createObtainedButton(
                btn, perkObj:name(),
                'selectButton_' .. capturedId,
                viewPerk, { capturedId, capturedIdx })
        else
            local color = (not satisfied(entry.id)) and 'disabled' or 'normal'
            btn.layout = myui.createTextButtonBorderless(
                btn, perkObj:name(), color,
                'selectButton_' .. capturedId, {},
                util.vector2(129, 17), viewPerk, { capturedId, capturedIdx })
        end
        btn:update()

        -- Indent perk rows that live inside an open dropdown group.
        -- We wrap the button in a horizontal Flex with a fixed left pad,
        -- giving a clear visual hierarchy without changing button widths.
        if entry.indented then
            local wrapper = ui.create {
                type  = ui.TYPE.Flex,
                props = { horizontal = true },
                content = ui.content {
                    myui.padWidget(16, 0),   -- 16px left indent
                    btn,
                },
            }
            wrapper:update()
            return wrapper
        end

        return btn
    end
end

-- ============================================================
--  PICK PERK
--
--  doPick() is a standalone function called from both the
--  pick button and the keyboard Enter / controller A handler.
--
--  After the perk is added we immediately record it in
--  justPickedPerks and call redraw() so the list greys out
--  the entry in the same frame, without waiting for the
--  addPerk player event to propagate.
-- ============================================================

local function doPick()
    local sp = getSelectedPerk()
    if sp == nil or not perkAvailable(sp) then return end

    local perkID = sp:id()
    log(nil, "Adding perk " .. perkID)

    -- Track locally so hasPerk() returns true immediately
    justPickedPerks[perkID] = true
    remainingPoints = remainingPoints - sp:cost()

    -- Send the actual add event (processed this frame, before next redraw)
    pself:sendEvent(MOD_NAME .. "addPerk", { perkID = perkID })

    -- Invalidate the satisfied cache so the list reflects new state
    satisfiedCache = {}

    if remainingPoints <= 0 then
        pself:sendEvent(MOD_NAME .. "closePerkUI")
    else
        -- Immediately rebuild and redraw so the acquired perk is greyed out
        -- without the player needing to click anything else first.
        pself:sendEvent(MOD_NAME .. "_internalRedraw", {})
    end
end

-- ============================================================
--  TAB NAVIGATION (keyboard / controller)
--
--  navigateTab(delta) moves the active tab by delta (+1 = right, -1 = left),
--  wrapping around at the ends.  It uses cachedTabNames so no tree rebuild
--  is needed per-frame.  Only tabs with available perks (or TAB_ALL) are
--  considered, matching the clickable-tab logic in buildTabBar.
-- ============================================================

-- navigateTab(delta, tree) moves the active tab by delta (+1 = right, -1 = left),
-- wrapping around at the ends.  tree is passed explicitly because cachedTree is
-- declared later in the file and would be nil if captured as an upvalue here.
-- Only tabs with available perks (or TAB_ALL) are reachable, matching the
-- clickable-tab logic in buildTabBar.
local function navigateTab(delta, tree)
    if #cachedTabNames == 0 then return end

    -- Find the index of the currently active tab
    local currentIdx = 1
    for i, name in ipairs(cachedTabNames) do
        if name == activeTabType then
            currentIdx = i
            break
        end
    end

    -- Walk in the requested direction, wrapping, skipping tabs that have
    -- no available perks (unless they are TAB_ALL, which is always reachable)
    local count = #cachedTabNames
    for _ = 1, count do
        currentIdx = ((currentIdx - 1 + delta) % count) + 1
        local candidate = cachedTabNames[currentIdx]
        if candidate == TAB_ALL or tabHasAvailablePerk(tree, candidate) then
            activeTabType  = candidate
            expandedGroups = {}
            if perkList then perkList.selectedIndex = 1 end
            pself:sendEvent(MOD_NAME .. "_internalRedraw", {})
            return
        end
    end
end

-- ============================================================
--  LIST NAVIGATION WITH SKIP
--
--  isEntryNavigable(idx) defines which list entries are valid
--  landing points for keyboard/controller navigation:
--    • Header rows: navigable if the group has acquirable perks
--      OR all its perks are already obtained (so the player can
--      still expand and view them).  Purely disabled/empty headers
--      are skipped.
--    • Perk rows: navigable if the perk is obtained OR its
--      requirements are satisfied.  Perks with unmet requirements
--      are skipped since there is nothing the player can do with
--      them right now.
--
--  navigateList(direction) moves the cursor by one step in the
--  given direction (+1 = down / higher index, -1 = up / lower
--  index), then keeps walking in that direction until a navigable
--  entry is found or the boundary is reached.  The cursor never
--  wraps around; it stops at index 1 or the total count.
-- ============================================================

local function isEntryNavigable(idx, tree)
    local entry = currentListEntries[idx]
    if not entry then return false end
    if entry.kind == "header" then
        -- Navigable if the group has acquirable perks or is fully obtained.
        -- tree is passed explicitly because cachedTree is declared after this
        -- function in the file; Lua locals are only visible from their
        -- declaration point onward, so capturing cachedTree as an upvalue
        -- here would always read nil.
        return groupHasAvailablePerk(tree, activeTabType, entry.group)
            or groupAllObtained(tree, activeTabType, entry.group)
    else
        -- Navigable if the perk is obtained or requirements are currently met
        return hasPerk(idx) or satisfied(entry.id)
    end
end

-- Moves the cursor in `direction` (+1 = down, -1 = up), skipping
-- entries that are not navigable.  Stops at the list boundary.
-- tree is the current category tree; passed in from the call site so
-- isEntryNavigable always receives a valid (non-nil) table.
local function navigateList(direction, tree)
    local total = #currentListEntries
    if total == 0 then return end

    local current   = perkList.selectedIndex
    local candidate = current + direction

    -- Walk until we find a navigable entry or go out of bounds
    for _ = 1, total do
        if candidate < 1 then
            candidate = 1
            break
        end
        if candidate > total then
            candidate = total
            break
        end
        if isEntryNavigable(candidate, tree) then
            break
        end
        candidate = candidate + direction
    end

    -- Clamp to valid range and apply
    candidate = math.max(1, math.min(total, candidate))
    perkList.selectedIndex = candidate
    -- Ensure the list scrolls so the selected entry is visible
    if perkList.selectedIndex < perkList.topIndex then
        perkList.topIndex = perkList.selectedIndex
    elseif perkList.selectedIndex > perkList.topIndex + perkList.displayCount - 1 then
        perkList.topIndex = perkList.selectedIndex - perkList.displayCount + 1
    end
end

local function toggleSelectedDropdown()
    local entry = currentListEntries[getSelectedIndex()]
    if not entry or entry.kind ~= "header" then return end
    if expandedGroups[entry.group] then
        expandedGroups[entry.group] = nil
    else
        expandedGroups[entry.group] = true
    end
    pself:sendEvent(MOD_NAME .. "_internalRedraw", {})
end

-- ============================================================
--  DESCRIPTION PAGE NAVIGATION
--
--  changeDescriptionPage(delta) advances or retreats the visible
--  page for the currently selected perk, clamped to [1, pageCount].
--  Called by the Prev/Next buttons, keyboard < > keys, and
--  controller shoulder buttons (LB / RB).
-- ============================================================

local function changeDescriptionPage(delta)
    local selectedPerk = getSelectedPerk()
    if selectedPerk == nil then return end
    local page, pages = getCurrentDescriptionPage(selectedPerk)
    activeDescriptionPageByPerkID[selectedPerk:id()] = math.max(1, math.min(page + delta, #pages))
    -- Only the detail panel changes; use the lightweight refresh to avoid
    -- the frame spike that full redraw() causes when changing pages.
    pself:sendEvent(MOD_NAME .. "_internalLightRedraw", {})
end

-- ============================================================
--  BUTTON ELEMENTS
--
--  All four action buttons live in a single permanent row in the
--  footer.  They are always present in the layout — their content
--  is never added or removed dynamically, which prevents OpenMW
--  from destroying the underlying Element objects and crashing.
--
--  Prev / Next    - description page navigation.  Rendered as
--                   'disabled' when the selected perk has only one
--                   page, or when already at the first/last page.
--  Acquire        - pick the selected perk ('disabled' when unavailable)
--  Exit           - close the UI
--
--  remainingPointsElement:  "X Perk Points Remaining"
--  perkPointCostElement:    "Cost: X" (blank when no perk selected)
--
--  All elements are refreshed together in updatePickButtonElement().
-- ============================================================

local pickButtonElement              = ui.create {}
local cancelButtonElement            = ui.create {}
local previousDescriptionButtonElement = ui.create {}
local nextDescriptionButtonElement     = ui.create {}

local function updatePickButtonElement()
    local selectedPerk = getSelectedPerk()

    -- ---- Acquire button ----
    local acquireColor = perkAvailable(selectedPerk) and 'normal' or 'disabled'
    pickButtonElement.layout = myui.createTextButton(
        pickButtonElement,
        "Acquire",
        acquireColor,
        'pickButton',
        {},
        util.vector2(129, 17),
        doPick)
    pickButtonElement:update()

    -- ---- Remaining points / cost lines ----
    local pts    = remainingPoints
    local plural = pts == 1 and "" or "s"
    remainingPointsElement.layout.props.text =
        tostring(pts) .. " Perk Point" .. plural .. " Remaining"
    remainingPointsElement:update()

    if selectedPerk ~= nil then
        perkPointCostElement.layout.props.text = "Cost: " .. tostring(selectedPerk:cost())
    else
        perkPointCostElement.layout.props.text = ""
    end
    perkPointCostElement:update()

    -- ---- Prev / Next page buttons ----
    -- These are ALWAYS in the layout (never removed) to prevent OpenMW from
    -- destroying the Element objects.  When the selected perk has only one
    -- page, both buttons are simply rendered in the 'disabled' colour.
    local page     = 1
    local pageCount = 1
    if selectedPerk ~= nil then
        local pages
        page, pages = getCurrentDescriptionPage(selectedPerk)
        pageCount = #pages
    end

    -- Prev: disabled when there is no previous page (page 1 or only 1 page)
    local prevColor = (pageCount > 1 and page > 1) and 'normal' or 'disabled'
    previousDescriptionButtonElement.layout = myui.createTextButton(
        previousDescriptionButtonElement,
        "Prev",
        prevColor,
        'previousDescriptionButton',
        {},
        util.vector2(68, 17),
        function() changeDescriptionPage(-1) end)
    previousDescriptionButtonElement:update()

    -- Next: disabled when there is no next page (last page or only 1 page)
    local nextColor = (pageCount > 1 and page < pageCount) and 'normal' or 'disabled'
    nextDescriptionButtonElement.layout = myui.createTextButton(
        nextDescriptionButtonElement,
        "Next",
        nextColor,
        'nextDescriptionButton',
        {},
        util.vector2(68, 17),
        function() changeDescriptionPage(1) end)
    nextDescriptionButtonElement:update()
end

cancelButtonElement.layout = myui.createTextButton(
    cancelButtonElement,
    "Exit",
    'normal',
    'cancelButton',
    {},
    util.vector2(129, 17),
    function() pself:sendEvent(MOD_NAME .. "closePerkUI", {}) end)
cancelButtonElement:update()

updatePickButtonElement()

-- ============================================================
--  PERK LIST WIDGET
-- ============================================================

-- cachedTree is set at the start of each redraw() so renderListEntry
-- can call the availability helpers without rebuilding the tree per row.
local cachedTree = {}

perkList = list.NewList(
    function(idx)
        if type(idx) ~= "number" then
            error("idx must be a number")
        end
        return renderListEntry(idx, idx == getSelectedIndex(), cachedTree)
    end
)

-- ============================================================
--  CLOSE UI
-- ============================================================

local function closeUI()
    if menu ~= nil then
        log(nil, "closing ui")
        menu:destroy()
        menu = nil

        perkList:destroy()

        perkDetailElement = ui.create {
            name = "detailLayout",
            type = ui.TYPE.Flex,
        }
        interfaces.UI.removeMode('Interface')
    end
end

-- ============================================================
--  LAYOUT
--
--  Structure (vertical outerFlex):
--    Tab bar row
--    mainFlex (horizontal):
--      [Left]  perkList
--      [Right] Vertical detail flex (arrange=Start):
--                perkDetailElement  (natural height, grows)
--                haveThisPerk
--                grow spacer        (pushes bottom section down)
--                remainingPointsElement   ("X Perk Points Remaining")
--                perkPointCostElement     ("Cost: X" or blank)
--                pad
--                buttons row (permanent): Prev | Next | Acquire | Exit
--                pad
--
--  Prev/Next are always in the layout — they are simply rendered in
--  the 'disabled' colour when the perk has only one description page.
--  Dynamically adding/removing Elements from a layout destroys them
--  in OpenMW's UI system, causing crashes on the next access.
-- ============================================================

local function menuLayout()
    return {
        layer = 'Windows',
        name  = 'menuContainer',
        type  = ui.TYPE.Container,
        template = interfaces.MWUI.templates.boxTransparentThick,
        props = {
            horizontal      = true,
            autoSize        = false,
            relativePosition = util.vector2(0.5, 0.5),
            anchor          = util.vector2(0.5, 0.5),
        },
        content = ui.content {
            {
                name     = 'padding',
                type     = ui.TYPE.Container,
                template = myui.padding(8, 8),
                content  = ui.content {
                    {
                        name  = 'outerFlex',
                        type  = ui.TYPE.Flex,
                        props = {
                            horizontal = false,
                            autoSize   = false,
                            size       = util.vector2(700, 510),
                        },
                        content = ui.content {
                            -- Tab bar across the top
                            tabBarElement,
                            myui.padWidget(0, 4),
                            {
                                name  = 'mainFlex',
                                type  = ui.TYPE.Flex,
                                props = {
                                    horizontal = true,
                                    autoSize   = false,
                                    size       = util.vector2(700, 430),
                                },
                                external = { grow = 1 },
                                content  = ui.content {
                                    -- Left: perk list
                                    perkList.root,
                                    myui.padWidget(8, 0),
                                    -- Right: two-section vertical layout.
                                    -- Top section (grow=1): detail content fills
                                    -- whatever space is left after the footer.
                                    -- Bottom section (no grow): fixed-height footer
                                    -- always visible at the bottom of the panel.
                                    {
                                        type  = ui.TYPE.Flex,
                                        props = {
                                            arrange      = ui.ALIGNMENT.Start,
                                            horizontal   = false,
                                            relativeSize = util.vector2(1, 1),
                                        },
                                        external = { grow = 1 },
                                        content  = ui.content {
                                            -- TOP: perk detail + "you have this" notice.
                                            {
                                                type  = ui.TYPE.Flex,
                                                props = {
                                                    arrange      = ui.ALIGNMENT.Start,
                                                    horizontal   = false,
                                                    relativeSize = util.vector2(1, 0),
                                                },
                                                external = { grow = 1 },
                                                content  = ui.content {
                                                    -- perkDetailElement uses relativeSize(1,1)
                                                    -- in its internal layout (detailLayout),
                                                    -- so it fills this container fully, giving
                                                    -- its text children a concrete pixel width
                                                    -- for word-wrap.
                                                    perkDetailElement,
                                                    myui.padWidget(0, 4),
                                                    haveThisPerk,
                                                },
                                            },
                                            -- BOTTOM: remaining points, cost, buttons.
                                            -- No grow: sizes to its natural content height
                                            -- and is always fully visible.
                                            {
                                                type  = ui.TYPE.Flex,
                                                props = {
                                                    arrange      = ui.ALIGNMENT.Start,
                                                    horizontal   = false,
                                                    relativeSize = util.vector2(1, 0),
                                                },
                                                content = ui.content {
                                                    remainingPointsElement,
                                                    myui.padWidget(0, 2),
                                                    perkPointCostElement,
                                                    myui.padWidget(0, 6),
                                                    -- Single permanent button row.
                                                    -- Prev/Next are always present; they
                                                    -- render as 'disabled' when the selected
                                                    -- perk has only one description page.
                                                    -- This avoids dynamic content changes
                                                    -- that would destroy Elements and crash.
                                                    {
                                                        type    = ui.TYPE.Flex,
                                                        props   = { horizontal = true },
                                                        content = ui.content {
                                                            previousDescriptionButtonElement,
                                                            myui.padWidget(8, 0),
                                                            nextDescriptionButtonElement,
                                                            myui.padWidget(8, 0),
                                                            pickButtonElement,
                                                            myui.padWidget(8, 0),
                                                            cancelButtonElement,
                                                        },
                                                    },
                                                    myui.padWidget(0, 8),
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    }
end

-- ============================================================
--  REDRAW
-- ============================================================

local function redraw()
    -- Build the category tree once per redraw; shared by the tab bar,
    -- the list renderer (via cachedTree), and the availability helpers.
    cachedTree = buildCategoryTree()
    local tabNames = getTabNames(cachedTree)

    -- Cache tab names at module scope so onFrame() can use them for
    -- keyboard/controller tab navigation without rebuilding the tree.
    cachedTabNames = tabNames

    -- Rebuild entry list for current tab/group state
    buildListEntries()

    -- If the current selection is on a non-navigable entry (e.g. a header row
    -- after a tab switch), silently advance to the first navigable entry so the
    -- player never needs to press down twice just to see a perk detail.
    -- Walk forward first; if nothing is found forward, try backward (handles
    -- the edge case where the cursor is below all navigable entries).
    if #currentListEntries > 0 then
        local idx = perkList.selectedIndex
        if not isEntryNavigable(idx, cachedTree) then
            -- Try forward
            local found = false
            for i = idx + 1, #currentListEntries do
                if isEntryNavigable(i, cachedTree) then
                    perkList.selectedIndex = i
                    found = true
                    break
                end
            end
            -- Fall back to searching backward
            if not found then
                for i = idx - 1, 1, -1 do
                    if isEntryNavigable(i, cachedTree) then
                        perkList.selectedIndex = i
                        break
                    end
                end
            end
        end
        -- Ensure the selected entry is within the visible scroll window
        if perkList.selectedIndex < perkList.topIndex then
            perkList.topIndex = perkList.selectedIndex
        elseif perkList.selectedIndex > perkList.topIndex + perkList.displayCount - 1 then
            perkList.topIndex = math.max(1, perkList.selectedIndex - perkList.displayCount + 1)
        end
    end

    -- Rebuild and update the tab bar, passing the tree for availability checks
    buildTabBar(tabNames, cachedTree)

    -- Update perk list widget
    perkList:setTotal(#currentListEntries)
    perkList:update()

    -- Update detail panel for the current selection
    local selectedPerk = getSelectedPerk()
    if selectedPerk ~= nil then
        perkDetailElement.layout = selectedPerk:detailLayout(selectedDescriptionText())
        perkDetailElement:update()
        haveThisPerk.layout.props.visible = hasPerk(getSelectedIndex())
        haveThisPerk:update()
    else
        -- Selection is on a header: clear the detail panel
        perkDetailElement.layout = {
            name = "detailLayout",
            type = ui.TYPE.Flex,
        }
        perkDetailElement:update()
        haveThisPerk.layout.props.visible = false
        haveThisPerk:update()
    end

    updatePickButtonElement()

    if menu ~= nil then
        menu:update()
    end
end

-- ============================================================
--  LIGHT REDRAW
--
--  A cheap refresh used for cursor movement within an unchanged
--  tab/group state (keyboard/controller up-down navigation,
--  mouse wheel, description page changes).
--
--  Skips the expensive steps that full redraw() does:
--    • buildCategoryTree()    — tree hasn't changed
--    • buildListEntries()     — entry list hasn't changed
--    • buildTabBar()          — tab bar hasn't changed
--    • perkList:setTotal()    — total hasn't changed
--
--  Only updates:
--    • perkList:update()      — re-renders visible rows with new highlight
--    • perkDetailElement      — shows the newly selected perk's detail
--    • haveThisPerk           — "you have this" notice
--    • updatePickButtonElement() — Acquire/Prev/Next/cost line
--    • menu:update()          — propagates changes to the root widget
--
--  Use full redraw() whenever the structure changes: tab switch,
--  dropdown toggled, perk acquired, or UI first opened.
-- ============================================================

local function lightRedraw()
    -- Re-render the list to update the highlighted row
    perkList:update()

    -- Update the detail panel for the current selection
    local selectedPerk = getSelectedPerk()
    if selectedPerk ~= nil then
        perkDetailElement.layout = selectedPerk:detailLayout(selectedDescriptionText())
        perkDetailElement:update()
        haveThisPerk.layout.props.visible = hasPerk(getSelectedIndex())
        haveThisPerk:update()
    else
        -- Selection is on a header or empty: clear the detail panel
        perkDetailElement.layout = {
            name = "detailLayout",
            type = ui.TYPE.Flex,
        }
        perkDetailElement:update()
        haveThisPerk.layout.props.visible = false
        haveThisPerk:update()
    end

    updatePickButtonElement()

    if menu ~= nil then
        menu:update()
    end
end

-- ============================================================
--  FULL REDRAW
-- ============================================================

local debounce = 0

local function showPerkUI(data)
    data = data or {}

    -- Prevent input for 5 frames to stop accidental Enter from console.
    debounce = DEBOUNCE_FRAMES
    satisfiedCache  = {}
    justPickedPerks = {}  -- clear pick tracking for the new session
    descriptionPagesByPerkID = {}
    activeDescriptionPageByPerkID = {}

    remainingPoints = interfaces.ErnPerkFramework.totalAllowedPoints() -
        interfaces.ErnPerkFramework.currentSpentPoints()

    -- Set the external perk-id filter, if provided.
    if data.visiblePerks ~= nil then
        if (type(data.visiblePerks) ~= "table") then
            error("showPerkUI(): expected visiblePerks to be a list, not a " .. type(data.visiblePerks))
        end
        visiblePerks = {}
        local idListString = ""
        for _, v in ipairs(data.visiblePerks) do
            visiblePerks[v] = true
            idListString = idListString .. ", " .. tostring(v)
        end
        log(nil, "Showing explicit subset of perks: " .. idListString)
        activeTabType = TAB_ALL
        tabPageIndex = 1
        expandedGroups = {}
    else
        visiblePerks = nil
    end

    -- Check availability against ALL perks regardless of the active tab.
    -- This ensures the UI opens even if the currently selected tab has no
    -- available perks (e.g. all Faction perks are locked but a Trait perk is free).
    if visiblePerks == nil then
        local aPerkIsAvailable = false
        local allPerks = interfaces.ErnPerkFramework.getPerks()
        for _, id in ipairs(interfaces.ErnPerkFramework.getPerkIDs()) do
            local perkObj = allPerks[id]
            if not perkObj:hidden() and perkAvailable(id) then
                aPerkIsAvailable = true
                break
            end
        end
        if not aPerkIsAvailable then
            log(nil, "No available perks found.")
            return
        end
    end

    if menu == nil then
        -- First open: default to the leftmost tab (index 1), which is the
        -- first alphabetical type-specific category. TAB_ALL sits on the
        -- right as a catch-all the player can navigate to if they want the
        -- unfiltered view.
        local tree     = buildCategoryTree()
        local tabNames = getTabNames(tree)
        if visiblePerks == nil then
            activeTabType = tabNames[1]
        end
        keepActiveTabVisible(tabNames)
        expandedGroups = {}

        interfaces.UI.setMode('Interface', { windows = {} })
        log(nil, "Showing Perk UI...")
        perkList.selectedIndex = 1
        menu = ui.create(menuLayout())
        redraw()
    else
        -- Already open (e.g. after acquiring a perk with points remaining):
        -- keep the current tab and groups, just refresh everything.
        redraw()
    end
end

-- ============================================================
--  INPUT
-- ============================================================

local function onMouseWheel(direction)
    if menu == nil then return end
    -- direction < 0 = wheel scrolled down → move cursor DOWN (higher index)
    -- direction > 0 = wheel scrolled up   → move cursor UP   (lower index)
    -- navigateList(+1) = down, navigateList(-1) = up
    -- lightRedraw() is used here instead of redraw() because the entry list
    -- and tab bar have not changed — only the highlighted row has moved.
    if direction < 0 then
        navigateList(1, cachedTree)
    else
        navigateList(-1, cachedTree)
    end
    lightRedraw()
end

-- ---------------------------------------------------------------
-- Key input state.
--
-- For keys that repeat while held (Up/Down list navigation,
-- Left/Right tab navigation), each key tracks how many frames
-- it has been held via a counter.  The first press fires
-- immediately; held keys wait KEY_REPEAT_INITIAL frames before
-- repeating, then fire every KEY_REPEAT_INTERVAL frames.
-- This is completely independent of the global `debounce` counter
-- so navigation never blocks other inputs (acquire, exit, etc.).
--
-- For keys that should fire exactly once per press (E, LB, RB,
-- Enter, Escape), we use a boolean that is set on press and
-- consumed on the following frame when the key is released.
-- ---------------------------------------------------------------

-- Frames held before the first auto-repeat fires
local KEY_REPEAT_INITIAL  = 20
-- Frames between subsequent auto-repeats while held
local KEY_REPEAT_INTERVAL = 6

local keyDownHeld   = 0   -- frames DownArrow / DPad Down has been held
local keyUpHeld     = 0   -- frames UpArrow   / DPad Up   has been held
local keyLeftHeld   = 0   -- frames LeftArrow / DPad Left  has been held
local keyRightHeld  = 0   -- frames RightArrow/ DPad Right has been held

-- Fire-on-release booleans (set on press, consumed on release)
local keyDropdownStatus = false
local keyDescPrevStatus = false
local keyDescNextStatus = false
local keyEnterStatus    = false
local keyEscapeStatus   = false

-- Helper: returns true on the frame a held counter should fire.
-- Fires immediately on frame 1, then again after INITIAL, then every INTERVAL.
local function shouldRepeat(heldFrames)
    if heldFrames == 1 then return true end
    if heldFrames <= KEY_REPEAT_INITIAL then return false end
    return (heldFrames - KEY_REPEAT_INITIAL) % KEY_REPEAT_INTERVAL == 0
end

-- How many extra frames to wait before accepting a held-key repeat
-- (kept for the UI-open guard only)
local LONG_DEBOUNCE = 5 * DEBOUNCE_FRAMES

local function onFrame(dt)
    if menu == nil then return end
    myui.processButtonAction(dt)

    -- Global debounce: only used on UI open to prevent accidental Enter
    -- from the console triggering an immediate perk pick.
    if debounce > 0 then
        debounce = debounce - 1
        return
    end

    -- ---------------------------------------------------------------
    -- List vertical navigation  (Up/Down arrows, DPad Up/Down)
    -- Uses per-key held counters for smooth auto-repeat.
    -- lightRedraw() used here: structure is unchanged.
    -- ---------------------------------------------------------------
    if input.isKeyPressed(input.KEY.DownArrow) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadDown) then
        keyDownHeld = keyDownHeld + 1
        if shouldRepeat(keyDownHeld) then
            navigateList(1, cachedTree)
            lightRedraw()
        end
    else
        keyDownHeld = 0
    end

    if input.isKeyPressed(input.KEY.UpArrow) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadUp) then
        keyUpHeld = keyUpHeld + 1
        if shouldRepeat(keyUpHeld) then
            navigateList(-1, cachedTree)
            lightRedraw()
        end
    else
        keyUpHeld = 0
    end

    -- ---------------------------------------------------------------
    -- Tab navigation  (Left/Right arrows, DPad Left/Right)
    -- Same auto-repeat approach; full redraw because the entry list changes.
    -- ---------------------------------------------------------------
    if input.isKeyPressed(input.KEY.LeftArrow) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadLeft) then
        keyLeftHeld = keyLeftHeld + 1
        if shouldRepeat(keyLeftHeld) then
            navigateTab(-1, cachedTree)
        end
    else
        keyLeftHeld = 0
    end

    if input.isKeyPressed(input.KEY.RightArrow) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.DPadRight) then
        keyRightHeld = keyRightHeld + 1
        if shouldRepeat(keyRightHeld) then
            navigateTab(1, cachedTree)
        end
    else
        keyRightHeld = 0
    end

    -- ---------------------------------------------------------------
    -- Dropdown expand/collapse  (E key / X button)
    -- Fires on RELEASE so a single tap produces exactly one toggle.
    -- ---------------------------------------------------------------
    if input.isKeyPressed(input.KEY.E) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.X) then
        keyDropdownStatus = true
    elseif keyDropdownStatus then
        toggleSelectedDropdown()
        keyDropdownStatus = false
    end

    -- ---------------------------------------------------------------
    -- Description page navigation  (Comma/Period, LB/RB)
    -- Fires on RELEASE for deliberate single-step paging.
    -- ---------------------------------------------------------------
    if input.isKeyPressed(input.KEY.Comma) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.LeftShoulder) then
        keyDescPrevStatus = true
    elseif keyDescPrevStatus then
        changeDescriptionPage(-1)
        keyDescPrevStatus = false
    end

    if input.isKeyPressed(input.KEY.Period) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.RightShoulder) then
        keyDescNextStatus = true
    elseif keyDescNextStatus then
        changeDescriptionPage(1)
        keyDescNextStatus = false
    end

    -- ---------------------------------------------------------------
    -- Acquire perk  (Enter / A button)
    -- Fires on RELEASE.
    -- ---------------------------------------------------------------
    if input.isKeyPressed(input.KEY.Enter) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.A) then
        keyEnterStatus = true
    elseif keyEnterStatus == true then
        local entry = currentListEntries[getSelectedIndex()]
        if entry and entry.kind == "header" then
            -- Enter on a header row expands/collapses it instead of picking
            toggleSelectedDropdown()
        else
            doPick()
        end
        keyEnterStatus = false
    end

    -- ---------------------------------------------------------------
    -- Exit
    -- Escape / B button → close the UI (fires on RELEASE)
    -- ---------------------------------------------------------------
    if input.isKeyPressed(input.KEY.Escape) or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.B) then
        keyEscapeStatus = true
    elseif keyEscapeStatus then
        keyEscapeStatus = false
        closeUI()
    end
end

-- Internal event fired by tab buttons and group header buttons to trigger a
-- redraw from within a UI callback. Callbacks cannot call redraw() directly
-- because the UI is mid-update at that point; deferring via a player event
-- guarantees the redraw happens in the next safe tick.
local function onInternalRedraw()
    redraw()
end

-- Lightweight version of the above, used when only the detail panel and
-- button states need refreshing (description page changes).
local function onInternalLightRedraw()
    lightRedraw()
end

return {
    eventHandlers = {
        [MOD_NAME .. "showPerkUI"]            = showPerkUI,
        [MOD_NAME .. "closePerkUI"]           = closeUI,
        [MOD_NAME .. "_internalRedraw"]       = onInternalRedraw,
        [MOD_NAME .. "_internalLightRedraw"]  = onInternalLightRedraw,
    },
    engineHandlers = {
        onFrame      = onFrame,
        onMouseWheel = onMouseWheel,
    }
}
