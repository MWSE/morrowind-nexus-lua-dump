---@omw-context none
local module = {}

local DEFAULT_TEXTURE = 'textures/sitdownplease/sitdownplease_black.png'
local ALPHA_UPDATE_EPSILON = 0.025
local elementAlphaCache = setmetatable({}, { __mode = "k" })

local function noopLog(...)
end

local function safeCall(fn)
    local ok, result = pcall(fn)
    if ok then return result end
    return nil, result
end

function module.createOnLayer(env, layerName, overlayName)
    local ui = assert(env.ui, "initialPlacementOverlay.createOnLayer requires env.ui")
    local util = assert(env.util, "initialPlacementOverlay.createOnLayer requires env.util")
    local debugLog = env.debugLog or noopLog
    local texturePath = env.texturePath or DEFAULT_TEXTURE
    if ui.layers and ui.layers.indexOf and not ui.layers.indexOf(layerName) then
        debugLog("initial placement overlay layer missing", tostring(layerName))
        return nil
    end

    local overlay, err = safeCall(function()
        return ui.create({
            type = ui.TYPE.Image,
            layer = layerName,
            name = overlayName,
            props = {
                resource = ui.texture { path = texturePath },
                relativePosition = util.vector2(0, 0),
                anchor = util.vector2(0, 0),
                relativeSize = util.vector2(1, 1),
                color = util.color.rgb(0, 0, 0),
                alpha = 1.0,
                propagateEvents = false,
            },
        }, { noWarnUnused = true })
    end)

    if overlay then return overlay end
    debugLog("initial placement overlay layer failed", tostring(layerName), tostring(err))
    return nil
end

function module.createLoadingText(env, layerName, overlayName)
    if env.showLoadingText ~= true then return nil end
    local ui = assert(env.ui, "initialPlacementOverlay.createLoadingText requires env.ui")
    local util = assert(env.util, "initialPlacementOverlay.createLoadingText requires env.util")
    local debugLog = env.debugLog or noopLog
    local label = tostring(env.loadingText or "Loading...")
    if ui.layers and ui.layers.indexOf and not ui.layers.indexOf(layerName) then
        debugLog("initial placement overlay loading text layer missing", tostring(layerName))
        return nil
    end
    local text, err = safeCall(function()
        return ui.create({
            type = ui.TYPE.Text,
            layer = layerName,
            name = overlayName,
            props = {
                text = label,
                textSize = tonumber(env.loadingTextSize or 22) or 22,
                textColor = util.color.rgb(0.86, 0.82, 0.70),
                textShadow = true,
                textShadowColor = util.color.rgb(0, 0, 0),
                relativePosition = util.vector2(0.5, 0.56),
                anchor = util.vector2(0.5, 0.5),
                size = util.vector2(440, 44),
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                alpha = 1.0,
                propagateEvents = false,
            },
        }, { noWarnUnused = true })
    end)
    if text then return text end
    debugLog("initial placement overlay loading text failed", tostring(layerName), tostring(err))
    return nil
end

function module.createPair(env)
    local mainLayer = env.mainLayer or 'Notification'
    local companionLayer = env.companionLayer or 'Windows'
    local mainName = env.mainName or 'SitDownPleaseInitialPlacementOverlay'
    local companionName = env.companionName or 'SitDownPleaseInitialPlacementOverlayTop'
    local textName = env.textName or 'SitDownPleaseInitialPlacementOverlayText'

    local main = module.createOnLayer(env, mainLayer, mainName)
    local companion = module.createOnLayer(env, companionLayer, companionName)
    local text = module.createLoadingText(env, companionLayer, textName)
    return main, companion, text
end

function module.ensureCompanion(env, companion, text)
    local createdCompanion = companion
    if not createdCompanion then
        createdCompanion = module.createOnLayer(
            env,
            env.companionLayer or 'Windows',
            env.companionName or 'SitDownPleaseInitialPlacementOverlayTop'
        )
    end
    local createdText = text
    if not createdText then
        createdText = module.createLoadingText(
            env,
            env.companionLayer or 'Windows',
            env.textName or 'SitDownPleaseInitialPlacementOverlayText'
        )
    end
    return createdCompanion, createdText
end

function module.destroyPair(main, companion, text)
    if text then elementAlphaCache[text] = nil end
    if main then elementAlphaCache[main] = nil end
    if companion then elementAlphaCache[companion] = nil end
    if text then pcall(function() text:destroy() end) end
    if main then pcall(function() main:destroy() end) end
    if companion and companion ~= main then pcall(function() companion:destroy() end) end
end

local function setElementAlpha(element, alpha)
    if not element then return end
    local previous = elementAlphaCache[element]
    if previous ~= nil then
        local terminalChange = (alpha == 0 and previous ~= 0) or (alpha == 1 and previous ~= 1)
        if math.abs(alpha - previous) < ALPHA_UPDATE_EPSILON and not terminalChange then return end
    end
    elementAlphaCache[element] = alpha
    pcall(function() element.layout.props.alpha = alpha end)
    pcall(function() element.props.alpha = alpha end)
    pcall(function() element:update() end)
end

function module.setAlpha(main, companion, text, alpha)
    alpha = math.max(0, math.min(1, tonumber(alpha) or 1))
    setElementAlpha(main, alpha)
    if companion and companion ~= main then setElementAlpha(companion, alpha) end
    setElementAlpha(text, alpha)
end

return module
