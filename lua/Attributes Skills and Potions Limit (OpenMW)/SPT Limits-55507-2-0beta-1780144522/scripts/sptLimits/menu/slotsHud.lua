local ui = require("openmw.ui")
local util = require("openmw.util")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")

local config = require("scripts.sptLimits.shared.config")

local maxSlots = config.maxSlotDisplay
local normalColor = util.color.rgb(0.79, 0.65, 0.38)
local overflowColor = util.color.rgb(0.85, 0.20, 0.20)
local baseX = -12
local baseY = -90 - 32 + 4
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

local elements = {}
for i = 1, maxSlots do
    elements[i] = ui.create({
        layer = "HUD",
        type = ui.TYPE.Flex,
        props = {
            relativePosition = util.vector2(1, 1),
            anchor = util.vector2(1, 1),
            position = util.vector2(baseX, baseY - (i - 1) * slotSpacing),
            horizontal = true,
            align = ui.ALIGNMENT.Center,
            visible = false,
        },
        content = ui.content({
            {
                name = "text",
                type = ui.TYPE.Text,
                props = {
                    text = "",
                    textSize = 16,
                    textColor = normalColor,
                    textFont = "Default",
                },
            },
            {
                name = "iconBox",
                type = ui.TYPE.Widget,
                template = interfaces.MWUI.templates.borders,
                props = {
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
            },
        }),
    })
end

local initialized = false
local lastPosition = nil

local function applyPosition(position)
    if position == lastPosition then
        return
    end
    lastPosition = position

    if position == "top" then
        for i = 1, maxSlots do
            elements[i].layout.props.relativePosition = util.vector2(1, 0)
            elements[i].layout.props.anchor = util.vector2(1, 0)
            elements[i].layout.props.position = util.vector2(baseX, 12 + (i - 1) * slotSpacing)
        end
    else
        for i = 1, maxSlots do
            elements[i].layout.props.relativePosition = util.vector2(1, 1)
            elements[i].layout.props.anchor = util.vector2(1, 1)
            elements[i].layout.props.position = util.vector2(baseX, baseY - (i - 1) * slotSpacing)
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

    local stateSection = storage.playerSection("sptLimitsState")
    local trackingMode = stateSection:get("trackingMode")

    if trackingMode ~= "slots" or hudCounterMode == "hidden" or potionLimitEnabled == false then
        for i = 1, maxSlots do
            if elements[i].layout.props.visible then
                elements[i].layout.props.visible = false
                elements[i]:update()
            end
        end
        return
    end

    local hudPosition = settingsSection:get("hudPosition") or "bottom"
    applyPosition(hudPosition)

    local slotCount = stateSection:get("slotCount") or 4
    local overflowOccupied = stateSection:get("overflowOccupied") or false
    local totalSlots = slotCount + 1

    for i = 1, maxSlots do
        local el = elements[i]
        if i > totalSlots then
            if el.layout.props.visible then
                el.layout.props.visible = false
                el:update()
            end
        else
            local countdown = stateSection:get("slot" .. i .. "Countdown") or 0
            local iconPath = stateSection:get("slot" .. i .. "Icon") or ""
            local isOverflow = (i == totalSlots)
            local shouldShow = countdown >= 0.05 or (isOverflow and overflowOccupied)

            if shouldShow then
                el.layout.props.visible = true

                local iconBox = el.layout.content[2]
                local tex = getTexture(iconPath)
                if tex then
                    iconBox.props.visible = true
                    iconBox.content[1].props.resource = tex
                else
                    iconBox.props.visible = false
                end

                local textWidget = el.layout.content[1]
                local color = isOverflow and overflowColor or normalColor
                textWidget.props.textColor = color
                if hudCounterMode == "minimal" then
                    textWidget.props.text = ""
                elseif countdown >= 0.05 then
                    textWidget.props.text = string.format("%.1fs ", countdown)
                else
                    textWidget.props.text = "0.0s "
                end

                el:update()
            else
                if el.layout.props.visible then
                    el.layout.props.visible = false
                    el:update()
                end
            end
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
