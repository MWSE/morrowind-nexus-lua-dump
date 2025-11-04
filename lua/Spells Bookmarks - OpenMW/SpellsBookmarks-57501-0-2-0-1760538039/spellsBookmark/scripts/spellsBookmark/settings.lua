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
                value = 'v',
                default = 'v',
        },
        showWindowOnInterface = {
                key = 'showWindowOnInterface',
                value = true,
                default = true,
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
                value = 30,
                default = 30,
        },
        windowY = {
                key = 'windowY',
                value = 30,
                default = 30,
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
                                key = o.showMagicWindow.key,
                                type = 'trigger'
                        }
                },
                {
                        key = o.showWindowOnInterface.key,
                        name = 'Show window when opening inventory',
                        default = o.showWindowOnInterface.default,
                        renderer = "checkbox",
                },

                -- table.unpack(windowSettings)

        }

}

input.registerTrigger {
        key = o.showMagicWindow.key,
        l10n = 'MyLocalizationContext',
}

return {
        o = o,
        getSectionKey = getSectionKey
}
