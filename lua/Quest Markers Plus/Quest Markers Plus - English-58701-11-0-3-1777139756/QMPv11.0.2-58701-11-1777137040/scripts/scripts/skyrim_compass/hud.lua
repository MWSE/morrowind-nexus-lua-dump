local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local v2 = util.vector2

local settings = storage.playerSection("SkyrimCompass_Settings")

local TEX = "textures/icons/skyrim_compass/"
local whiteTex = ui.texture { path = TEX .. "bar_white.dds" }

local BASE_WIDTH = 600
local BASE_HEIGHT = 40
local COMPASS_MARGIN = 10
local LOC_SHOW_TIME = 4.0

local function getScale()
    return (settings:get("compassScale") or 100) / 100
end

local els = {}
local built = false
local lastFrame = 0

local locName = ""
local locAlpha = 0
local locTimer = 0
local LOC_PERSIST_TIME = 5.0
local discAlpha = 0
local discTimer = 0

local function getLabelY(ss)
    local ch = BASE_HEIGHT * getScale()
    if settings:get("compassBottom") then
        return ss.y - ch - COMPASS_MARGIN - 18
    else
        return COMPASS_MARGIN + ch + 4
    end
end

local function getScreenSize()
    local layerId = ui.layers.indexOf("HUD")
    local w = ui.layers[layerId].size.x
    local ss = ui.screenSize()
    local scale = ss.x / w
    return ss:ediv(v2(scale, scale))
end

local function createCenteredText(size, clr)
    return ui.create({
        layer = "HUD",
        type = ui.TYPE.Flex,
        props = {
            position = v2(0, 0),
            size = v2(BASE_WIDTH * getScale(), size + 10),
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            visible = false,
            alpha = 0,
        },
        content = ui.content {
            { type = ui.TYPE.Text, props = {
                text = "",
                textSize = size,
                textColor = clr or util.color.rgb(0.88, 0.88, 0.88),
                textShadow = true,
                textShadowColor = util.color.rgb(0, 0, 0),
            }},
        },
    })
end

local function buildAll()
    els.locLabel = createCenteredText(13, util.color.rgb(0.78, 0.78, 0.78))

    els.discText = createCenteredText(26)

    els.discLine = ui.create({
        layer = "HUD",
        type = ui.TYPE.Widget,
        props = { position = v2(0, 0), size = v2(240, 2), visible = false, alpha = 0 },
        content = ui.content {
            { type = ui.TYPE.Image, props = {
                position = v2(0, 0), size = v2(240, 2),
                resource = whiteTex, color = util.color.rgb(0.6, 0.6, 0.6), alpha = 0.5,
            }},
        },
    })

    built = true
end

local function getLocationName()
    local cell
    pcall(function()
        cell = self.cell or (self.object and self.object.cell)
    end)
    if not cell then return "" end

    local name = ""
    pcall(function() name = cell.name or "" end)
    if name ~= "" then return name end

    pcall(function()
        if cell.isExterior then
            local region = cell.region
            if region and region ~= "" then name = region end
        end
    end)

    return name
end

local function updateLocation(dt)
    local ss = getScreenSize()
    local cw = BASE_WIDTH * getScale()
    local compassX = (ss.x - cw) / 2
    local name = getLocationName()

    if name ~= locName and name ~= "" then
        locName = name
        locTimer = LOC_PERSIST_TIME
        discTimer = LOC_SHOW_TIME
        if els.discText then
            els.discText.layout.content[1].props.text = name
            els.discText.layout.props.visible = true
        end
    end

    if els.locLabel and settings:get("showLocationLabel") ~= false then
        els.locLabel.layout.props.position = v2(compassX, getLabelY(ss))
        els.locLabel.layout.props.size = v2(cw, 23)
        els.locLabel.layout.content[1].props.text = locName
        local tgt = 0
        if locTimer > 0 then
            locTimer = locTimer - dt
            if locTimer > LOC_PERSIST_TIME - 0.5 then
                tgt = ((LOC_PERSIST_TIME - locTimer) / 0.5) * 0.7
            elseif locTimer < 1.0 then
                tgt = (locTimer / 1.0) * 0.7
            else
                tgt = 0.7
            end
        end
        if locAlpha < tgt then
            locAlpha = math.min(tgt, locAlpha + dt * 2)
        elseif locAlpha > tgt then
            locAlpha = math.max(tgt, locAlpha - dt * 2)
        end
        els.locLabel.layout.props.alpha = locAlpha
        els.locLabel.layout.props.visible = locAlpha > 0.01
        els.locLabel:update()
    end

    local showDisc = settings:get("showDiscovery") ~= false
    if els.discText then
        els.discText.layout.props.position = v2(compassX, ss.y * 0.22)
        els.discText.layout.props.size = v2(cw, 36)
    end
    if els.discLine then
        els.discLine.layout.props.position = v2(compassX + (cw - 240) / 2, ss.y * 0.22 + 46)
    end
    if not showDisc then discTimer = 0 end

    if discTimer > 0 then
        discTimer = discTimer - dt
        local a
        if discTimer > LOC_SHOW_TIME - 0.8 then
            a = (LOC_SHOW_TIME - discTimer) / 0.8
        elseif discTimer < 1.2 then
            a = discTimer / 1.2
        else
            a = 1
        end
        discAlpha = a
        if els.discText then
            els.discText.layout.props.alpha = discAlpha
            els.discText.layout.props.visible = discAlpha > 0.01
            els.discText:update()
        end
        if els.discLine then
            els.discLine.layout.props.alpha = discAlpha * 0.5
            els.discLine.layout.props.visible = discAlpha > 0.01
            els.discLine:update()
        end
    else
        if els.discText then
            els.discText.layout.props.visible = false
            els.discText:update()
        end
        if els.discLine then
            els.discLine.layout.props.visible = false
            els.discLine:update()
        end
    end
end

return {
    engineHandlers = {
        onFrame = function(dt)
            local now = core.getRealTime()
            if now - lastFrame < 0.016 then return end
            local elapsed = now - lastFrame
            lastFrame = now

            local mode = I.UI.getMode()
            local compassEnabled = settings:get("compassEnabled")
            if compassEnabled == nil then compassEnabled = true end

            if (mode ~= nil and mode ~= "Interface") or not compassEnabled then
                for _, el in pairs(els) do
                    if el and el.layout then
                        el.layout.props.visible = false
                        pcall(function() el:update() end)
                    end
                end
                return
            end

            if not built then buildAll() end
            updateLocation(elapsed)
        end,

        onActive = function()
            els = {}
            built = false
        end,
    },
}
