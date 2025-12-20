local input = require('openmw.input')
local I = require('openmw.interfaces')


local MOD_ID = "spellsBookmark"
local prefix = 'SettingsPlayer'
local L = require("openmw.core").l10n(MOD_ID)


local function getSectionKey()
        return prefix .. MOD_ID
end



local o = {
        showMagicWindow = {
                key = 'showMagicWindow',
                default = MOD_ID,
                value = MOD_ID,
                argument = {
                        type = 'trigger',
                        key = 'showMagicWindowArgKey'
                }
        },
        showWindowOnInterface = {
                key = 'showWindowOnInterface',
                value = true,
                default = true,
        },

        scrollDirection = {
                key = 'scrollDirection',
                value = 'Reversed',
                default = 'Reversed',

        },

        windowW = {
                key = 'windowW',
                value = 300,
                default = 300,
        },
        windowH = {
                key = 'windowH',
                value = 200,
                default = 200,
        },
        windowX = {
                key = 'windowX',
                value = 0,
                default = 0,
        },
        windowY = {
                key = 'windowY',
                value = 0,
                default = 0,
        },
        windowAnchX = {
                key = 'windowAnchX',
                value = 0,
                default = 0,
        },
        windowAnchY = {
                key = 'windowAnchY',
                value = 0,
                default = 0,
        },
}

I.Settings.registerPage {
        key = MOD_ID,
        l10n = MOD_ID,
        name = "Spells Bookmarks",
        description = L("Add spells to a quick access menu")
}

input.registerTrigger {
        key = o.showMagicWindow.argument.key,
        l10n = MOD_ID,
}

-- local windowSettings = {}
-- for i, v in pairs({ 'windowX', 'windowY', 'windowW', 'windowH', 'windowAnchX', 'windowAnchY' }) do
--         local setting = {
--                 key = o[v].key,
--                 name = o[v].key,
--                 default = o[v].default,
--                 renderer = "number",
--         }

--         table.insert(windowSettings, setting)
-- end

I.Settings.registerGroup {
        -- key = prefix .. MOD_ID,
        key = getSectionKey(),
        l10n = MOD_ID,
        name = "Spells Bookmarks",
        page = MOD_ID,
        permanentStorage = false,
        -- description = "settingsDescription",
        settings = {
                {
                        key = o.showMagicWindow.key,
                        name = 'Open magic window',
                        default = o.showMagicWindow.default,
                        renderer = "inputBinding",
                        argument = {
                                key = o.showMagicWindow.argument.key,
                                type = 'trigger',
                        }
                },
                {
                        key = o.showWindowOnInterface.key,
                        name = 'Show window when opening inventory',
                        default = o.showWindowOnInterface.default,
                        renderer = "checkbox",
                },
                {
                        key = o.scrollDirection.key,
                        name = 'List scroll direction',
                        default = o.scrollDirection.default,
                        renderer = "select",
                        argument = {
                                l10n = MOD_ID,
                                items = { 'Natural', 'Reversed' }
                        },
                },

                -- table.unpack(windowSettings)

        }

}


return {
        o = o,
        getSectionKey = getSectionKey
}
