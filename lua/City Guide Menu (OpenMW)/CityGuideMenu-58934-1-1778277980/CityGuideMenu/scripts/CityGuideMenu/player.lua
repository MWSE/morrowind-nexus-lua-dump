-- City Guide Menu for OpenMW 0.51+
-- Bind the toggle hotkey in: Options -> Scripts -> City Guide Menu -> Hotkey.
-- Default key: N. Opens a categorized menu of map books in your inventory;
-- click an entry to open it via the normal book/scroll viewer.

local ui      = require('openmw.ui')
local util    = require('openmw.util')
local input   = require('openmw.input')
local self    = require('openmw.self')
local core    = require('openmw.core')
local types   = require('openmw.types')
local async   = require('openmw.async')
local storage = require('openmw.storage')
local I       = require('openmw.interfaces')

----------------------------------------------------------------
-- KNOWN MAPS, grouped by source mod
----------------------------------------------------------------
local KNOWN_MAPS = {
    ['Morrowind'] = {
        -- Vanilla
        'bk_guide_to_vvardenfell',
        'bk_guide_to_vivec',
        'bk_guide_to_balmora',
        'bk_guide_to_ald_ruhn',
        'bk_guide_to_sadrithmora',
        -- Tamriel Rebuilt mainland
        't_sc_guidetoalmalexiatr',
        't_sc_guidetoalmasthirrtr',
        't_sc_guidetoandothrentr',
        't_sc_guidetoandrethistr',
        't_sc_guidetoblacklighttr',
        't_sc_guidetodeshaantr',
        't_sc_guidetodreshoraktr',
        't_sc_guidetofirewatchtr',
        't_sc_guidetohlerynhultr',
        't_sc_guidetokogoteltr',
        't_sc_guidetokragenmoortr',
        't_sc_guidetomervayantr',
        't_sc_guidetomournholddistricttr',
        't_sc_guidetonarsisdistricttr',
        't_sc_guidetonarsistr',
        't_sc_guidetonecrom',
        't_sc_guidetooldebonhearttr',
        't_sc_guidetoporttelvannistr',
        't_sc_guidetosilgradtr',
        't_sc_guidetoteartr',
        't_sc_guidetotelvannistr',
        't_sc_guidetovelothistr',
    },
    ['Skyrim'] = {
        't_sc_guidetodragonstarshotn',
        't_sc_guidetofalkreathshotn',
        't_sc_guidetohaafingarshotn',
        't_sc_guidetokarthwastenshotn',
        't_sc_guidetomarkarthsideshotn',
        't_sc_guidetowhiterunshotn',
        't_sc_guidetowinterholdshotn',
    },
    ['Cyrodiil'] = {
        't_sc_guidetoanvilpc',
        't_sc_guidetochorrolpc',
        't_sc_guidetokvatchpc',
        't_sc_guidetoskingradpc',
        't_sc_guidetosutchpc',
    },
}

local CATEGORY_ORDER = {
    'Morrowind',
    'Skyrim',
    'Cyrodiil',
}

local CATEGORY_BY_ID = {}
for cat, ids in pairs(KNOWN_MAPS) do
    for _, id in ipairs(ids) do
        CATEGORY_BY_ID[id] = cat
    end
end

----------------------------------------------------------------
-- Display-name helper: strip "Guide to " prefix for cleaner rows
----------------------------------------------------------------
local function shortDisplayName(name)
    if not name or name == '' then return '?' end
    return (string.gsub(name, '^Guide to ', ''))
end

----------------------------------------------------------------
-- Input action + Settings page
----------------------------------------------------------------
input.registerAction {
    key          = 'CityGuideMenuToggle',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'CityGuideMenu',
    name         = 'City Guide Menu: toggle',
    description  = '',
    defaultValue = false,
}

I.Settings.registerPage {
    key         = 'CityGuideMenu',
    l10n        = 'CityGuideMenu',
    name        = 'City Guide Menu',
    description = 'Lists the maps currently in your inventory. '
                .. 'Click an entry to open the scroll viewer for that map.',
}

