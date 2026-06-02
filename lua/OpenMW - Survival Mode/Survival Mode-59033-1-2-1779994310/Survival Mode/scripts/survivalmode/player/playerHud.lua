local M = {}
local core = require('openmw.core')

function M.createController(deps)
    local state = assert(deps.state)
    local ui = assert(deps.ui)
    local clamp = assert(deps.clamp)
    local normalizeKey = assert(deps.normalizeKey)
    local trim = assert(deps.trim)
    local iconPaths = assert(deps.iconPaths)
    local iconFadeInSeconds = assert(deps.iconFadeInSeconds)
    local iconFadeOutSeconds = assert(deps.iconFadeOutSeconds)
    local hungerFlashDurationSeconds = assert(deps.hungerFlashDurationSeconds)
    local hungerFlashFadeInRatio = assert(deps.hungerFlashFadeInRatio)
    local thirstFlashDurationSeconds = assert(deps.thirstFlashDurationSeconds)
    local thirstFlashFadeInRatio = assert(deps.thirstFlashFadeInRatio)
    local wellRestedStageId = assert(deps.wellRestedStageId)
    local minNegative = -math.huge

    local function createNeedZeroMap()
        return {
            hunger = 0,
            thirst = 0,
            sleep = 0,
            temperature = 0,
        }
    end

    local function createNeedNilMap()
        return {
            hunger = nil,
            thirst = nil,
            sleep = nil,
            temperature = nil,
        }
    end

    local lastHudRealTime = nil

    local function getHudVisualStep(dt)
        if type(core.getRealFrameDuration) == 'function' then
            local ok, value = pcall(core.getRealFrameDuration)
            if ok then
                local realStep = tonumber(value) or 0
                if realStep > 0 then
                    return math.min(realStep, 0.25)
                end
            end
        end

        if type(core.getRealTime) == 'function' then
            local ok, value = pcall(core.getRealTime)
            if ok then
                local currentTime = tonumber(value)
                if currentTime ~= nil then
                    local previousTime = tonumber(lastHudRealTime)
                    lastHudRealTime = currentTime
                    if previousTime ~= nil then
                        local realStep = currentTime - previousTime
                        if realStep > 0 then
                            return math.min(realStep, 0.25)
                        end
                    end
                end
            end
        end

        return tonumber(dt) or 0
    end

    local function updateFlashTimer(remaining, step)
        local timeRemaining = tonumber(remaining) or 0
        if timeRemaining <= 0 then
            return 0
        end

        step = tonumber(step) or 0
        if step <= 0 then
            return timeRemaining
        end

        return math.max(0, timeRemaining - step)
    end

    local function getFlashAlpha(remaining, durationSeconds, fadeInRatioValue)
        if remaining <= 0 then
            return 0
        end

        local duration = tonumber(durationSeconds) or 0
        duration = math.max(0.01, duration)
        local progress = 1 - (remaining / duration)
        progress = clamp(progress, 0, 1)

        local fadeInRatio = clamp(tonumber(fadeInRatioValue) or 0.25, 0.01, 0.99)
        if progress < fadeInRatio then
            return progress / fadeInRatio
        end

        local fadeOutProgress = (progress - fadeInRatio) / (1 - fadeInRatio)
        return clamp(1 - fadeOutProgress, 0, 1)
    end

    local api = {}

    function api.initializeState()
        if type(state.iconResources) ~= 'table' then
            state.iconResources = {}
        end
        if type(state.hudElement) == 'nil' then
            state.hudElement = nil
        end
        if type(state.hudSignature) == 'nil' then
            state.hudSignature = nil
        end
        if type(state.hudLayoutSignature) == 'nil' then
            state.hudLayoutSignature = nil
        end
        if tonumber(state.lastHudRebuildTime) == nil then
            state.lastHudRebuildTime = minNegative
        end
        if tonumber(state.hungerFlashTimeRemaining) == nil then
            state.hungerFlashTimeRemaining = 0
        end
        if tonumber(state.thirstFlashTimeRemaining) == nil then
            state.thirstFlashTimeRemaining = 0
        end
        if type(state.iconFadeTimeRemaining) ~= 'table' then
            state.iconFadeTimeRemaining = createNeedZeroMap()
        end
        if type(state.iconFadeOutTimeRemaining) ~= 'table' then
            state.iconFadeOutTimeRemaining = createNeedZeroMap()
        end
        if type(state.lastNeedIcons) ~= 'table' then
            state.lastNeedIcons = createNeedNilMap()
        end
        if type(state.leavingNeedIcons) ~= 'table' then
            state.leavingNeedIcons = createNeedNilMap()
        end
    end

    function api.resetNeedIconState(needId)
        if type(needId) ~= 'string' or needId == '' then
            return
        end
        state.iconFadeTimeRemaining[needId] = 0
        state.iconFadeOutTimeRemaining[needId] = 0
        state.lastNeedIcons[needId] = nil
        state.leavingNeedIcons[needId] = nil
    end

    function api.resetNeedFlashState(needId)
        local normalized = normalizeKey(needId)
        if normalized == 'hunger' then
            state.hungerFlashTimeRemaining = 0
        elseif normalized == 'thirst' then
            state.thirstFlashTimeRemaining = 0
        end
    end

    function api.resetTransientState()
        state.hungerFlashTimeRemaining = 0
        state.thirstFlashTimeRemaining = 0
        state.iconFadeTimeRemaining = createNeedZeroMap()
        state.iconFadeOutTimeRemaining = createNeedZeroMap()
        state.lastNeedIcons = createNeedNilMap()
        state.leavingNeedIcons = createNeedNilMap()
        api.invalidateHud()
    end

    function api.invalidateHud()
        state.hudSignature = nil
    end

    function api.ensureIconResources()
        for iconKey, iconPath in pairs(iconPaths) do
            if state.iconResources[iconKey] == nil then
                state.iconResources[iconKey] = ui.texture({ path = iconPath })
            end
        end
    end

    function api.getNeedIcons(hungerStage, thirstStage, sleepStage, temperatureStage, allowThirstFlashFallback)
        local icons = {
            hunger = nil,
            thirst = nil,
            sleep = nil,
            temperature = nil,
        }

        if type(hungerStage) == 'table' and hungerStage.hungerIconKey ~= nil then
            icons.hunger = hungerStage.hungerIconKey
        elseif allowThirstFlashFallback and state.hungerFlashTimeRemaining > 0 then
            -- Keep flash visible briefly even after eating resets hunger below icon threshold.
            -- Use neutral source so satisfied-stage consumes show the neutral flash variant.
            icons.hunger = 'hunger_neutral'
        end

        if type(thirstStage) == 'table' and thirstStage.thirstIconKey ~= nil then
            icons.thirst = thirstStage.thirstIconKey
        elseif allowThirstFlashFallback and state.thirstFlashTimeRemaining > 0 then
            -- Keep flash visible briefly even after a drink resets thirst below icon threshold.
            -- Use neutral source so hydrated-stage consumes show the neutral flash variant.
            icons.thirst = 'thirst_neutral'
        end

        if type(sleepStage) == 'table'
            and sleepStage.sleepIconKey ~= nil
            and (
                normalizeKey(sleepStage.id) ~= wellRestedStageId
                or state.sleepWellRestedBonusEligible == true
            ) then
            icons.sleep = sleepStage.sleepIconKey
        end

        if type(temperatureStage) == 'table' and temperatureStage.temperatureIconKey ~= nil then
            icons.temperature = temperatureStage.temperatureIconKey
        end

        return icons
    end

    function api.updateNeedFlashes(dt)
        local step = getHudVisualStep(dt)
        state.hungerFlashTimeRemaining = updateFlashTimer(state.hungerFlashTimeRemaining, step)
        state.thirstFlashTimeRemaining = updateFlashTimer(state.thirstFlashTimeRemaining, step)
    end

    function api.updateNeedIconFades(dt)
        local step = getHudVisualStep(dt)
        if step > 0 then
            step = math.min(step, 1 / 30)
        end

        for needId, _ in pairs(state.iconFadeTimeRemaining) do
            local remaining = state.iconFadeTimeRemaining[needId] or 0
            if remaining <= 0 then
                state.iconFadeTimeRemaining[needId] = 0
            elseif step <= 0 then
                state.iconFadeTimeRemaining[needId] = remaining
            else
                state.iconFadeTimeRemaining[needId] = math.max(0, remaining - step)
            end

            local fadeOutRemaining = state.iconFadeOutTimeRemaining[needId] or 0
            local updatedFadeOut = fadeOutRemaining
            if fadeOutRemaining <= 0 then
                updatedFadeOut = 0
            elseif step > 0 then
                updatedFadeOut = math.max(0, fadeOutRemaining - step)
            end
            state.iconFadeOutTimeRemaining[needId] = updatedFadeOut
            if updatedFadeOut <= 0 then
                state.leavingNeedIcons[needId] = nil
            end
        end
    end

    function api.syncNeedIconFadeState(icons)
        for _, needId in ipairs({ 'hunger', 'thirst', 'sleep', 'temperature' }) do
            local previousIcon = state.lastNeedIcons[needId]
            local currentIcon = icons[needId]
            if previousIcon ~= currentIcon then
                local fadeInDuration = iconFadeInSeconds
                local fadeOutDuration = iconFadeOutSeconds
                if needId == 'temperature' then
                    fadeInDuration = iconFadeInSeconds * 1.75
                    fadeOutDuration = iconFadeOutSeconds * 1.75
                end

                if previousIcon ~= nil then
                    state.leavingNeedIcons[needId] = previousIcon
                    state.iconFadeOutTimeRemaining[needId] = fadeOutDuration
                else
                    state.leavingNeedIcons[needId] = nil
                    state.iconFadeOutTimeRemaining[needId] = 0
                end

                state.lastNeedIcons[needId] = currentIcon
                if currentIcon ~= nil then
                    state.iconFadeTimeRemaining[needId] = fadeInDuration
                else
                    state.iconFadeTimeRemaining[needId] = 0
                end
            end
        end
    end

    function api.getNeedIconAlpha(needId)
        local remaining = state.iconFadeTimeRemaining[needId] or 0
        if remaining <= 0 then
            return 1
        end

        local duration = iconFadeInSeconds
        if needId == 'temperature' then
            duration = iconFadeInSeconds * 1.75
        end
        duration = math.max(0.01, duration)
        local progress = 1 - (remaining / duration)
        progress = (progress * progress) * (3 - (2 * progress))
        return clamp(progress, 0, 1)
    end

    function api.getNeedLeavingIconAlpha(needId)
        local remaining = state.iconFadeOutTimeRemaining[needId] or 0
        if remaining <= 0 then
            return 0
        end

        local duration = iconFadeOutSeconds
        if needId == 'temperature' then
            duration = iconFadeOutSeconds * 1.75
        end
        duration = math.max(0.01, duration)
        local progress = 1 - (remaining / duration)
        progress = (progress * progress) * (3 - (2 * progress))
        return clamp(1 - progress, 0, 1)
    end

    function api.getHungerFlashAlpha()
        return getFlashAlpha(state.hungerFlashTimeRemaining, hungerFlashDurationSeconds, hungerFlashFadeInRatio)
    end

    function api.getThirstFlashAlpha()
        return getFlashAlpha(state.thirstFlashTimeRemaining, thirstFlashDurationSeconds, thirstFlashFadeInRatio)
    end

    function api.subscribeSettings(args)
        local async = assert(args.async)
        local hudSettings = assert(args.hudSettings)
        local settingsSections = assert(args.settingsSections)
        local syncDebugLoggingState = assert(args.syncDebugLoggingState)
        local updateSystems = assert(args.updateSystems)
        state.runHudFrameUpdate = updateSystems

        hudSettings:subscribe(async:callback(function()
            api.invalidateHud()
            syncDebugLoggingState(false)
            updateSystems()
        end))

        settingsSections.gameplay:subscribe(async:callback(function()
            api.invalidateHud()
            updateSystems()
        end))

        settingsSections.debug:subscribe(async:callback(function()
            api.invalidateHud()
            syncDebugLoggingState(false)
            updateSystems()
        end))
    end

    return api
