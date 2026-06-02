local ui = require('openmw.ui')
local util = require('openmw.util')
local wetnessSystem = require('scripts.survivalmode.temperature.wetnessSystem')
local playerConfig = require('scripts.survivalmode.player.playerConfig')

local WETNESS_FADE_IN_SECONDS = 0.4
local WETNESS_FADE_OUT_SECONDS = 5.0
local WETNESS_FILL_TEXTURE_PATH = 'icons/progressbar-fill-wetness.png'
local WETNESS_EMPTY_TEXTURE_PATH = 'icons/progressbar-empty-black.png'
local WETNESS_OVERLAY_VERTICAL_TEXTURE_PATH = playerConfig.needBarTextures.overlayVertical or 'icons/progressbar-container-v.png'
local WETNESS_OVERLAY_HORIZONTAL_TEXTURE_PATH = playerConfig.needBarTextures.overlayHorizontal or 'icons/progressbar-container.png'

local state = {
    alpha = 0,
    wetness = 0,
    fillTexture = nil,
    emptyTexture = nil,
    overlayVerticalTexture = nil,
    overlayHorizontalTexture = nil,
}

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function round(value)
    local numeric = tonumber(value) or 0
    if numeric >= 0 then
        return math.floor(numeric + 0.5)
    end
    return math.ceil(numeric - 0.5)
end

local function ensureTextures()
    if state.fillTexture == nil then
        state.fillTexture = ui.texture({
            path = WETNESS_FILL_TEXTURE_PATH,
        })
    end
    if state.emptyTexture == nil then
        state.emptyTexture = ui.texture({
            path = WETNESS_EMPTY_TEXTURE_PATH,
        })
    end
    if state.overlayVerticalTexture == nil then
        state.overlayVerticalTexture = ui.texture({
            path = WETNESS_OVERLAY_VERTICAL_TEXTURE_PATH,
        })
    end
    if state.overlayHorizontalTexture == nil then
        state.overlayHorizontalTexture = ui.texture({
            path = WETNESS_OVERLAY_HORIZONTAL_TEXTURE_PATH,
        })
    end
end

local function setWetnessValue(value)
    state.wetness = clamp(tonumber(value) or 0, 0, tonumber(wetnessSystem.WETNESS_MAX) or 100)
end

local function getWetnessBarWidget(iconSize, thickness, orientation)
    ensureTextures()

    local orientationKey = tostring(orientation or 'vertical')
    local useVertical = orientationKey ~= 'horizontal'
    local fillResource = state.fillTexture
    local maxWetness = math.max(1, tonumber(wetnessSystem.WETNESS_MAX) or 100)
    local wetnessProgress = clamp(state.wetness / maxWetness, 0, 1)
    local alpha = clamp(state.alpha, 0, 1)
    local layers = {}

    if useVertical then
        local fillHeight = math.floor((iconSize * wetnessProgress) + 0.5)
        fillHeight = clamp(fillHeight, 0, iconSize)

        table.insert(layers, {
            type = ui.TYPE.Image,
            props = {
                resource = state.emptyTexture,
                size = util.vector2(thickness, iconSize),
                alpha = alpha,
            },
        })

        if fillHeight > 0 then
            table.insert(layers, {
                type = ui.TYPE.Image,
                props = {
                    resource = fillResource,
                    size = util.vector2(thickness, fillHeight),
                    relativePosition = util.vector2(0, 1),
                    anchor = util.vector2(0, 1),
                    alpha = alpha,
                },
            })
        end

        table.insert(layers, {
            type = ui.TYPE.Image,
            props = {
                resource = state.overlayVerticalTexture,
                size = util.vector2(thickness, iconSize),
                alpha = alpha,
            },
        })

        return {
            type = ui.TYPE.Widget,
            props = {
                size = util.vector2(thickness, iconSize),
            },
            content = ui.content(layers),
        }
    end

    local fillWidth = math.floor((iconSize * wetnessProgress) + 0.5)
    fillWidth = clamp(fillWidth, 0, iconSize)
    table.insert(layers, {
        type = ui.TYPE.Image,
        props = {
            resource = state.emptyTexture,
            size = util.vector2(iconSize, thickness),
            alpha = alpha,
        },
    })
    if fillWidth > 0 then
        table.insert(layers, {
            type = ui.TYPE.Image,
            props = {
                resource = fillResource,
                size = util.vector2(fillWidth, thickness),
                alpha = alpha,
            },
        })
    end

    table.insert(layers, {
        type = ui.TYPE.Image,
        props = {
            resource = state.overlayHorizontalTexture,
            size = util.vector2(iconSize, thickness),
            alpha = alpha,
        },
    })

    return {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(iconSize, thickness),
        },
        content = ui.content(layers),
    }
end

local function hasVisibleBar()
    return clamp(state.alpha, 0, 1) > 0
end

local function update(dt)
    local step = tonumber(dt) or 0
    if step < 0 then
        step = 0
    end

    if state.wetness > 0 then
        if step <= 0 and state.alpha <= 0 then
            state.alpha = 1
            return
        end

        state.alpha = clamp(
            state.alpha + (step / math.max(0.01, WETNESS_FADE_IN_SECONDS)),
            0,
            1
        )
        return
    end

    if step <= 0 then
        state.alpha = 0
        return
    end

    state.alpha = clamp(
        state.alpha - (step / math.max(0.01, WETNESS_FADE_OUT_SECONDS)),
        0,
        1
    )
end

local function reset()
    state.alpha = 0
    state.wetness = 0
end

local function getSignatureToken()
    return table.concat({
        tostring(round(state.wetness)),
        tostring(round(clamp(state.alpha, 0, 1) * 1000)),
    }, ':')
end

return {
    setWetnessValue = setWetnessValue,
    update = update,
    reset = reset,
    getSignatureToken = getSignatureToken,
    hasVisibleBar = hasVisibleBar,
    buildBarWidget = getWetnessBarWidget,
}
