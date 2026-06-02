local M = {
    hud = {
        defaultIconSize = 32,
        defaultIconSpacing = 4,
        paddingX = 14,
        paddingY = 14,
    },
    scanPrefixes = {
        food = 'database',
        thirst = 'database',
    },
    needBarTextures = {
        fill = 'icons/progressbar-fill.png',
        overlayHorizontal = 'icons/progressbar-container.png',
        overlayVertical = 'icons/progressbar-container-v.png',
    },
}

function M.createHudConfig(deps)
    local util = assert(deps.util)
    local playerConfig = assert(deps.playerConfig)
    local temperature = assert(deps.temperature)
    local hungerFlashIconKeys = assert(deps.hungerFlashIconKeys)
    local thirstFlashIconKeys = assert(deps.thirstFlashIconKeys)

    local iconPaths = {
        need_bar_fill_texture = playerConfig.needBarTextures.fill or 'icons/progressbar-fill.png',
        need_bar_empty_texture = 'icons/progressbar-empty-black.png',
        need_bar_overlay_texture_h = playerConfig.needBarTextures.overlayHorizontal or 'icons/progressbar-container.png',
        need_bar_overlay_texture_v = playerConfig.needBarTextures.overlayVertical or 'icons/progressbar-container-v.png',
        hunger_0 = 'icons/hunger-0.png',
        hunger_1 = 'icons/hunger-1.png',
        hunger_2 = 'icons/hunger-2.png',
        hunger_3 = 'icons/hunger-3.png',
        hunger_4 = 'icons/hunger-4.png',
        hunger_0_flash = 'icons/flash/hunger-0-flash.png',
        hunger_1_flash = 'icons/flash/hunger-1-flash.png',
        hunger_2_flash = 'icons/flash/hunger-2-flash.png',
        hunger_3_flash = 'icons/flash/hunger-3-flash.png',
        hunger_4_flash = 'icons/flash/hunger-4-flash.png',
        hunger_neutral_flash = 'icons/flash/hunger-neutral-flash.png',
        thirst_0 = 'icons/thirst-0.png',
        thirst_1 = 'icons/thirst-1.png',
        thirst_2 = 'icons/thirst-2.png',
        thirst_3 = 'icons/thirst-3.png',
        thirst_4 = 'icons/thirst-4.png',
        thirst_0_flash = 'icons/flash/thirst-0-flash.png',
        thirst_1_flash = 'icons/flash/thirst-1-flash.png',
        thirst_neutral_flash = 'icons/flash/thirst-neutral-flash.png',
        thirst_3_flash = 'icons/flash/thirst-3-flash.png',
        thirst_4_flash = 'icons/flash/thirst-4-flash.png',
        sleep_0 = 'icons/sleep-0.png',
        sleep_1 = 'icons/sleep-1.png',
        sleep_2 = 'icons/sleep-2.png',
        sleep_3 = 'icons/sleep-3.png',
        sleep_4 = 'icons/sleep-4.png',
        hunger_neutral = 'icons/hunger-neutral.png',
        thirst_neutral = 'icons/thirst-neutral.png',
        sleep_neutral = 'icons/sleep-neutral.png',
        frame_thick = 'icons/frame-thick.png',
    }
    for iconKey, iconPath in pairs(temperature.system.ICON_PATHS) do
        iconPaths[iconKey] = iconPath
    end

    return {
        rawValueTextSize = 12,
        rawValueTextHeight = 14,
        needBarHeightRatio = 0.125,
        minNeedBarHeight = 2,
        needBarOffsetPixels = 1,
        iconFadeInSeconds = 0.45,
        iconFadeOutSeconds = 0.45,
        hudPadding = util.vector2(
            tonumber(playerConfig.hud.paddingX) or 14,
            tonumber(playerConfig.hud.paddingY) or 14
        ),
        defaultHudPosition = util.vector2(1, 0),
        -- Throttle full HUD destroy/recreate to reduce frame-time spikes.
        hudDynamicRebuildIntervalSeconds = 1 / 12,
        needNeutralIconKeys = {
            hunger = 'hunger_neutral',
            thirst = 'thirst_neutral',
            sleep = 'sleep_neutral',
            temperature = 'temp_neutral',
        },
        needNeutralFlashSourceIconKeys = {
            hunger = 'hunger_neutral',
            thirst = 'thirst_neutral',
            sleep = nil,
            temperature = nil,
        },
        iconPaths = iconPaths,
        hungerFlashIconKeys = hungerFlashIconKeys,
        thirstFlashIconKeys = thirstFlashIconKeys,
    }
end

return M