end

function M.create(deps)
    local state = assert(deps.state)
    local ui = assert(deps.ui)
    local util = assert(deps.util)
    local TEMPERATURE_DEBUG = assert(deps.temperatureDebug)
    local hudSettings = assert(deps.hudSettings)
    local now = assert(deps.now)
    local round = assert(deps.round)
    local clamp = assert(deps.clamp)
    local normalizeKey = assert(deps.normalizeKey)
    local ensureIconResources = assert(deps.ensureIconResources)
    local isHorizontal = assert(deps.isHorizontal)
    local isHudEnabled = assert(deps.isHudEnabled)
    local isRawValuesDebugEnabled = assert(deps.isRawValuesDebugEnabled)
    local areProgressBarsEnabled = assert(deps.areProgressBarsEnabled)
    local isNeutralImagesSettingEnabled = assert(deps.isNeutralImagesSettingEnabled)
    local isThickerIconFrameEnabled = assert(deps.isThickerIconFrameEnabled)
    local isHungerSystemEnabled = assert(deps.isHungerSystemEnabled)
    local isThirstSystemEnabled = assert(deps.isThirstSystemEnabled)
    local isSleepSystemEnabled = assert(deps.isSleepSystemEnabled)
    local isTemperatureSystemEnabled = assert(deps.isTemperatureSystemEnabled)
    local getNeedIcons = assert(deps.getNeedIcons)
    local syncNeedIconFadeState = assert(deps.syncNeedIconFadeState)
    local getHudPosition = assert(deps.getHudPosition)
    local getHudOffsetX = assert(deps.getHudOffsetX)
    local getHudOffsetY = assert(deps.getHudOffsetY)
    local getIconSizeValue = assert(deps.getIconSizeValue)
    local getIconSpacingValue = assert(deps.getIconSpacingValue)
    local getHungerFlashAlpha = assert(deps.getHungerFlashAlpha)
    local getThirstFlashAlpha = assert(deps.getThirstFlashAlpha)
    local getNeedIconAlpha = assert(deps.getNeedIconAlpha)
    local getNeedLeavingIconAlpha = assert(deps.getNeedLeavingIconAlpha)
    local getStageProgressNormalized = assert(deps.getStageProgressNormalized)
    local NEED_NEUTRAL_ICON_KEYS = assert(deps.needNeutralIconKeys)
    local NEED_NEUTRAL_FLASH_SOURCE_ICON_KEYS = assert(deps.needNeutralFlashSourceIconKeys)
    local HUNGER_FLASH_ICON_KEYS = assert(deps.hungerFlashIconKeys)
    local THIRST_FLASH_ICON_KEYS = assert(deps.thirstFlashIconKeys)
    local MIN_NEED_BAR_HEIGHT = assert(deps.minNeedBarHeight)
    local NEED_BAR_HEIGHT_RATIO = assert(deps.needBarHeightRatio)
    local NEED_BAR_OFFSET_PIXELS = assert(deps.needBarOffsetPixels)
    local RAW_VALUE_TEXT_SIZE = assert(deps.rawValueTextSize)
    local RAW_VALUE_TEXT_HEIGHT = assert(deps.rawValueTextHeight)
    local HUD_DYNAMIC_REBUILD_INTERVAL_SECONDS = assert(deps.hudDynamicRebuildIntervalSeconds)

    local function getHudRebuildTime()
        if type(core.getRealTime) == 'function' then
            local ok, value = pcall(core.getRealTime)
            if ok then
                local realTime = tonumber(value)
                if realTime ~= nil then
                    return realTime
                end
            end
        end

        return now()
    end
    local HUD_PADDING = assert(deps.hudPadding)
    local HUD_SIGNATURE_ALPHA_STEPS = 20

