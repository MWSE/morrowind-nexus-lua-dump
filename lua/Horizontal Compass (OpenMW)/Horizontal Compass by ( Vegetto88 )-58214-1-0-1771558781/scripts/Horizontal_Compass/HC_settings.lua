local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local storage = require('openmw.storage')
local async = require('openmw.async')

local layerId = ui.layers.indexOf("HUD")
local hudLayerSize = ui.layers[layerId].size

local settingsGroupKey = "Settings" .. MODNAME

I.Settings.registerPage {
    key = MODNAME,
    l10n = "none",
    name = "Horizontal Compass",
    description = "A horizontal compass HUD element.\n- Click and drag to move the position.\n- Mousewheel while dragging to change scale.",
}

local settingsTemplate = {
    key = settingsGroupKey,
    page = MODNAME,
    l10n = "none",
    name = "Compass Settings                                            ", -- lol
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = "HOTKEY_HC_TOGGLE",
            renderer = "inputBinding",
            name = "Toggle compass visibility",
            description = "Click and press a key to bind a toggle hotkey",
            default = "",
            argument = { type = "action", key = "hcToggleCompass" },
        },
        {
            key = "HUD_DISPLAY",
            name = "HUD Display",
            description = "When to display the HUD/widget element.",
            default = "Always",
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "none",
                items = { "Always", "Interface Only", "Hide on Interface", "Hide on Dialogue Only", "Never" },
            },
        },
        {
            key = "HUD_LOCK",
            name = "Lock Position",
            description = "Lock the compass position so it can't be accidentally dragged",
            renderer = "checkbox",
            default = false,
        },
        {
            key = "HUD_X_POS",
            name = "X Position",
            description = "",
            renderer = "number",
            integer = true,
            default = math.floor(hudLayerSize.x * 0.064),
        },
        {
            key = "HUD_Y_POS",
            name = "Y Position",
            description = "",
            renderer = "number",
            integer = true,
            default = 0,
        },
        {
            key = "COMPASS_SCALE",
            name = "Scale",
            description = "Scale of the compass.\nDefault is 0.4\nMousewheel while dragging to adjust in-game",
            renderer = "number",
            default = 0.4,
            argument = { min = 0.1, max = 2.0 },
        },

        {
            key = "SHOW_IN_INTERIORS",
            name = "Show in interiors",
            description = "WIP, kinda doesn't work",
            default = "Never",
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "none",
                items = { "Never", "Always" },
            },
        },		
    },
}

I.Settings.registerGroup(settingsTemplate)

local uiSection = storage.playerSection(settingsGroupKey)

_G.compassUiSection = uiSection

-- called on init and when settings change
local function readAllSettings()
    for _, entry in pairs(settingsTemplate.settings) do
        local val = uiSection:get(entry.key)
        if val == nil then val = entry.default end
        _G[entry.key] = val
    end
end

readAllSettings()

uiSection:subscribe(async:callback(function(_, setting)
    if not setting then return end
    local oldValue = _G[setting]
    _G[setting] = uiSection:get(setting)

    -- update compass dimensions in-place when scale changes
    if setting == "COMPASS_SCALE" and compassHud and updateCompassScale then
        updateCompassScale()
        return
    end

    -- update position
    if (setting == "HUD_X_POS" or setting == "HUD_Y_POS") and compassHud then
        compassHud.layout.props.position = util.vector2(HUD_X_POS, HUD_Y_POS)
        compassHud:update()
        return
    end

    if setting == "HUD_LOCK" and compassHud then
        compassHud.layout.layer = HUD_LOCK and 'Scene' or 'Modal'
        compassHud:update()
        return
    end

    -- refresh visibility for HUD_DISPLAY changes
    if refreshCompassVisibility then
        refreshCompassVisibility()
    end
end))