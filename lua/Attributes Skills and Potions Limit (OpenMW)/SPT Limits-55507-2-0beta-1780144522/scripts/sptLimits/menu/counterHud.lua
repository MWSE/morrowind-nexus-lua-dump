local ui = require("openmw.ui")
local util = require("openmw.util")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")

local config = require("scripts.sptLimits.shared.config")

local maxIcons = config.maxSlotDisplay
local normalColor = util.color.rgb(0.79, 0.65, 0.38)
local overdoseColor = util.color.rgb(0.85, 0.20, 0.20)
local slotSpacing = 22
local iconSize = 16

local textureCache = {}

local function getTexture(path)
    if not path or path == "" then
        return nil
    end
    if not textureCache[path] then
        textureCache[path] = ui.texture({ path = path })
    end
    return textureCache[path]
end

local textElement = ui.create({
    layer = "HUD",
    type = ui.TYPE.Text,
    props = {
        relativePosition = util.vector2(1, 1),
        anchor = util.vector2(1, 1),
        position = util.vector2(-12, -90 - 32 + 4),
        text = "",
        textSize = 16,
        textColor = normalColor,
        textFont = "Default",
        visible = false,
    },
})

local iconElements = {}
for i = 1, maxIcons do
    iconElements[i] = ui.create({
        layer = "HUD",
        type = ui.TYPE.Widget,
        template = interfaces.MWUI.templates.borders,
        props = {
            relativePosition = util.vector2(1, 1),
            anchor = util.vector2(1, 1),
            position = util.vector2(-12, -90 - 32 + 4 - i * slotSpacing),
            size = util.vector2(iconSize + 4, iconSize + 4),
            visible = false,
        },
        content = ui.content({
            {
                name = "icon",
                type = ui.TYPE.Image,
                props = {
                    size = util.vector2(iconSize, iconSize),
                },
            },
        }),
    })
end

local initialized = false
local lastPosition = nil
local lastMode = nil

local function parseIcons(iconsStr)
    if not iconsStr or iconsStr == "" then
        return {}
    end
    local icons = {}
    local pos = 1
    while true do
        local sep = iconsStr:find("|", pos, true)
        if sep then
            icons[#icons + 1] = iconsStr:sub(pos, sep - 1)
            pos = sep + 1
        else
            icons[#icons + 1] = iconsStr:sub(pos)
            break
        end
    end
    return icons
end

local function applyPosition(position, mode)
    if position == lastPosition and mode == lastMode then
        return
    end
    lastPosition = position
    lastMode = mode

    local iconOffset = mode == "minimal" and 0 or 1

    if position == "top" then
        local topBaseY = 12
        textElement.layout.props.relativePosition = util.vector2(1, 0)
        textElement.layout.props.anchor = util.vector2(1, 0)
        textElement.layout.props.position = util.vector2(-12, topBaseY)
        for i = 1, maxIcons do
            iconElements[i].layout.props.relativePosition = util.vector2(1, 0)
            iconElements[i].layout.props.anchor = util.vector2(1, 0)
            iconElements[i].layout.props.position = util.vector2(-12, topBaseY + (i - 1 + iconOffset) * slotSpacing)
        end
    else
        local bottomBaseY = -90 - 32 + 4
        textElement.layout.props.relativePosition = util.vector2(1, 1)
        textElement.layout.props.anchor = util.vector2(1, 1)
        textElement.layout.props.position = util.vector2(-12, bottomBaseY)
        for i = 1, maxIcons do
            iconElements[i].layout.props.relativePosition = util.vector2(1, 1)
            iconElements[i].layout.props.anchor = util.vector2(1, 1)
            iconElements[i].layout.props.position = util.vector2(-12, bottomBaseY - (i - 1 + iconOffset) * slotSpacing)
        end
    end
end

local function hideAll()
    if textElement.layout.props.visible then
        textElement.layout.props.visible = false
        textElement:update()
    end
    for i = 1, maxIcons do
        if iconElements[i].layout.props.visible then
            iconElements[i].layout.props.visible = false
            iconElements[i]:update()
        end
    end
end

local function tick()
    local settingsSection = storage.playerSection("sptLimitsPotions")
    local hudCounterMode = settingsSection:get("hudCounterMode")
    local potionLimitEnabled = settingsSection:get("potionLimitEnabled")

    if hudCounterMode == nil and potionLimitEnabled == nil then
        if not initialized then
            return
        end
    else
        initialized = true
    end

    if hudCounterMode == "hidden" or potionLimitEnabled == false then
        hideAll()
        return
    end

    local hudPosition = settingsSection:get("hudPosition") or "bottom"
    applyPosition(hudPosition, hudCounterMode)

    local stateSection = storage.playerSection("sptLimitsState")
    local trackingMode = stateSection:get("trackingMode")
    if trackingMode == "slots" then
        hideAll()
        return
    end

    local drinkCount = stateSection:get("drinkCount") or 0
    local countdown = stateSection:get("countdown") or 0
    local potionLimit = stateSection:get("potionLimit") or 3
    local iconsStr = stateSection:get("drinkIcons") or ""
    local icons = parseIcons(iconsStr)

    if drinkCount == 0 then
        hideAll()
        return
    end

    local isOverdose = drinkCount > potionLimit

    if hudCounterMode == "minimal" then
        textElement.layout.props.visible = false
        textElement:update()
    else
        textElement.layout.props.visible = true
        textElement.layout.props.text = string.format("%.1fs %d/%d", countdown, drinkCount, potionLimit)
        textElement.layout.props.textColor = isOverdose and overdoseColor or normalColor
        textElement:update()
    end

    local displayCount = math.min(#icons, maxIcons)
    for i = 1, maxIcons do
        local el = iconElements[i]
        if i > displayCount then
            if el.layout.props.visible then
                el.layout.props.visible = false
                el:update()
            end
        else
            el.layout.props.visible = true
            local tex = getTexture(icons[i])
            if tex then
                el.layout.content[1].props.resource = tex
            else
                el.layout.content[1].props.resource = nil
            end
            el:update()
        end
    end
end

return {
    engineHandlers = {
        onFrame = function()
            tick()
        end,
    },
}