local function quantizeAlphaForSignature(alphaValue)
    local clamped = clamp(tonumber(alphaValue) or 0, 0, 1)
    local steps = math.max(1, math.floor(tonumber(HUD_SIGNATURE_ALPHA_STEPS) or 20))
    return tostring(round(clamped * steps))
end

local function normalizeWetnessHudSignature(signatureToken)
    local token = tostring(signatureToken or '')
    local wetness, alphaMillis = token:match('^(%-?%d+):(%-?%d+)$')
    if wetness == nil or alphaMillis == nil then
        if token == '' then
            return '-'
        end
        return token
    end

    local wetnessValue = tonumber(wetness) or 0
    local alphaValue = clamp((tonumber(alphaMillis) or 0) / 1000, 0, 1)
    return string.format('%d:%s', round(wetnessValue), quantizeAlphaForSignature(alphaValue))
end

local function buildHudSignature(
    icons,
    hungerSystemEnabled,
    thirstSystemEnabled,
    sleepSystemEnabled,
    temperatureSystemEnabled,
    horizontal,
    hudPosition,
    hudOffsetX,
    hudOffsetY,
    enabled,
    showRawValues,
    showProgressBars,
    temperatureProgressBarEnabled,
    progressBarOrientation,
    showNeutralImages,
    showThickerIconFrame,
    iconSize,
    iconSpacing,
    hungerValue,
    thirstValue,
    sleepValue,
    temperatureValue,
    hungerFlashAlpha,
    thirstFlashAlpha,
    hungerIconAlpha,
    thirstIconAlpha,
    sleepIconAlpha,
    temperatureIconAlpha,
    hungerLeavingIcon,
    thirstLeavingIcon,
    sleepLeavingIcon,
    temperatureLeavingIcon,
    hungerLeavingAlpha,
    thirstLeavingAlpha,
    sleepLeavingAlpha,
    temperatureLeavingAlpha,
    temperatureDebugOverlayEnabled,
    temperatureDebugOverlaySignature,
    wetnessHudSignature
)
    local parts = {
        enabled and '1' or '0',
        hungerSystemEnabled and '1' or '0',
        thirstSystemEnabled and '1' or '0',
        sleepSystemEnabled and '1' or '0',
        temperatureSystemEnabled and '1' or '0',
        horizontal and '1' or '0',
        showRawValues and '1' or '0',
        showProgressBars and '1' or '0',
        temperatureProgressBarEnabled and '1' or '0',
        progressBarOrientation,
        showNeutralImages and '1' or '0',
        showThickerIconFrame and '1' or '0',
        icons.hunger or '-',
        icons.thirst or '-',
        icons.sleep or '-',
        icons.temperature or '-',
        string.format('%.4f', hudPosition.x),
        string.format('%.4f', hudPosition.y),
        tostring(iconSize),
        tostring(iconSpacing),
        tostring(round(hungerValue)),
        tostring(round(thirstValue)),
        tostring(round(sleepValue)),
        tostring(round(temperatureValue)),
        quantizeAlphaForSignature(hungerFlashAlpha),
        quantizeAlphaForSignature(thirstFlashAlpha),
        quantizeAlphaForSignature(hungerIconAlpha),
        quantizeAlphaForSignature(thirstIconAlpha),
        quantizeAlphaForSignature(sleepIconAlpha),
        quantizeAlphaForSignature(temperatureIconAlpha),
        hungerLeavingIcon or '-',
        thirstLeavingIcon or '-',
        sleepLeavingIcon or '-',
        temperatureLeavingIcon or '-',
        quantizeAlphaForSignature(hungerLeavingAlpha),
        quantizeAlphaForSignature(thirstLeavingAlpha),
        quantizeAlphaForSignature(sleepLeavingAlpha),
        quantizeAlphaForSignature(temperatureLeavingAlpha),
        tostring(hudOffsetX),
        tostring(hudOffsetY),
        temperatureDebugOverlayEnabled and '1' or '0',
        temperatureDebugOverlaySignature or '-',
        normalizeWetnessHudSignature(wetnessHudSignature),
    }

    return table.concat(parts, '|')
