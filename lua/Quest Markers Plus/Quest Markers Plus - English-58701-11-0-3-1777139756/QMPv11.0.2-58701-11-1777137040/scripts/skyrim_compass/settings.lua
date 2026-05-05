local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local v2 = util.vector2

local barTex = ui.texture { path = "textures/icons/skyrim_compass/bar_white.dds" }

local function hsvToRgb(h, s, v)
    h = (h % 360) / 360
    s = s / 100
    v = v / 100
    if s == 0 then return v, v, v end
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    else return v, p, q end
end

I.Settings.registerRenderer("slider", function(value, set, arg)
    local min = arg and arg.min or 0
    local max = arg and arg.max or 100
    local integer = arg and arg.integer
    local barW = 150
    local barH = 12

    local frac = math.max(0, math.min(1, (value - min) / (max - min)))
    local fillW = math.max(1, math.floor(frac * barW))

    local fillColor
    if arg and arg.hue then
        local r, g, b = hsvToRgb(value, 100, 100)
        fillColor = util.color.rgb(r, g, b)
    else
        fillColor = util.color.rgb(0.72, 0.6, 0.35)
    end

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Widget,
                props = {
                    size = v2(barW, barH),
                    propagateEvents = false,
                },
                events = {
                    mousePress = async:callback(function(e, layout)
                        if e.button ~= 1 then return end
                        local x = e.offset.x
                        local f = math.max(0, math.min(1, x / barW))
                        local nv = min + f * (max - min)
                        if integer then nv = math.floor(nv + 0.5) end
                        set(nv)
                    end),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        props = {
                            position = v2(0, 0),
                            size = v2(barW, barH),
                            resource = barTex,
                            color = util.color.rgb(0.15, 0.15, 0.15),
                        },
                    },
                    {
                        type = ui.TYPE.Image,
                        props = {
                            position = v2(0, 0),
                            size = v2(fillW, barH),
                            resource = barTex,
                            color = fillColor,
                        },
                    },
                },
            },
            {
                type = ui.TYPE.Text,
                props = {
                    text = "  " .. tostring(math.floor(value)),
                    textSize = 14,
                    textColor = util.color.rgb(0.9, 0.85, 0.7),
                },
            },
        },
    }
end)

local SETTINGS_KEY = "SkyrimCompass_Settings"

I.Settings.registerPage {
    key = "SkyrimCompass",
    l10n = "SkyrimCompass",
    name = "compassTitle",
    description = "compassDesc",
}

I.Settings.registerGroup {
    key = SETTINGS_KEY,
    page = "SkyrimCompass",
    l10n = "SkyrimCompass",
    name = "settingsGroup",
    permanentStorage = true,
    settings = {
        {
            key = "compassEnabled",
            renderer = "checkbox",
            name = "compassEnabledName",
            description = "compassEnabledDesc",
            default = true,
        },
        {
            key = "compassBottom",
            renderer = "checkbox",
            name = "compassBottomName",
            description = "compassBottomDesc",
            default = false,
        },
        {
            key = "compassScale",
            renderer = "slider",
            name = "compassScaleName",
            description = "compassScaleDesc",
            default = 100,
            argument = { min = 50, max = 200, integer = true },
        },
        {
            key = "compassAlpha",
            renderer = "slider",
            name = "compassAlphaName",
            description = "compassAlphaDesc",
            default = 30,
            argument = { min = 0, max = 100, integer = true },
        },
        {
            key = "markerAlpha",
            renderer = "slider",
            name = "markerAlphaName",
            description = "markerAlphaDesc",
            default = 100,
            argument = { min = 0, max = 100, integer = true },
        },
        {
            key = "showCityNames",
            renderer = "checkbox",
            name = "showCityNamesName",
            description = "showCityNamesDesc",
            default = true,
        },
        {
            key = "showLocationLabel",
            renderer = "checkbox",
            name = "showLocationLabelName",
            description = "showLocationLabelDesc",
            default = true,
        },
        {
            key = "showDiscovery",
            renderer = "checkbox",
            name = "showDiscoveryName",
            description = "showDiscoveryDesc",
            default = true,
        },
        {
            key = "showWelcomeAgain",
            renderer = "checkbox",
            name = "showWelcomeName",
            description = "showWelcomeDesc",
            default = false,
        },
    },
}

I.Settings.registerGroup {
    key = "SkyrimCompass_QuestColor",
    page = "SkyrimCompass",
    l10n = "SkyrimCompass",
    name = "questColorGroup",
    permanentStorage = true,
    settings = {
        {
            key = "questHue",
            renderer = "slider",
            name = "questHueName",
            description = "questHueDesc",
            default = 0,
            argument = { min = 0, max = 360, integer = true, hue = true },
        },
        {
            key = "questSaturation",
            renderer = "slider",
            name = "questSaturationName",
            description = "questSaturationDesc",
            default = 0,
            argument = { min = 0, max = 100, integer = true },
        },
        {
            key = "questBrightness",
            renderer = "slider",
            name = "questBrightnessName",
            description = "questBrightnessDesc",
            default = 100,
            argument = { min = 0, max = 100, integer = true },
        },
    },
}

I.Settings.registerGroup {
    key = "SkyrimCompass_IconColor",
    page = "SkyrimCompass",
    l10n = "SkyrimCompass",
    name = "iconColorGroup",
    permanentStorage = true,
    settings = {
        {
            key = "iconHue",
            renderer = "slider",
            name = "iconHueName",
            description = "iconHueDesc",
            default = 0,
            argument = { min = 0, max = 360, integer = true, hue = true },
        },
        {
            key = "iconSaturation",
            renderer = "slider",
            name = "iconSaturationName",
            description = "iconSaturationDesc",
            default = 0,
            argument = { min = 0, max = 100, integer = true },
        },
        {
            key = "iconBrightness",
            renderer = "slider",
            name = "iconBrightnessName",
            description = "iconBrightnessDesc",
            default = 100,
            argument = { min = 0, max = 100, integer = true },
        },
    },
}

return {}
