-- local core = require('openmw.core')
-- local types = require('openmw.types')
local self = require('openmw.self')
local input = require('openmw.input')
-- local ui = require('openmw.ui')
-- local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local quickUIStuff = require('scripts.spellsBookmark.quickUI')
local quickUiData = require('scripts.spellsBookmark.quickUI_data')
-- local storage = require('openmw.storage')
-- local ambient = require('openmw.ambient')
local createBookmarksWindow = quickUIStuff.createBookmarksWindow
local createBookmarkManagerWindow = quickUIStuff.createBookmarkManagerWindow
local scrollUp = quickUIStuff.scrollUp
local scrollDown = quickUIStuff.scrollDown
local onFrame = quickUIStuff.onFrame
-- local ALL_SPELLS = core.magic.spells.records
-- local testWindow = require('scripts.test').testWindow

-- These lines set up a common variable (the mod ID, which cannot have spaces in it) and load a few more things from the OpenMW engine:
-- L: Use OpenMW's builtin localization handling to support multiple languages more easily
-- Player: Access the player object in the game
-- playerSettings: Access the player's settings
local MOD_ID = "spellsBookmark"
local L = require("openmw.core").l10n(MOD_ID)
-- local Player = require("openmw.types").Player
-- local playerSettings = storage.playerSection("SettingsPlayer" .. MOD_ID)

I.Settings.registerPage {
        key = MOD_ID,
        l10n = MOD_ID,
        name = "spellsBookmark",
        description = L("Add spells to a quick access menu")
}

local showBookmarksKey = 'showBookmarksKey'
local showManagerKey = 'showManagerKey'

I.Settings.registerGroup {
        key = "SettingsPlayer" .. MOD_ID,
        l10n = MOD_ID,
        name = "spellsBookmark",
        page = MOD_ID,
        -- description = "settingsDescription",
        permanentStorage = false,
        settings = {
                {
                        key = showBookmarksKey,
                        name = 'View bookmarks',
                        -- description = 'description',
                        default = 'v',
                        renderer = "inputBinding",
                        argument = {
                                key = showBookmarksKey,
                                type = 'trigger'
                        }
                },
                {
                        key = showManagerKey,
                        name = 'Manage bookmarks',
                        -- description = 'description',
                        default = 'b',
                        renderer = "inputBinding",
                        argument = {
                                key = showManagerKey,
                                type = 'trigger'
                        }
                }
        }
}

input.registerTrigger {
        key = showBookmarksKey,
        l10n = 'MyLocalizationContext',
        -- name = 'MyTrigger_name',
        -- description = 'MyTrigger_full_description',
}
input.registerTrigger {
        key = showManagerKey,
        l10n = 'MyLocalizationContext',
        -- name = 'MyTrigger_name',
        -- description = 'MyTrigger_full_description',
}


local function closeWindow(window)
        SpellWindows[window]:destroy()
        SpellWindows[window] = nil
        I.UI.setMode(nil)
end

local function showBookmarks()
        if SpellWindows.quickSpells == nil then
                if SpellWindows.bmManager then
                        closeWindow('bmManager')
                end

                createBookmarksWindow()
                I.UI.addMode('Interface', { windows = {} })
        else
                closeWindow('quickSpells')
        end
end

local function showManager()
        if SpellWindows.bmManager == nil then
                if SpellWindows.quickSpells then
                        closeWindow('quickSpells')
                end

                createBookmarkManagerWindow()
                I.UI.addMode('Interface', { windows = {} })
        else
                closeWindow('bmManager')
        end
end

input.registerTriggerHandler(showBookmarksKey, async:callback(showBookmarks))
input.registerTriggerHandler(showManagerKey, async:callback(showManager))

SpellWindows = {
        quickSpells = nil,
        bmManager = nil
}


local function closeBoth()
        if SpellWindows.quickSpells then
                SpellWindows.quickSpells:destroy()
                SpellWindows.quickSpells = nil
        end
        if SpellWindows.bmManager then
                SpellWindows.bmManager:destroy()
                SpellWindows.bmManager = nil
        end
end


local function onLoad()
        quickUiData.loadData(self)
end

local function onSave()
        quickUiData.saveData()
end

return {
        engineHandlers = {
                -- onKeyPress = onKeyPress,
                onFrame = onFrame,
                onLoad = onLoad,
                onSave = onSave,
                onMouseWheel = function(v, h)
                        if SpellWindows and SpellWindows.bmManager then
                                if v == -1 then
                                        scrollUp()
                                else
                                        if v == 1 then
                                                scrollDown()
                                        end
                                end
                        end
                end,
        },
        eventHandlers = {
                UiModeChanged = function(data)
                        -- print('UiModeChanged from', data.oldMode, 'to', data.newMode, '(' .. tostring(data.arg) .. ')')
                        if data.oldMode ~= nil then
                                if data.newMode == nil then
                                        closeBoth()
                                else
                                        if data.oldMode ~= data.newMode and data.newMode ~= 'Interface' then
                                                closeBoth()
                                        end
                                end
                        end
                end
        },
}
