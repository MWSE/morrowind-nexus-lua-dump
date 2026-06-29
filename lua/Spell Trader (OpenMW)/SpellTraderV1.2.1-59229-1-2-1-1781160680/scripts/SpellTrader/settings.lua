local I = require('openmw.interfaces')
local async = require('openmw.async')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')

local l10nContext = 'SpellTrader'
local l10n = core.l10n(l10nContext)
local v2 = util.vector2

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function gmstColor(key, fallback)
    local value = core.getGMST(key)
    if type(value) == 'string' then
        local parts = {}
        for part in value:gmatch('[^,]+') do
            parts[#parts + 1] = tonumber(part:match('^%s*(.-)%s*$'))
        end
        if #parts >= 3 and parts[1] and parts[2] and parts[3] then
            local alpha = parts[4] or 255
            return util.color.rgba(
                clamp(parts[1], 0, 255) / 255,
                clamp(parts[2], 0, 255) / 255,
                clamp(parts[3], 0, 255) / 255,
                clamp(alpha, 0, 255) / 255)
        end
    end
    return fallback
end

local function paddedBox(layout)
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content { layout },
            },
        },
    }
end

I.Settings.registerRenderer('SpellTrader/resetSeenSpells', function(value, set)
    local token = type(value) == 'number' and value or 0
    return paddedBox {
        template = I.MWUI.templates.textNormal,
        props = {
            text = l10n('ResetSeenSpellsButton'),
            size = v2(120, 0),
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
        },
        events = {
            mouseClick = async:callback(function()
                set(token + 1)
            end),
        },
    }
end)

I.Settings.registerPage {
    key = 'SpellTrader',
    l10n = l10nContext,
    name = l10n('SettingsPageName'),
    description = l10n('SettingsPageDescription'),
}

I.Settings.registerGroup {
    key = 'Settings/SpellTrader/1_General',
    page = 'SpellTrader',
    l10n = l10nContext,
    name = l10n('SettingsGroupGeneralName'),
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = 'EnableMod',
            renderer = 'checkbox',
            name = l10n('SettingEnableModName'),
            description = l10n('SettingEnableModDescription'),
            default = true,
        },
        {
            key = 'ShowIcons',
            renderer = 'checkbox',
            name = l10n('SettingShowIconsName'),
            description = l10n('SettingShowIconsDescription'),
            default = true,
        },
        {
            key = 'HighlightUnknownSpells',
            renderer = 'checkbox',
            name = l10n('SettingHighlightUnknownSpellsName'),
            description = l10n('SettingHighlightUnknownSpellsDescription'),
            default = true,
        },
        {
            key = 'HighlightUnknownSpellColor',
            renderer = 'color',
            name = l10n('SettingHighlightUnknownSpellColorName'),
            description = l10n('SettingHighlightUnknownSpellColorDescription'),
            default = gmstColor('FontColor_color_link', util.color.rgb(0.45, 0.55, 1)),
        },
        {
            key = 'MarkNewSpells',
            renderer = 'checkbox',
            name = l10n('SettingMarkNewSpellsName'),
            description = l10n('SettingMarkNewSpellsDescription'),
            default = false,
        },
        {
            key = 'NewSpellSeenDelay',
            renderer = 'number',
            name = l10n('SettingNewSpellSeenDelayName'),
            description = l10n('SettingNewSpellSeenDelayDescription'),
            default = 0.5,
            argument = {
                min = 0,
                max = 2,
            },
        },
        {
            key = 'ResetSeenSpells',
            renderer = 'SpellTrader/resetSeenSpells',
            name = l10n('SettingResetSeenSpellsName'),
            description = l10n('SettingResetSeenSpellsDescription'),
            default = 0,
        },
        {
            key = 'AllowWindowDrag',
            renderer = 'checkbox',
            name = l10n('SettingAllowWindowDragName'),
            description = l10n('SettingAllowWindowDragDescription'),
            default = true,
        },
        {
            key = 'AllowWindowResize',
            renderer = 'checkbox',
            name = l10n('SettingAllowWindowResizeName'),
            description = l10n('SettingAllowWindowResizeDescription'),
            default = true,
        },
        {
            key = 'ShowSortButtons',
            renderer = 'checkbox',
            name = l10n('SettingShowSortButtonsName'),
            description = l10n('SettingShowSortButtonsDescription'),
            default = false,
        },
        {
            key = 'ShowSearch',
            renderer = 'checkbox',
            name = l10n('SettingShowSearchName'),
            description = l10n('SettingShowSearchDescription'),
            default = false,
        },
        {
            key = 'ConfirmPurchase',
            renderer = 'checkbox',
            name = l10n('SettingConfirmPurchaseName'),
            description = l10n('SettingConfirmPurchaseDescription'),
            default = false,
        },
    },
}