I.Settings.registerGroup {
    key              = 'SettingsPlayerCityGuideMenu',
    page             = 'CityGuideMenu',
    l10n             = 'CityGuideMenu',
    name             = 'Hotkey',
    permanentStorage = true,
    settings = {
        {
            key         = 'toggleHotkey',
            renderer    = 'inputBinding',
            name        = '',
            description = '',
            default     = 'n',
            argument    = { key = 'CityGuideMenuToggle', type = 'action' },
        },
    },
}

-- Scaling: OpenMW does not expose its own GUI scaling factor to Lua, so
-- the user has to mirror the value here. The menu was tuned at 1.67 (the
-- "calibration" scaling). At any other value, the script multiplies all
-- pixel-based dimensions by 1.67 / userScale so the menu renders at a
-- constant physical size matching the calibration look.
I.Settings.registerGroup {
    key              = 'SettingsPlayerCityGuideMenuScaling',
    page             = 'CityGuideMenu',
    l10n             = 'CityGuideMenu',
    name             = 'Scaling',
    permanentStorage = true,
    settings = {
        {
            key         = 'guiScale',
            renderer    = 'number',
            name        = 'OpenMW GUI Scaling Factor',
            description = 'Set this to match your OpenMW GUI Scaling Factor.',
            default     = 1.67,
        },
    },
}

local scalingSettings = storage.playerSection('SettingsPlayerCityGuideMenuScaling')

----------------------------------------------------------------
-- UI state
----------------------------------------------------------------
local PAUSE_TAG = 'CityGuideMenu'

-- UI modes the engine puts us into when activating a map item; used to
-- recognise the "third press dismisses the city map we just opened" case.
local BOOK_LIKE_MODES = { Book = true, Scroll = true }

local menuElement       = nil
local cityMapOpenedByUs = false  -- set when we trigger UseItem on a map
local currentRowProps   = nil    -- props of the current-city row (for cross-row hover toggle)

-- Journal palette (from openmw.cfg fallbacks):
local COLOR_HEADER       = util.color.rgb(0/255,  0/255,  0/255)  -- color_answer (day-title red)
local COLOR_CITY_NORMAL  = util.color.rgb( 0/255,  0/255, 0/255)  -- journal_link
local COLOR_CITY_HOVER   = util.color.rgb( 41/255,  63/255, 173/255)  -- journal_link_over
local COLOR_CITY_CURRENT = util.color.rgb( 41/255, 63/255, 173/255)  -- journal_link_pressed
local COLOR_NORMAL       = COLOR_CITY_NORMAL  -- used for the "no maps" message

----------------------------------------------------------------
-- Layout (in unscaled UI pixels; engine applies the GUI scaling factor)
----------------------------------------------------------------
-- Vanilla scroll texture (Morrowind.bsa: textures/scroll.dds). Renders
-- the in-game scroll background. We size the menu as a fraction of the
-- player's screen via ui.screenSize() so the scroll fills a consistent
-- visual portion regardless of resolution or GUI scaling factor.
-- Texture paths route through the BSA so loose-file replacers win.

-- ============================================================
-- TUNE THE MENU SIZE HERE
-- ============================================================
-- MENU_W_RATIO: menu width as a fraction of screen width.
-- MENU_ASPECT:  width / height (vanilla scroll viewer is ~1.34).
-- After editing, type `reloadlua` in the OpenMW console.
-- ============================================================
local MENU_W_RATIO = 0.332
local MENU_ASPECT  = 1.375

-- ============================================================
-- FINE TUNING: positions, sizes, alignment.
-- All values can be edited; `reloadlua` to see changes.
--
-- Pixel-sized values below (anything in plain pixels rather than a
-- 0.x ratio) are calibrated at OpenMW [GUI] scaling factor = 1.67.
-- They are auto-compensated at render time against the user-set
-- "OpenMW GUI Scaling Factor" setting so the menu renders at a
-- constant physical size regardless of the actual GUI scaling.
-- Position ratios (TITLE_Y_RATIO, CLOSE_Y_RATIO, etc.) inherit the
-- compensation through MENU_W / MENU_H, which already include it.
-- ============================================================

