local ui = require('openmw.ui')
local util = require('openmw.util')

local OVERLAY_TEXTURE_PATH = 'icons/cold-overlay.png'
local OVERLAY_LAYER = 'SurvivalModeColdEffect'
local OVERLAY_SIZE_MULTIPLIER = 1.5
local TRANSITION_DURATION_SECONDS = 5.0
local SUSTAIN_FADE_IN_SECONDS = 5.0
local SUSTAIN_FADE_OUT_SECONDS = 0.7
local WARM_EFFECT_MULTIPLIER = 0.5
local COOL_TINT_COLOR = util.color.rgb(0.72, 0.88, 1.0)
local COOL_BURST_COLOR = util.color.rgb(0.86, 0.95, 1.0)
local WARM_TINT_COLOR = util.color.rgb(1.0, 0.70, 0.34)
local WARM_BURST_COLOR = util.color.rgb(1.0, 0.82, 0.56)

local state = {
    stageId = 'neutral',
    previousStageId = nil,
    sustainAlpha = 0,
    transitionTimeRemaining = 0,
    transitionStageId = nil,
    overlayTexture = nil,
    overlayElement = nil,
    signature = nil,
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

local function normalizeStageId(stageId)
    if type(stageId) ~= 'string' then
        return 'neutral'
    end

    local normalized = string.lower(stageId):match('^%s*(.-)%s*$')
    if normalized == '' then
        return 'neutral'
    end
    return normalized
end

local function getStageFamily(stageId)
    if stageId == 'chilly' or stageId == 'cold' or stageId == 'very_cold' or stageId == 'freezing' then
        return 'cool'
    end
    if stageId == 'warm' or stageId == 'hot' or stageId == 'very_hot' or stageId == 'scorching' then
        return 'warm'
    end
    return 'neutral'
end

local function getTargetSustainAlpha(stageId)
    if stageId == 'chilly' then
        return 0.06
    end
    if stageId == 'cold' then
        return 0.12
    end
    if stageId == 'very_cold' then
        return 0.24
    end
    if stageId == 'freezing' then
        return 0.36
    end
    if stageId == 'warm' then
        return 0.06 * WARM_EFFECT_MULTIPLIER
    end
    if stageId == 'hot' then
        return 0.12 * WARM_EFFECT_MULTIPLIER
    end
    if stageId == 'very_hot' then
        return 0.24 * WARM_EFFECT_MULTIPLIER
    end
    if stageId == 'scorching' then
        return 0.36 * WARM_EFFECT_MULTIPLIER
    end
    return 0
end

local function getTransitionStrength(stageId)
    if stageId == 'chilly' then
        return 0.5
    end
    if stageId == 'cold' then
        return 1.0
    end
    if stageId == 'very_cold' then
        return 2.0
    end
    if stageId == 'freezing' then
        return 3.0
    end
    if stageId == 'warm' then
        return 0.5
    end
    if stageId == 'hot' then
        return 1.0
    end
    if stageId == 'very_hot' then
        return 2.0
    end
    if stageId == 'scorching' then
        return 3.0
    end
    return 1.0
end

local function shouldStartTransitionBurst(previousStageId, nextStageId)
    local nextFamily = getStageFamily(nextStageId)
    if nextFamily == 'neutral' then
        return false
    end

    local previousTargetAlpha = getTargetSustainAlpha(previousStageId)
    local nextTargetAlpha = getTargetSustainAlpha(nextStageId)
    return nextTargetAlpha > previousTargetAlpha
end

local function getTintColor(stageId)
    if getStageFamily(stageId) == 'warm' then
        return WARM_TINT_COLOR
    end
    return COOL_TINT_COLOR
end

local function getSustainTintStageId()
    if getStageFamily(state.stageId) ~= 'neutral' then
        return state.stageId
    end
    if state.sustainAlpha > 0.001 and getStageFamily(state.previousStageId) ~= 'neutral' then
        return state.previousStageId
    end
    return state.stageId
end

local function getBurstColor(stageId)
    if getStageFamily(stageId) == 'warm' then
        return WARM_BURST_COLOR
    end
    return COOL_BURST_COLOR
end

local function ensureTexture()
    if state.overlayTexture == nil then
        state.overlayTexture = ui.texture({
            path = OVERLAY_TEXTURE_PATH,
        })
    end
end

local function ensureLayer()
    if ui.layers.indexOf(OVERLAY_LAYER) ~= nil then
        return
    end

    local ok, err = pcall(function()
        ui.layers.insertBefore('HUD', OVERLAY_LAYER, { interactive = false })
    end)

    if not ok then
        print(string.format('[SurvivalMode] Failed to create cold overlay layer: %s', tostring(err)))
    end
end

local function destroyOverlay()
    if state.overlayElement == nil then
        return true
    end

    local overlayElement = state.overlayElement
    local ok, err = pcall(function()
        overlayElement:destroy()
    end)

    if ok then
        state.overlayElement = nil
        return true
    end

    print(string.format('[SurvivalMode] Failed to destroy cold overlay element: %s', tostring(err)))
    return false
end

local function hasVisibleEffect()
    return state.sustainAlpha > 0.001 or state.transitionTimeRemaining > 0.001
end

local function getSignature()
    return table.concat({
        state.stageId,
        tostring(round(clamp(state.sustainAlpha, 0, 1) * 1000)),
        tostring(round(clamp(state.transitionTimeRemaining, 0, TRANSITION_DURATION_SECONDS) * 1000)),
    }, ':')
end

local function setStage(stageId)
    local normalizedStageId = normalizeStageId(stageId)
    local previousStageId = state.stageId
    if previousStageId == normalizedStageId then
        return
    end

    state.previousStageId = previousStageId
    state.stageId = normalizedStageId

    if shouldStartTransitionBurst(previousStageId, normalizedStageId) then
        state.transitionTimeRemaining = TRANSITION_DURATION_SECONDS
        state.transitionStageId = normalizedStageId
    else
        state.transitionTimeRemaining = 0
        state.transitionStageId = nil
    end
end

local function getTransitionAlpha()
    local duration = math.max(0.01, TRANSITION_DURATION_SECONDS)
    local progress = 1 - clamp(state.transitionTimeRemaining / duration, 0, 1)
    local transitionStageId = state.transitionStageId or state.stageId
    return math.sin(progress * math.pi) * 0.18 * getTransitionStrength(transitionStageId)
end

local function update(dt)
    local step = tonumber(dt) or 0
    if step < 0 then
        step = 0
    end

    local targetSustainAlpha = getTargetSustainAlpha(state.stageId)
    local fadeDuration = SUSTAIN_FADE_IN_SECONDS
    if targetSustainAlpha < state.sustainAlpha then
        fadeDuration = SUSTAIN_FADE_OUT_SECONDS
    end

    if step <= 0 then
        state.sustainAlpha = targetSustainAlpha
    elseif targetSustainAlpha > state.sustainAlpha then
        state.sustainAlpha = math.min(
            targetSustainAlpha,
            state.sustainAlpha + (step / math.max(0.01, fadeDuration)) * targetSustainAlpha
        )
    elseif targetSustainAlpha < state.sustainAlpha then
        state.sustainAlpha = math.max(
            targetSustainAlpha,
            state.sustainAlpha - (step / math.max(0.01, fadeDuration)) * math.max(state.sustainAlpha, 0.01)
        )
    end

    if step <= 0 then
        return
    end

    state.transitionTimeRemaining = clamp(
        state.transitionTimeRemaining - step,
        0,
        TRANSITION_DURATION_SECONDS
    )
    if state.transitionTimeRemaining <= 0 then
        state.transitionStageId = nil
    end
end

local function createOverlayImage(color, alpha)
    local multiplier = math.max(1.0, tonumber(OVERLAY_SIZE_MULTIPLIER) or 1.0)
    local offset = -(multiplier - 1.0) * 0.5

    return {
        type = ui.TYPE.Image,
        props = {
            resource = state.overlayTexture,
            relativeSize = util.vector2(multiplier, multiplier),
            relativePosition = util.vector2(offset, offset),
            color = color,
            alpha = clamp(alpha, 0, 1),
            propagateEvents = false,
        },
    }
end

local function refresh()
    if not hasVisibleEffect() then
        state.signature = nil
        destroyOverlay()
        return
    end

    local signature = getSignature()
    if signature == state.signature and state.overlayElement ~= nil then
        return
    end

    if not destroyOverlay() then
        state.signature = nil
        return
    end

    ensureTexture()
    ensureLayer()
    state.signature = signature

    local tintColor = getTintColor(getSustainTintStageId())
    local transitionStageId = state.transitionStageId or state.stageId
    local burstColor = getBurstColor(transitionStageId)

    local layers = {
        createOverlayImage(tintColor, state.sustainAlpha),
    }

    local transitionAlpha = getTransitionAlpha()
    if transitionAlpha > 0.001 then
        table.insert(layers, createOverlayImage(burstColor, transitionAlpha))
    end

    state.overlayElement = ui.create({
        layer = OVERLAY_LAYER,
        type = ui.TYPE.Widget,
        props = {
            relativeSize = util.vector2(1, 1),
            propagateEvents = false,
        },
        content = ui.content(layers),
    })
end

local function sync(stageId, dt)
    setStage(stageId)
    update(dt)
    refresh()
end

local function reset()
    state.stageId = 'neutral'
    state.previousStageId = nil
    state.sustainAlpha = 0
    state.transitionTimeRemaining = 0
    state.transitionStageId = nil
    state.signature = nil
    destroyOverlay()
end

return {
    reset = reset,
    sync = sync,
    setStage = setStage,
    update = update,
    refresh = refresh,
}