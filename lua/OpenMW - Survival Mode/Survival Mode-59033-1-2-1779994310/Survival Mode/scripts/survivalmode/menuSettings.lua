local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local markTexture = ui.texture({ path = 'textures/menu_map_smark.dds' })
local GRID_STEP_COUNT = 300
local GRID_SIZE = util.vector2(100, 100)
local MARKER_SIZE = util.vector2(20, 20)

local function snapToGrid(value)
    local snapped = math.floor((value * GRID_STEP_COUNT) + 0.5) / GRID_STEP_COUNT
    return util.clamp(snapped, 0, 1)
end

I.Settings.registerRenderer('SurvivalNeedsScreenPosition', function(value, set)
    if value == nil then
        value = util.vector2(1, 0)
    end

    local snappedValue = util.vector2(
        snapToGrid(value.x),
        snapToGrid(value.y)
    )

    local update = async:callback(function(e)
        if e.button ~= 1 then
            return
        end

        local relativeOffset = (e.offset - MARKER_SIZE / 2):ediv(GRID_SIZE)
        local clampedOffset = util.vector2(
            util.clamp(relativeOffset.x, 0, 1),
            util.clamp(relativeOffset.y, 0, 1)
        )
        local snappedOffset = util.vector2(
            snapToGrid(clampedOffset.x),
            snapToGrid(clampedOffset.y)
        )

        set(snappedOffset)
    end)

    return {
        template = I.MWUI.templates.box,
        content = ui.content({
            {
                props = {
                    size = GRID_SIZE + MARKER_SIZE,
                },
                content = ui.content({
                    {
                        template = I.MWUI.templates.borders,
                        props = {
                            anchor = snappedValue,
                            relativePosition = snappedValue,
                            size = MARKER_SIZE,
                        },
                        content = ui.content({
                            {
                                type = ui.TYPE.Image,
                                props = {
                                    resource = markTexture,
                                    relativeSize = util.vector2(1, 1),
                                    color = util.color.rgb(202 / 255, 165 / 255, 96 / 255),
                                },
                            },
                        }),
                    },
                }),
                events = {
                    mouseMove = update,
                    mousePress = update,
                },
            },
        }),
    }
end)

I.Settings.registerPage({
    key = 'SurvivalNeeds',
    l10n = 'SurvivalMode',
    name = 'page_name',
    description = 'page_description',
})

I.Settings.registerGroup({
    key = 'SettingsSurvivalNeedsHUD',
    page = 'SurvivalNeeds',
    l10n = 'SurvivalMode_Settings',
    name = 'group_name',
    permanentStorage = true,
    settings = {
        {
            key = 'enable',
            name = 'enable_name',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'position',
            name = 'position_name',
            default = util.vector2(1, 0),
            renderer = 'SurvivalNeedsScreenPosition',
        },
        {
            key = 'offsetX',
            name = 'offset_x_name',
            default = 0,
            renderer = 'number',
            argument = {
                integer = true,
            },
        },
        {
            key = 'offsetY',
            name = 'offset_y_name',
            default = 0,
            renderer = 'number',
            argument = {
                integer = true,
            },
        },
        {
            key = 'iconOrientation',
            name = 'icon_orientation_name',
            default = 'horizontal',
            renderer = 'select',
            argument = {
                l10n = 'SurvivalMode_Settings',
                items = {
                    'horizontal',
                    'vertical',
                },
            },
        },
        {
            key = 'iconSize',
            name = 'icon_size_name',
            default = 32,
            renderer = 'number',
            argument = {
                min = 1,
                integer = true,
            },
        },
        {
            key = 'iconSpacing',
            name = 'icon_spacing_name',
            default = 4,
            renderer = 'number',
            argument = {
                min = 0,
                integer = true,
            },
        },
        {
            key = 'showProgressBars',
            name = 'show_progress_bars_name',
            default = false,
            renderer = 'checkbox',
        },
        {
            key = 'temperatureVerticalProgressBar',
            name = 'temperature_progress_bar_name',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'enableTemperatureEffectOverlay',
            name = 'enable_temperature_effect_overlay_name',
            description = 'enable_temperature_effect_overlay_description',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'progressBarOrientation',
            name = 'progress_bar_orientation_name',
            default = 'vertical',
            renderer = 'select',
            argument = {
                l10n = 'SurvivalMode_Settings',
                items = {
                    'vertical',
                    'horizontal',
                },
            },
        },
        {
            key = 'enableThickerIconFrame',
            name = 'enable_thicker_icon_frame_name',
            default = false,
            renderer = 'checkbox',
        },
        {
            key = 'enableNeutralImages',
            name = 'enable_neutral_images_name',
            description = 'enable_neutral_images_description',
            default = false,
            renderer = 'checkbox',
        },
        {
            key = 'enableStageMessages',
            name = 'enable_stage_messages_name',
            description = 'enable_stage_messages_description',
            default = false,
            renderer = 'checkbox',
        },
        {
            key = 'enableWarmthIndicatorAbility',
            name = 'warmth_indicator_ability_name',
            description = 'warmth_indicator_ability_description',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'statsMenuIndent',
            name = 'stats_menu_indent_name',
            description = 'stats_menu_indent_description',
            default = false,
            renderer = 'checkbox',
        },
        {
            key = 'enableStatsWindowExtenderIntegration',
            name = 'enable_swe_integration_name',
            description = 'enable_swe_integration_description',
            default = true,
            renderer = 'checkbox',
        },
    },
})

I.Settings.registerGroup({
    key = 'SettingsSurvivalNeedsGameplay',
    page = 'SurvivalNeeds',
    l10n = 'SurvivalMode_Settings',
    name = 'gameplay_group_name',
    permanentStorage = true,
    settings = {
        {
            key = 'enableHungerSystem',
            name = 'enable_hunger_system_name',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'enableThirstSystem',
            name = 'enable_thirst_system_name',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'enableSleepSystem',
            name = 'enable_sleep_system_name',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'enableTemperatureSystem',
            name = 'enable_temperature_system_name',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'enableSeasonalTemperatureVariations',
            name = 'seasonal_temperature_variations_name',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'enableTemperatureBasedHealthPenalties',
            name = 'temperature_based_health_penalties_name',
            default = true,
            renderer = 'checkbox',
        },
    },
})

I.Settings.registerGroup({
    key = 'SettingsSurvivalNeedsZZDebug',
    page = 'SurvivalNeeds',
    l10n = 'SurvivalMode_Settings',
    name = 'debug_group_name',
    permanentStorage = true,
    settings = {
        {
            key = 'showRawValues',
            name = 'show_raw_values_name',
            default = false,
            renderer = 'checkbox',
        },
        {
            key = 'enableTemperatureDebugOverlay',
            name = 'temperature_debug_overlay_name',
            default = false,
            renderer = 'checkbox',
        },
        {
            key = 'hbfsDisableConjurationDrain',
            name = 'hbfs_disable_conjuration_drain_name',
            description = 'hbfs_disable_conjuration_drain_description',
            default = true,
            renderer = 'checkbox',
        },
    },
})

return {}