end

local function buildHudLayoutSignature(
    icons,
    hungerSystemEnabled,
    thirstSystemEnabled,
    sleepSystemEnabled,
    temperatureSystemEnabled,
    horizontal,
    hudPosition,
    hudOffsetX,
    hudOffsetY,
    enabled,
    showRawValues,
    showProgressBars,
    temperatureProgressBarEnabled,
    progressBarOrientation,
    showNeutralImages,
    showThickerIconFrame,
    iconSize,
    iconSpacing,
    temperatureDebugOverlayEnabled
)
    local parts = {
        enabled and '1' or '0',
        hungerSystemEnabled and '1' or '0',
        thirstSystemEnabled and '1' or '0',
        sleepSystemEnabled and '1' or '0',
        temperatureSystemEnabled and '1' or '0',
        horizontal and '1' or '0',
        showRawValues and '1' or '0',
        showProgressBars and '1' or '0',
        temperatureProgressBarEnabled and '1' or '0',
        progressBarOrientation,
        showNeutralImages and '1' or '0',
        showThickerIconFrame and '1' or '0',
        icons.hunger or '-',
        icons.thirst or '-',
        icons.sleep or '-',
        icons.temperature or '-',
        string.format('%.4f', hudPosition.x),
        string.format('%.4f', hudPosition.y),
        tostring(iconSize),
        tostring(iconSpacing),
        tostring(hudOffsetX),
        tostring(hudOffsetY),
        temperatureDebugOverlayEnabled and '1' or '0',
    }

    return table.concat(parts, '|')
end

local function spacerWidget(horizontal, spacing)
    if horizontal then
        return {
            props = {
                size = util.vector2(spacing, 1),
            },
        }
    end

    return {
        props = {
            size = util.vector2(1, spacing),
        },
    }
end

local function destroyHud()
    if state.hudElement == nil then
        return true
    end

    local hudElement = state.hudElement
    local ok, err = pcall(function()
        hudElement:destroy()
    end)

    if ok then
        state.hudElement = nil
        return true
    end

    print(string.format('[SurvivalMode] Failed to destroy HUD element: %s', tostring(err)))
    return false
end

