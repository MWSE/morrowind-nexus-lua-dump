---@omw-context menu
local interfaces = require("openmw.interfaces")

local PAGE_KEY = "Spellforge"
local GROUP_KEY = "SettingsPlayerSpellforge"
local KEY_UI_SIZE = "ui_size"

local PRESET_ORDER = {
    "Normal",
    "Large",
    "Extra Large",
}

local function alreadyRegisteredError(err)
    local message = string.lower(tostring(err or ""))
    return string.find(message, "already", 1, true) ~= nil
        and string.find(message, "registered", 1, true) ~= nil
end

local function registerPage(settings)
    local ok, err = pcall(function()
        settings.registerPage {
            key = PAGE_KEY,
            l10n = "Spellforge",
            name = "Spellforge",
            description = "Spellforge Settings",
        }
    end)
    return ok or alreadyRegisteredError(err), err
end

local function registerGroup(settings)
    local ok, err = pcall(function()
        settings.registerGroup {
            key = GROUP_KEY,
            page = PAGE_KEY,
            l10n = "Spellforge",
            name = "Spellforge UI",
            description = "Spellforge UI Settings",
            permanentStorage = true,
            order = 0,
            settings = {
                {
                    key = KEY_UI_SIZE,
                    renderer = "select",
                    name = "UI Size",
                    description = "Scales the Spellforge spellmaking window and text.",
                    default = "Normal",
                    argument = {
                        disabled = false,
                        l10n = "Spellforge",
                        items = PRESET_ORDER,
                    },
                },
            },
        }
    end)
    return ok or alreadyRegisteredError(err), err
end

local function registerSettings()
    local settings = interfaces.Settings
    if settings == nil
        or type(settings.registerPage) ~= "function"
        or type(settings.registerGroup) ~= "function"
    then
        print(string.format(
            "[spellforge][menu.settings][WARN] SPELLFORGE_UI_SETTINGS_UNAVAILABLE reason=interfaces_settings_missing settings_type=%s registerPage_type=%s registerGroup_type=%s",
            type(settings),
            type(settings and settings.registerPage),
            type(settings and settings.registerGroup)
        ))
        return
    end

    local ok_page, page_err = registerPage(settings)
    if not ok_page then
        print("[spellforge][menu.settings][WARN] SPELLFORGE_UI_SETTINGS_PAGE_REGISTER_FAILED reason=" .. tostring(page_err))
        return
    end

    local ok_group, group_err = registerGroup(settings)
    if not ok_group then
        print("[spellforge][menu.settings][WARN] SPELLFORGE_UI_SETTINGS_GROUP_REGISTER_FAILED reason=" .. tostring(group_err))
        return
    end

    print("[spellforge][menu.settings][INFO] SPELLFORGE_UI_SETTINGS_REGISTERED page=Spellforge group=SettingsPlayerSpellforge key=ui_size")
end

registerSettings()

return {}