-- Title placement:
local TITLE_Y_RATIO    = 0.22    -- vertical position (smaller = higher up)
local TITLE_X_OFFSET   = 25.0    -- horizontal nudge in pixels (-left, +right)

-- Three province columns:
local CONTENT_X_RATIO  = 0.15    -- larger = columns shifted further right

-- Close button:
local CLOSE_W          = 80     -- width  (native texture is 64)
local CLOSE_H          = 40      -- height (native texture is 32)
local CLOSE_Y_RATIO    = 0.0565    -- vertical position (smaller = higher up)
local CLOSE_RIGHT_PAD  = 41      -- pixels from menu's right edge
-- ============================================================

-- Layout values that rarely need tuning:
-- CONTENT_Y_RATIO sits roughly halfway between the title baseline and the
-- middle of the scroll, so the columns hug the title rather than floating
-- in the lower half of the parchment.
local CONTENT_Y_RATIO  = 0.31
local CONTENT_W_RATIO  = 0.78
local HEADER_GAP_RATIO = 0.062
local ROW_GAP_RATIO    = 0.048

local TITLE_TEXT       = 'City Guides'
local TITLE_TEXT_SIZE  = 30
local HEADER_TEXT_SIZE = 24
local ROW_TEXT_SIZE    = 20

-- ============================================================
-- Scale compensation
-- ============================================================
-- The menu was tuned at OpenMW GUI scaling factor 1.67. ui.screenSize()
-- returns physical screen pixels (not logical), and widget sizes /
-- font sizes are interpreted as logical pixels that the engine then
-- multiplies by the live GUI scaling factor. So a literal 30 px font
-- will render at 30 * scalingFactor physical px -- bigger at 1.67,
-- smaller at 1.0. To keep the on-screen size constant, every absolute
-- pixel value is multiplied by 1.67 / userScale. CALIBRATION_GUI_SCALE
-- is fixed; userScale comes from the "OpenMW GUI Scaling Factor"
-- setting and the user is expected to keep it in sync with their
-- engine setting.
--
-- OpenMW exposes no Lua API for reading engine settings, which is why
-- this duplication is necessary; mirroring it once via the settings
-- page is the least bad option.
local CALIBRATION_GUI_SCALE = 1.67
local CURRENT_PX_FACTOR     = 1.0
local function px(v)
    return math.floor(v * CURRENT_PX_FACTOR + 0.5)
end
local function refreshScaleFactor()
    local userScale = scalingSettings:get('guiScale')
    if not userScale or userScale <= 0 then
        userScale = CALIBRATION_GUI_SCALE
    end
    CURRENT_PX_FACTOR = CALIBRATION_GUI_SCALE / userScale
end

-- Vanilla textures from Morrowind.bsa.
local TEX_SCROLL        = ui.texture { path = 'textures/scroll.dds' }
local TEX_CLOSE_IDLE    = ui.texture { path = 'textures/tx_menubook_close_idle.dds' }
local TEX_CLOSE_OVER    = ui.texture { path = 'textures/tx_menubook_close_over.dds' }
local TEX_CLOSE_PRESSED = ui.texture { path = 'textures/tx_menubook_close_pressed.dds' }

----------------------------------------------------------------
-- Open/close lifecycle
----------------------------------------------------------------
local function destroyWidget()
    if menuElement then
        menuElement:destroy()
        menuElement = nil
    end
end

local function closeMenu()
    if not menuElement then return end
    destroyWidget()
    pcall(function() I.UI.removeMode('Interface') end)
    core.sendGlobalEvent('Unpause', PAUSE_TAG)
end

local function activateMap(mapItem)
    cityMapOpenedByUs = true
    closeMenu()
    core.sendGlobalEvent('UseItem', {
        object = mapItem,
        actor  = self.object,
    })