local function refreshHud(hungerStage, thirstStage, sleepStage, temperatureStage)
    ensureIconResources()

    local horizontal = isHorizontal()
    local enabled = isHudEnabled()
    local showTemperatureDebugOverlay = TEMPERATURE_DEBUG.isOverlayEnabled()
    local showRawValues = isRawValuesDebugEnabled()
    local showProgressBars = areProgressBarsEnabled()
    local temperatureProgressBarValue = hudSettings:get('temperatureVerticalProgressBar')
    local temperatureProgressBarEnabled = true
    if temperatureProgressBarValue ~= nil then
        if type(temperatureProgressBarValue) == 'string' then
            local legacyMode = normalizeKey(temperatureProgressBarValue)
            temperatureProgressBarEnabled = legacyMode == 'left' or legacyMode == 'right'
        else
            temperatureProgressBarEnabled = temperatureProgressBarValue == true
        end
    end
    local progressBarOrientation = normalizeKey(tostring(hudSettings:get('progressBarOrientation') or ''))
    if progressBarOrientation ~= 'horizontal' then
        progressBarOrientation = 'vertical'
    end
    local useVerticalProgressBars = progressBarOrientation == 'vertical'
    local showNeutralImages = isNeutralImagesSettingEnabled()
    local showThickerIconFrame = isThickerIconFrameEnabled()
    local needSystemEnabledById = {
        hunger = isHungerSystemEnabled(),
        thirst = isThirstSystemEnabled(),
        sleep = isSleepSystemEnabled(),
        temperature = isTemperatureSystemEnabled(),
    }
    local icons = getNeedIcons(hungerStage, thirstStage, sleepStage, temperatureStage, not showNeutralImages)
    syncNeedIconFadeState(icons)
    local hudPosition = getHudPosition()
    local hudAnchor = util.vector2(
        hudPosition.x >= 0.5 and 1 or 0,
        hudPosition.y >= 0.5 and 1 or 0
    )
    local hudOffsetX = getHudOffsetX()
    local hudOffsetY = getHudOffsetY()
    local iconSize = getIconSizeValue()
    local iconSpacing = getIconSpacingValue()
    local hungerValue = state.hunger
    local thirstValue = state.thirst
    local sleepValue = state.sleep
    local temperatureValue = state.temperature
    local hungerFlashAlpha = getHungerFlashAlpha()
    local thirstFlashAlpha = getThirstFlashAlpha()
    local hungerIconAlpha = getNeedIconAlpha('hunger')
    local thirstIconAlpha = getNeedIconAlpha('thirst')
    local sleepIconAlpha = getNeedIconAlpha('sleep')
    local temperatureIconAlpha = getNeedIconAlpha('temperature')
    local hungerLeavingIcon = state.leavingNeedIcons.hunger
    local thirstLeavingIcon = state.leavingNeedIcons.thirst
    local sleepLeavingIcon = state.leavingNeedIcons.sleep
    local temperatureLeavingIcon = state.leavingNeedIcons.temperature
    local hungerLeavingAlpha = getNeedLeavingIconAlpha('hunger')
    local thirstLeavingAlpha = getNeedLeavingIconAlpha('thirst')
    local sleepLeavingAlpha = getNeedLeavingIconAlpha('sleep')
    local temperatureLeavingAlpha = getNeedLeavingIconAlpha('temperature')
    local temperatureDebugOverlayLines = {}
    local temperatureDebugOverlaySignature = nil
    local wetnessHud = require('scripts.survivalmode.temperature.wetnessHud')
    local wetnessHudSignature = wetnessHud.getSignatureToken()

    if showTemperatureDebugOverlay then
        temperatureDebugOverlayLines = TEMPERATURE_DEBUG.buildDebugOverlayLines(state)
        temperatureDebugOverlaySignature = table.concat(temperatureDebugOverlayLines, '\n')
    end

    local layoutSignature = buildHudLayoutSignature(
        icons,
        needSystemEnabledById.hunger,
        needSystemEnabledById.thirst,
        needSystemEnabledById.sleep,
        needSystemEnabledById.temperature,
        horizontal,
        hudPosition,
        hudOffsetX,
        hudOffsetY,
        enabled,
        showRawValues,
        showProgressBars,
        temperatureProgressBarEnabled,
        progressBarOrientation,
        showNeutralImages,
        showThickerIconFrame,
        iconSize,
        iconSpacing,
        showTemperatureDebugOverlay
    )

    local signature = buildHudSignature(
        icons,
        needSystemEnabledById.hunger,
        needSystemEnabledById.thirst,
        needSystemEnabledById.sleep,
        needSystemEnabledById.temperature,
        horizontal,
        hudPosition,
        hudOffsetX,
        hudOffsetY,
        enabled,
        showRawValues,
        showProgressBars,
        temperatureProgressBarEnabled,
        progressBarOrientation,
        showNeutralImages,
        showThickerIconFrame,
        iconSize,
        iconSpacing,
        hungerValue,
        thirstValue,
        sleepValue,
        temperatureValue,
        hungerFlashAlpha,
        thirstFlashAlpha,
        hungerIconAlpha,
        thirstIconAlpha,
        sleepIconAlpha,
        temperatureIconAlpha,
        hungerLeavingIcon,
        thirstLeavingIcon,
        sleepLeavingIcon,
        temperatureLeavingIcon,
        hungerLeavingAlpha,
        thirstLeavingAlpha,
        sleepLeavingAlpha,
        temperatureLeavingAlpha,
        showTemperatureDebugOverlay,
        temperatureDebugOverlaySignature,
        wetnessHudSignature
    )

    local hasExistingHud = state.hudElement ~= nil
    if hasExistingHud and signature ~= state.hudSignature and layoutSignature == state.hudLayoutSignature then
        local elapsedSinceLastHudRebuild = getHudRebuildTime() - (tonumber(state.lastHudRebuildTime) or -math.huge)
        if elapsedSinceLastHudRebuild >= 0 and elapsedSinceLastHudRebuild < HUD_DYNAMIC_REBUILD_INTERVAL_SECONDS then
            return
        end
    end

    if signature == state.hudSignature and state.hudElement ~= nil then
        return
    end

    if not destroyHud() then
        -- Keep trying to clean up the current element before creating a replacement.
        state.hudSignature = nil
        state.hudLayoutSignature = nil
        return
    end
    state.hudSignature = signature
    state.hudLayoutSignature = layoutSignature
    state.lastHudRebuildTime = getHudRebuildTime()

    local rootWidgets = {}

    if enabled then
        local visibleIcons = {}
        local needDisplayOrder = {
            'hunger',
            'thirst',
            'sleep',
            'temperature',
        }
        if not horizontal then
            needDisplayOrder = {
                'temperature',
                'hunger',
                'thirst',
                'sleep',
            }
        end

        for _, needId in ipairs(needDisplayOrder) do
            if needSystemEnabledById[needId] == true then
                local iconKey = icons[needId]
                local leavingIconKey = state.leavingNeedIcons[needId]
                local neutralIconKey = nil
                local neutralFlashSourceIconKey = nil
                if showNeutralImages then
                    neutralIconKey = NEED_NEUTRAL_ICON_KEYS[needId]
                    neutralFlashSourceIconKey = NEED_NEUTRAL_FLASH_SOURCE_ICON_KEYS[needId]
                end

                if iconKey ~= nil or leavingIconKey ~= nil or neutralIconKey ~= nil then
                    table.insert(visibleIcons, {
                        needId = needId,
                        iconKey = iconKey,
                        leavingIconKey = leavingIconKey,
                        neutralIconKey = neutralIconKey,
                        neutralFlashSourceIconKey = neutralFlashSourceIconKey,
                        baseAlpha = getNeedIconAlpha(needId),
                        leavingAlpha = getNeedLeavingIconAlpha(needId),
                    })
                end
            end
        end

        if #visibleIcons > 0 then
            local needValues = {
                hunger = hungerValue,
                thirst = thirstValue,
                sleep = sleepValue,
                temperature = temperatureValue,
            }
            local needStages = {
                hunger = hungerStage,
                thirst = thirstStage,
                sleep = sleepStage,
                temperature = temperatureStage,
            }
            local sharedBarHeightOrThickness = math.max(
                MIN_NEED_BAR_HEIGHT,
                math.floor((iconSize * NEED_BAR_HEIGHT_RATIO) + 0.5)
            )
            local sharedVerticalWetnessBarExtraWidth = 0
            if useVerticalProgressBars and not horizontal and wetnessHud.hasVisibleBar() then
                sharedVerticalWetnessBarExtraWidth = NEED_BAR_OFFSET_PIXELS + sharedBarHeightOrThickness
            end

            local widgets = {}
            for index, descriptor in ipairs(visibleIcons) do
                if index > 1 and iconSpacing > 0 then
                    table.insert(widgets, {
                        type = ui.TYPE.Widget,
                        props = spacerWidget(horizontal, iconSpacing).props,
                    })
                end

                local layers = {}

                if descriptor.neutralIconKey ~= nil then
                    table.insert(layers, {
                        type = ui.TYPE.Image,
                        props = {
                            resource = state.iconResources[descriptor.neutralIconKey],
                            size = util.vector2(iconSize, iconSize),
                            alpha = 1.0,
                        },
                    })
                end

                if descriptor.leavingIconKey ~= nil and descriptor.leavingAlpha > 0 then
                    table.insert(layers, {
                        type = ui.TYPE.Image,
                        props = {
                            resource = state.iconResources[descriptor.leavingIconKey],
                            size = util.vector2(iconSize, iconSize),
                            alpha = descriptor.leavingAlpha,
                        },
                    })
                end

                if descriptor.iconKey ~= nil then
                    table.insert(layers, {
                        type = ui.TYPE.Image,
                        props = {
                            resource = state.iconResources[descriptor.iconKey],
                            size = util.vector2(iconSize, iconSize),
                            alpha = descriptor.baseAlpha,
                        },
                    })
                end

                local hungerFlashSourceIconKey = descriptor.iconKey or descriptor.neutralFlashSourceIconKey
                if descriptor.needId == 'hunger' and hungerFlashSourceIconKey ~= nil and hungerFlashAlpha > 0 then
                    local flashIconKey = HUNGER_FLASH_ICON_KEYS[hungerFlashSourceIconKey]
                    if flashIconKey ~= nil and state.iconResources[flashIconKey] ~= nil then
                        table.insert(layers, {
                            type = ui.TYPE.Image,
                            props = {
                                resource = state.iconResources[flashIconKey],
                                size = util.vector2(iconSize, iconSize),
                                alpha = hungerFlashAlpha,
                            },
                        })
                    end
                end

                local thirstFlashSourceIconKey = descriptor.iconKey or descriptor.neutralFlashSourceIconKey
                if descriptor.needId == 'thirst' and thirstFlashSourceIconKey ~= nil and thirstFlashAlpha > 0 then
                    local flashIconKey = THIRST_FLASH_ICON_KEYS[thirstFlashSourceIconKey]
                    if flashIconKey ~= nil and state.iconResources[flashIconKey] ~= nil then
                        table.insert(layers, {
                            type = ui.TYPE.Image,
                            props = {
                                resource = state.iconResources[flashIconKey],
                                size = util.vector2(iconSize, iconSize),
                                alpha = thirstFlashAlpha,
                            },
                        })
                    end
                end

                if showThickerIconFrame then
                    local frameAlpha = 0
                    if descriptor.neutralIconKey ~= nil then
                        frameAlpha = 1
                    end
                    if descriptor.iconKey ~= nil then
                        frameAlpha = math.max(frameAlpha, descriptor.baseAlpha or 0)
                    end
                    if descriptor.leavingIconKey ~= nil then
                        frameAlpha = math.max(frameAlpha, descriptor.leavingAlpha or 0)
                    end
                    table.insert(layers, {
                        type = ui.TYPE.Image,
                        props = {
                            resource = state.iconResources.frame_thick,
                            size = util.vector2(iconSize, iconSize),
                            alpha = clamp(frameAlpha, 0, 1),
                        },
                    })
                end

                local iconWidget = {
                    type = ui.TYPE.Widget,
                    props = {
                        size = util.vector2(iconSize, iconSize),
                    },
                    content = ui.content(layers),
                }

                local mainVisualWidget = iconWidget
                local barHeightOrThickness = sharedBarHeightOrThickness
                local showTemperatureProgressBar = descriptor.needId == 'temperature'
                    and temperatureProgressBarEnabled
                local showNeedProgressBar = showProgressBars
                if descriptor.needId == 'temperature' then
                    showNeedProgressBar = showProgressBars or showTemperatureProgressBar
                end
                local showWetnessBar = descriptor.needId == 'temperature' and wetnessHud.hasVisibleBar()
                local wetnessBarWidget = nil
                if showWetnessBar then
                    wetnessBarWidget = wetnessHud.buildBarWidget(
                        iconSize,
                        barHeightOrThickness,
                        progressBarOrientation
                    )
                end

                if showNeedProgressBar then
                    local barProgress = getStageProgressNormalized(
                        needValues[descriptor.needId],
                        needStages[descriptor.needId],
                        descriptor.needId == 'temperature'
                    )

                    if useVerticalProgressBars then
                        local fillHeight = math.floor((iconSize * barProgress) + 0.5)
                        fillHeight = clamp(fillHeight, 0, iconSize)
                        local barLayers = {
                            {
                                type = ui.TYPE.Image,
                                props = {
                                    resource = state.iconResources.need_bar_empty_texture,
                                    size = util.vector2(barHeightOrThickness, iconSize),
                                    alpha = 1.0,
                                },
                            },
                        }

                        if fillHeight > 0 then
                            table.insert(barLayers, {
                                type = ui.TYPE.Image,
                                props = {
                                    resource = state.iconResources.need_bar_fill_texture,
                                    size = util.vector2(barHeightOrThickness, fillHeight),
                                    relativePosition = util.vector2(0, 1),
                                    anchor = util.vector2(0, 1),
                                    alpha = 1.0,
                                },
                            })
                        end

                        table.insert(barLayers, {
                            type = ui.TYPE.Image,
                            props = {
                                resource = state.iconResources.need_bar_overlay_texture_v,
                                size = util.vector2(barHeightOrThickness, iconSize),
                                alpha = 1.0,
                            },
                        })

                        local verticalBarWidget = {
                            type = ui.TYPE.Widget,
                            props = {
                                size = util.vector2(barHeightOrThickness, iconSize),
                            },
                            content = ui.content(barLayers),
                        }

                        local sideContent = {}
                        if not horizontal and wetnessBarWidget ~= nil then
                            table.insert(sideContent, wetnessBarWidget)
                            if NEED_BAR_OFFSET_PIXELS > 0 then
                                table.insert(sideContent, {
                                    type = ui.TYPE.Widget,
                                    props = {
                                        size = util.vector2(NEED_BAR_OFFSET_PIXELS, iconSize),
                                    },
                                })
                            end
                        end
                        table.insert(sideContent, iconWidget)
                        if NEED_BAR_OFFSET_PIXELS > 0 then
                            table.insert(sideContent, {
                                type = ui.TYPE.Widget,
                                props = {
                                    size = util.vector2(NEED_BAR_OFFSET_PIXELS, iconSize),
                                },
                            })
                        end
                        table.insert(sideContent, verticalBarWidget)
                        if horizontal and wetnessBarWidget ~= nil then
                            if NEED_BAR_OFFSET_PIXELS > 0 then
                                table.insert(sideContent, {
                                    type = ui.TYPE.Widget,
                                    props = {
                                        size = util.vector2(NEED_BAR_OFFSET_PIXELS, iconSize),
                                    },
                                })
                            end
                            table.insert(sideContent, wetnessBarWidget)
                        end

                        mainVisualWidget = {
                            type = ui.TYPE.Flex,
                            props = {
                                horizontal = true,
                                arrange = ui.ALIGNMENT.Center,
                            },
                            content = ui.content(sideContent),
                        }
                    else
                        local itemWidgets = ui.content({ iconWidget })
                        local fillWidth = math.floor((iconSize * barProgress) + 0.5)
                        fillWidth = clamp(fillWidth, 0, iconSize)
                        local barLayers = {
                            {
                                type = ui.TYPE.Image,
                                props = {
                                    resource = state.iconResources.need_bar_empty_texture,
                                    size = util.vector2(iconSize, barHeightOrThickness),
                                    alpha = 1.0,
                                },
                            },
                        }

                        if fillWidth > 0 then
                            table.insert(barLayers, {
                                type = ui.TYPE.Image,
                                props = {
                                    resource = state.iconResources.need_bar_fill_texture,
                                    size = util.vector2(fillWidth, barHeightOrThickness),
                                    alpha = 1.0,
                                },
                            })
                        end

                        table.insert(barLayers, {
                            type = ui.TYPE.Image,
                            props = {
                                resource = state.iconResources.need_bar_overlay_texture_h,
                                size = util.vector2(iconSize, barHeightOrThickness),
                                alpha = 1.0,
                            },
                        })

                        if NEED_BAR_OFFSET_PIXELS > 0 then
                            itemWidgets:add({
                                type = ui.TYPE.Widget,
                                props = {
                                    size = util.vector2(iconSize, NEED_BAR_OFFSET_PIXELS),
                                },
                            })
                        end

                        local bottomBarWidget = {
                            type = ui.TYPE.Widget,
                            props = {
                                size = util.vector2(iconSize, barHeightOrThickness),
                            },
                            content = ui.content(barLayers),
                        }
                        itemWidgets:add(bottomBarWidget)
                        if wetnessBarWidget ~= nil then
                            if NEED_BAR_OFFSET_PIXELS > 0 then
                                itemWidgets:add({
                                    type = ui.TYPE.Widget,
                                    props = {
                                        size = util.vector2(iconSize, NEED_BAR_OFFSET_PIXELS),
                                    },
                                })
                            end
                            itemWidgets:add(wetnessBarWidget)
                        end

                        mainVisualWidget = {
                            type = ui.TYPE.Flex,
                            props = {
                                horizontal = false,
                                arrange = ui.ALIGNMENT.Center,
                            },
                            content = itemWidgets,
                        }
                    end
                elseif wetnessBarWidget ~= nil then
                    if useVerticalProgressBars then
                        local sideContent = {}
                        if not horizontal then
                            table.insert(sideContent, wetnessBarWidget)
                            if NEED_BAR_OFFSET_PIXELS > 0 then
                                table.insert(sideContent, {
                                    type = ui.TYPE.Widget,
                                    props = {
                                        size = util.vector2(NEED_BAR_OFFSET_PIXELS, iconSize),
                                    },
                                })
                            end
                            table.insert(sideContent, iconWidget)
                        else
                            table.insert(sideContent, iconWidget)
                            if NEED_BAR_OFFSET_PIXELS > 0 then
                                table.insert(sideContent, {
                                    type = ui.TYPE.Widget,
                                    props = {
                                        size = util.vector2(NEED_BAR_OFFSET_PIXELS, iconSize),
                                    },
                                })
                            end
                            table.insert(sideContent, wetnessBarWidget)
                        end
                        mainVisualWidget = {
                            type = ui.TYPE.Flex,
                            props = {
                                horizontal = true,
                                arrange = ui.ALIGNMENT.Center,
                            },
                            content = ui.content(sideContent),
                        }
                    else
                        local itemWidgets = ui.content({ iconWidget })
                        if NEED_BAR_OFFSET_PIXELS > 0 then
                            itemWidgets:add({
                                type = ui.TYPE.Widget,
                                props = {
                                    size = util.vector2(iconSize, NEED_BAR_OFFSET_PIXELS),
                                },
                            })
                        end
                        itemWidgets:add(wetnessBarWidget)
                        mainVisualWidget = {
                            type = ui.TYPE.Flex,
                            props = {
                                horizontal = false,
                                arrange = ui.ALIGNMENT.Center,
                            },
                            content = itemWidgets,
                        }
                    end
                end

                if useVerticalProgressBars
                    and not horizontal
                    and sharedVerticalWetnessBarExtraWidth > 0
                    and descriptor.needId ~= 'temperature' then
                    mainVisualWidget = {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            arrange = ui.ALIGNMENT.Start,
                        },
                        content = ui.content({
                            {
                                type = ui.TYPE.Widget,
                                props = {
                                    size = util.vector2(sharedVerticalWetnessBarExtraWidth, iconSize),
                                },
                            },
                            mainVisualWidget,
                        }),
                    }
                end

                local itemWidgets = ui.content({ mainVisualWidget })
                if showRawValues and (descriptor.iconKey ~= nil or descriptor.neutralIconKey ~= nil) then
                    itemWidgets:add({
                        type = ui.TYPE.Text,
                        props = {
                            text = tostring(round(needValues[descriptor.needId] or 0)),
                            textSize = RAW_VALUE_TEXT_SIZE,
                            size = util.vector2(iconSize, RAW_VALUE_TEXT_HEIGHT),
                            textColor = TEMPERATURE_DEBUG.textColor,
                        },
                    })
                end

                table.insert(widgets, {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = false,
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = itemWidgets,
                })
            end

            local iconRowArrange = ui.ALIGNMENT.Center
            if horizontal then
                iconRowArrange = ui.ALIGNMENT.Start
            end
            table.insert(rootWidgets, {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = horizontal,
                    arrange = iconRowArrange,
                },
                content = ui.content(widgets),
            })
        end
    end

    if showTemperatureDebugOverlay then
        if #rootWidgets > 0 and TEMPERATURE_DEBUG.spacing > 0 then
            table.insert(rootWidgets, {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(1, TEMPERATURE_DEBUG.spacing),
                },
            })
        end

        local overlayLineWidgets = ui.content({})
        for _, lineText in ipairs(temperatureDebugOverlayLines) do
            overlayLineWidgets:add({
                type = ui.TYPE.Text,
                props = {
                    text = lineText,
                    textSize = TEMPERATURE_DEBUG.textSize,
                    size = util.vector2(TEMPERATURE_DEBUG.textWidth, TEMPERATURE_DEBUG.lineHeight),
                    textColor = TEMPERATURE_DEBUG.textColor,
                },
            })
        end

        table.insert(rootWidgets, {
            type = ui.TYPE.Flex,
            props = {
                horizontal = false,
                arrange = ui.ALIGNMENT.Center,
            },
            content = overlayLineWidgets,
        })
    end

    if #rootWidgets == 0 then
        return
    end

    local hudContentArrange = ui.ALIGNMENT.Center
    if hudAnchor.x >= 1 then
        hudContentArrange = ui.ALIGNMENT.End
    elseif hudAnchor.x <= 0 then
        hudContentArrange = ui.ALIGNMENT.Start
    end

    state.hudElement = ui.create({
        layer = 'HUD',
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            relativePosition = hudPosition,
            anchor = hudAnchor,
            position = (util.vector2(1, 1) - hudAnchor * 2):emul(HUD_PADDING) + util.vector2(hudOffsetX, hudOffsetY),
            arrange = hudContentArrange,
        },
        content = ui.content(rootWidgets),
    })
end


    return {
        refreshHud = refreshHud,
        destroyHud = destroyHud,
    }
end

return M