end

----------------------------------------------------------------
-- Inventory scan
----------------------------------------------------------------
local function getOwnedMapsByCategory()
    local byCat = {}
    local inventory = types.Actor.inventory(self)
    for _, book in ipairs(inventory:getAll(types.Book)) do
        local cat = CATEGORY_BY_ID[book.recordId]
        if cat then
            byCat[cat] = byCat[cat] or {}
            local rec = types.Book.records[book.recordId]
            table.insert(byCat[cat], {
                object  = book,
                display = shortDisplayName(rec and rec.name),
            })
        end
    end
    for _, list in pairs(byCat) do
        table.sort(list, function(a, b) return a.display < b.display end)
    end
    return byCat
end

----------------------------------------------------------------
-- Current-city detection
----------------------------------------------------------------
-- Lowercase + drop spaces/apostrophes/dashes/dots so that
-- "Ald'ruhn, Skar"  matches  "Ald-Ruhn"  matches  "ald ruhn".
local function normalize(s)
    return string.gsub(string.lower(s or ''), "[%s%-%'%.]", '')
end

-- Find the owned-map entry whose display name appears in the player's
-- current cell name. Longer match wins so a player standing in
-- "Old Ebonheart, ..." gets the Old Ebonheart map rather than a
-- hypothetical Ebonheart map. Returns the {object, display} entry or nil.
local function findCurrentCityMap(byCat)
    local cellNorm = normalize(self.cell.name)
    if cellNorm == '' then return nil end
    local best, bestLen = nil, 0
    for _, list in pairs(byCat) do
        for _, entry in ipairs(list) do
            local n = normalize(entry.display)
            if #n > bestLen and n ~= '' and string.find(cellNorm, n, 1, true) then
                best, bestLen = entry, #n
            end
        end
    end
    return best
end

----------------------------------------------------------------
-- Widget builders
----------------------------------------------------------------
local function headerWidget(text)
    return {
        type = ui.TYPE.Text,
        props = {
            text      = text,
            textSize  = px(HEADER_TEXT_SIZE),
            textColor = COLOR_HEADER,
        },
    }
end

local function rowWidget(entry, isCurrent)
    local baseColor = isCurrent and COLOR_CITY_CURRENT or COLOR_CITY_NORMAL
    local props = {
        text      = '* ' .. entry.display,
        textSize  = px(ROW_TEXT_SIZE),
        textColor = baseColor,
    }
    if isCurrent then currentRowProps = props end

    return {
        type  = ui.TYPE.Text,
        props = props,
        events = {
            mouseClick = async:callback(function() activateMap(entry.object) end),
            focusGain  = async:callback(function()
                props.textColor = COLOR_CITY_HOVER
                -- Hovering a non-current row toggles the current-city
                -- highlight off so only one city looks "selected" at a time.
                if not isCurrent and currentRowProps then
                    currentRowProps.textColor = COLOR_CITY_NORMAL
                end
                if menuElement then menuElement:update() end
            end),
            focusLoss  = async:callback(function()
                props.textColor = baseColor
                if not isCurrent and currentRowProps then
                    currentRowProps.textColor = COLOR_CITY_CURRENT
                end
                if menuElement then menuElement:update() end
            end),
        },
    }
end

----------------------------------------------------------------
-- Render
----------------------------------------------------------------
-- Approximate rendered width of `text` at `size` pixels. Pelagiad averages
-- about 0.5x its size per character; we round up slightly to leave breathing
-- room and avoid clipping. Used for manual centering since the OpenMW Lua
-- centering APIs (Flex arrange/justify, relativePosition+anchor on
-- non-root widgets) didn't behave reliably in this 0.51 build.
local function estimateTextWidth(text, size)
    return math.ceil(#text * size * 0.55)
end

-- Close button with idle/over/pressed visual states. Uses focus and mouse
-- events to swap textures, falling back gracefully if focus events don't
-- fire on Image widgets in this 0.51 build (worst case: idle texture only).
local function closeButtonLayout(x, y)
    local props = {
        resource = TEX_CLOSE_IDLE,
        position = util.vector2(x, y),
        size     = util.vector2(px(CLOSE_W), px(CLOSE_H)),
    }
    local function setTexture(tex)
        props.resource = tex
        if menuElement then menuElement:update() end
    end
    return {
        type  = ui.TYPE.Image,
        props = props,
        events = {
            mouseClick = async:callback(function() closeMenu() end),
            focusGain  = async:callback(function() setTexture(TEX_CLOSE_OVER) end),
            focusLoss  = async:callback(function() setTexture(TEX_CLOSE_IDLE) end),
            mousePress = async:callback(function() setTexture(TEX_CLOSE_PRESSED) end),
        },
    }
end

local function renderMenu()
    destroyWidget()
    currentRowProps = nil  -- reset before rebuilding rows

    -- Pull the latest user-set GUI scaling factor before computing any
    -- pixel sizes; lets the user reloadlua-free tweak the setting and
    -- have it picked up next time the menu opens.
    refreshScaleFactor()

    -- Resolve layout ratios to absolute menu pixels using current screen
    -- size. Done at render time so the scroll scales if the player changes
    -- resolution mid-game (re-open the menu to pick up new dims).
    local screen    = ui.screenSize()
    local MENU_W    = math.floor(screen.x * MENU_W_RATIO * CURRENT_PX_FACTOR)
    local MENU_H    = math.floor(MENU_W / MENU_ASPECT)

    local TITLE_Y   = math.floor(MENU_H * TITLE_Y_RATIO)
    local CLOSE_X   = MENU_W - px(CLOSE_W) - px(CLOSE_RIGHT_PAD)
    local CLOSE_Y   = math.floor(MENU_H * CLOSE_Y_RATIO)
    local CONTENT_X = math.floor(MENU_W * CONTENT_X_RATIO)
    local CONTENT_Y = math.floor(MENU_H * CONTENT_Y_RATIO)
    local CONTENT_W = math.floor(MENU_W * CONTENT_W_RATIO)
    local HEADER_GAP = math.floor(MENU_H * HEADER_GAP_RATIO)
    local ROW_GAP    = math.floor(MENU_H * ROW_GAP_RATIO)

    local byCat      = getOwnedMapsByCategory()
    local current    = findCurrentCityMap(byCat)
    local currentObj = current and current.object or nil

    local content = {
        -- Scroll background.
        {
            type = ui.TYPE.Image,
            props = {
                resource = TEX_SCROLL,
                position = util.vector2(0, 0),
                size     = util.vector2(MENU_W, MENU_H),
            },
        },
        -- Title centered manually. relativePosition+anchor centers root
        -- widgets fine but doesn't work for child widgets here, so we
        -- compute the left edge from an estimated text width.
        (function()
            local w = estimateTextWidth(TITLE_TEXT, px(TITLE_TEXT_SIZE))
            return {
                type = ui.TYPE.Text,
                props = {
                    text      = TITLE_TEXT,
                    textSize  = px(TITLE_TEXT_SIZE),
                    textColor = COLOR_HEADER,
                    position  = util.vector2(math.floor((MENU_W - w) / 2) + px(TITLE_X_OFFSET), TITLE_Y),
                },
            }
        end)(),
        closeButtonLayout(CLOSE_X, CLOSE_Y),
    }

    -- Collect provinces with at least one owned map. We position columns
    -- absolutely, dividing CONTENT_W into N equal slots; this avoids the
    -- Flex auto-sizing-to-widest-child issue where columns ended up
    -- packed at their natural widths instead of distributed.
    local activeCats = {}
    for _, cat in ipairs(CATEGORY_ORDER) do
        local list = byCat[cat]
        if list and #list > 0 then
            activeCats[#activeCats + 1] = { cat = cat, list = list }
        end
    end

    if #activeCats == 0 then
        content[#content + 1] = {
            type = ui.TYPE.Text,
            props = {
                text      = 'No maps in inventory.',
                textSize  = px(ROW_TEXT_SIZE),
                textColor = COLOR_NORMAL,
                position  = util.vector2(CONTENT_X, CONTENT_Y),
            },
        }
    else
        local slot = math.floor(CONTENT_W / #activeCats)
        for i, ac in ipairs(activeCats) do
            -- Find the widest line in this column (header or longest city
            -- with bullet) so we can shift the whole column right within
            -- its slot to look centered. Header and city use different
            -- font sizes so we measure each at its own size.
            local widest = estimateTextWidth(ac.cat, px(HEADER_TEXT_SIZE))
            for _, entry in ipairs(ac.list) do
                local w = estimateTextWidth('* ' .. entry.display, px(ROW_TEXT_SIZE))
                if w > widest then widest = w end
            end
            local colX = CONTENT_X + (i - 1) * slot
                       + math.max(0, math.floor((slot - widest) / 2))

            local children = { headerWidget(ac.cat) }
            for _, entry in ipairs(ac.list) do
                children[#children + 1] = rowWidget(entry, entry.object == currentObj)
            end
            content[#content + 1] = {
                type = ui.TYPE.Flex,
                props = {
                    position   = util.vector2(colX, CONTENT_Y),
                    horizontal = false,
                    autoSize   = true,
                },
                content = ui.content(children),
            }
        end
    end

    menuElement = ui.create {
        type  = ui.TYPE.Container,
        layer = 'Windows',
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor           = util.vector2(0.5, 0.5),
            size             = util.vector2(MENU_W, MENU_H),
        },
        content = ui.content(content),
    }
end


local function openMenu()
    renderMenu()
    I.UI.addMode('Interface', { windows = {} })
    core.sendGlobalEvent('Pause', PAUSE_TAG)
end

local function toggleMenu()
    -- Stage 3: a previous press of ours opened a city map (Book/Scroll mode).
    -- This press closes that viewer. Has to be checked before the menuElement
    -- branch because menuElement is nil at this point (we destroyed it when
    -- we activated the map).
    if cityMapOpenedByUs and BOOK_LIKE_MODES[I.UI.getMode()] then
        cityMapOpenedByUs = false
        pcall(function() I.UI.removeMode(I.UI.getMode()) end)
        return
    end

    -- Stage 2: the menu is up. If we're standing in a city we own a map for,
    -- open that map. Otherwise close the menu (the legacy behaviour).
    if menuElement then
        local current = findCurrentCityMap(getOwnedMapsByCategory())
        if current then
            activateMap(current.object)
        else
            closeMenu()
        end
        return
    end

    -- Stage 1: nothing of ours is up. Open the menu, gated on:
    --   * I.UI.getMode() ~= nil whenever inventory/dialogue/etc is up.
    --   * core.isWorldPaused() returns true while the console is open
    --     (the console isn't a UI mode but the engine pauses for it).
    if (not I.UI.getMode()) and (not core.isWorldPaused()) then
        openMenu()
    end
end

----------------------------------------------------------------
-- Wire up hotkey
----------------------------------------------------------------
input.registerActionHandler(
    'CityGuideMenuToggle',
    async:callback(function(pressed)
        if pressed then toggleMenu() end
    end)
)

----------------------------------------------------------------
-- Engine handlers
----------------------------------------------------------------
return {
    engineHandlers = {
        onSave = function() return {} end,
        onLoad = function() destroyWidget() end,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            -- Esc'd out of our menu while it was open: tear down + unpause.
            if menuElement and data.oldMode == 'Interface' then
                destroyWidget()
                core.sendGlobalEvent('Unpause', PAUSE_TAG)
            end
            -- Player exited a Book/Scroll some other way (Esc, click outside)
            -- — clear our flag so the next hotkey press doesn't try to close
            -- a viewer that's already gone.
            if cityMapOpenedByUs and BOOK_LIKE_MODES[data.oldMode] then
                cityMapOpenedByUs = false
            end
        end,
    },
}