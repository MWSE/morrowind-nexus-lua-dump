--[[
ErnOneStick for OpenMW.
Copyright (C) 2025 Erin Pentecost and hyacinth

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

camera = require('openmw.camera')
util = require('openmw.util')
I = require('openmw.interfaces')
ui = require('openmw.ui')
storage = require('openmw.storage')
async = require('openmw.async')
input = require('openmw.input')
self = require("openmw.self")
core = require('openmw.core')
v2 = util.vector2
types = require('openmw.types')

MODNAME = "compassHud"

local north = util.vector3(0, 1, 0)
local west = util.vector3(1, 0, 0)

function getColorFromGameSettings(colorTag)
    local result = core.getGMST(colorTag)
    if not result then
        return util.color.rgb(1, 1, 1)
    end
    local rgb = {}
    for color in string.gmatch(result, '(%d+)') do
        table.insert(rgb, tonumber(color))
    end
    if #rgb ~= 3 then
        return util.color.rgb(1, 1, 1)
    end
    return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

settingsSection = storage.playerSection('Settings' .. MODNAME)
require('scripts.ErnCompass.compass_settings')

compassHud = nil
compassText = nil

local function getFacing()
    local facing = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
    -- dot product returns 0 if at 90*, 1 if codirectional, -1 if opposite.
    -- 1 = north
    -- -1 = south
    -- 1 = east
    -- -1 = west
    return {
        northSouth = facing:dot(north),
        eastWest = facing:dot(west),
    }
end

local function facingAs16wind(facing)
    -- Compute the facing angle in radians.
    -- atan2(y, x) gives 0 at east, π/2 at north.
    local angle = math.atan2(facing.northSouth, facing.eastWest)

    -- Convert to degrees, where 0° = East, 90° = North.
    local deg = math.deg(angle)
    if deg < 0 then deg = deg + 360 end

    -- 16-wind compass labels, spaced every 22.5°
    local directions = {
        "E", "ENE", "NE", "NNE",
        "N", "NNW", "NW", "WNW",
        "W", "WSW", "SW", "SSW",
        "S", "SSE", "SE", "ESE",
    }

    -- Each sector is 22.5° wide. Offset by 11.25° so 0° centers on "E".
    local index = math.floor((deg + 11.25) / 22.5) % 16 + 1
    return directions[index]
end

function updateCompass(force)
    if not compassText then return end

    local faceString
    local changed = false
    local facing = facingAs16wind(getFacing())

    if compassHud.layout.content.compassFlex.content.compassText.props.text ~= facing then
        compassHud.layout.content.compassFlex.content.compassText.props.text = facing
        changed = true
    end
    refreshUiVisibility()
end

local function createCompassHud()
    if compassHud then
        compassHud:destroy()
        compassHud = nil
        compassText = nil
    end

    local template = {
        content = ui.content {}
    }

    compassHudBackground = {
        type = ui.TYPE.Image,
        name = "compassHudBackground",
        props = {
            resource = ui.texture { path = 'black' },
            relativeSize = v2(1, 1),
            alpha = BACKGROUND_ALPHA
        }
    }

    template.content:add(compassHudBackground)
    compassHud = ui.create({
        type = ui.TYPE.Container,
        layer = HUD_LOCK and 'Scene' or 'Modal',
        name = "compassHud",
        template = template,
        props = {
            position = v2(HUD_X_POS, HUD_Y_POS),
            anchor = util.vector2(0.5, 0.5),
            autoSize = true,
        },
        content = ui.content {},
        userData = {
            windowStartPosition = v2(HUD_X_POS, HUD_Y_POS),
        }
    })
    compassHud.layout.events = {
        mousePress = async:callback(function(data, elem)
            if data.button == 1 then -- Left mouse button
                if not elem.userData then
                    elem.userData = {}
                end
                elem.userData.isDragging = true
                elem.userData.dragStartPosition = data.position
                elem.userData.windowStartPosition = compassHud.layout.props.position or v2(0, 0)
            end
            compassHud:update()
        end),

        mouseRelease = async:callback(function(data, elem)
            if elem.userData then
                elem.userData.isDragging = false
            end
            compassHud:update()
        end),

        mouseMove = async:callback(function(data, elem)
            if elem.userData and elem.userData.isDragging then
                -- Calculate new position based on mouse movement
                local deltaX = data.position.x - elem.userData.dragStartPosition.x
                local deltaY = data.position.y - elem.userData.dragStartPosition.y
                local newPosition = v2(
                    elem.userData.windowStartPosition.x + deltaX,
                    elem.userData.windowStartPosition.y + deltaY
                )
                settingsSection:set("HUD_X_POS", math.floor(newPosition.x))
                settingsSection:set("HUD_Y_POS", math.floor(newPosition.y))
                --saveData.windowPos = newPosition
                compassHud.layout.props.position = newPosition
                compassHud:update()
            end
        end),
    }
    compassFlex = {
        type = ui.TYPE.Flex,
        name = "compassFlex",
        props = {
            horizontal = false,
            autoSize = true,
            size = v2(1, 1),
            arrange = ui.ALIGNMENT.Start
        },
        content = ui.content {}
    }
    compassHud.layout.content:add(compassFlex)

    compassText = {
        type = ui.TYPE.Text,
        name = "compassText",
        props = {
            text = "321",
            textColor = TEXT_COLOR,
            textShadow = true,
            textShadowColor = util.color.rgba(0, 0, 0, 0.9),
            textAlignV = ui.ALIGNMENT.Start,
            textAlignH = ui.ALIGNMENT.Start,
            textSize = FONT_SIZE,
        },
    }

    compassFlex.content:add(compassText)
    updateCompass(true)
end

function onMouseWheel(vertical)
    if compassHud.layout.userData.isDragging then
        if input.isShiftPressed() then
            settingsSection:set("BACKGROUND_ALPHA", math.min(1, math.max(0, BACKGROUND_ALPHA + vertical / 10)))
        else
            settingsSection:set("FONT_SIZE", math.max(5, FONT_SIZE + vertical)) -- minimum 5 to keep readable
        end
    end
end

function chargenFinished()
    if saveData.chargenFinished then
        return true
    end
    if types.Player.getBirthSign(self) ~= "" then
        saveData.chargenFinished = true
        return true
    end
    if types.Player.isCharGenFinished(self) then
        saveData.chargenFinished = true
        return true
    end
    playerItems = types.Container.inventory(self):getAll()
    for a, b in pairs(playerItems) do
        if b.recordId == "chargen statssheet" then
            saveData.chargenFinished = true
            return true
        end
    end
    return false
end

function onLoad(data)
    saveData = data or {}

    local layerId = ui.layers.indexOf("HUD")
    local hudLayerSize = ui.layers[layerId].size

    settingsSection:set("HUD_X_POS", math.floor(math.max(0, math.min(HUD_X_POS, hudLayerSize.x - FONT_SIZE * 2))))
    settingsSection:set("HUD_Y_POS", math.floor(math.max(0, math.min(HUD_Y_POS, hudLayerSize.y - FONT_SIZE))))

    createCompassHud()
end

input.registerTriggerHandler("ToggleHUD", async:callback(function()
    compassHud.layout.props.visible = I.UI.isHudVisible()
    compassHud:update()
end))

function onSave()
    return saveData
end

function refreshUiVisibility()
    if HUD_DISPLAY == "Always" then
        compassHud.layout.props.visible = I.UI.isHudVisible() and chargenFinished() and self.cell.isExterior
        compassHud:update()
    elseif HUD_DISPLAY == "Never" then
        compassHud.layout.props.visible = false and chargenFinished() and self.cell.isExterior
        compassHud:update()
    elseif HUD_DISPLAY == "Interface Only" then
        compassHud.layout.props.visible = currentUiMode == "Interface" and I.UI.isHudVisible() and chargenFinished() and
            self.cell.isExterior
        compassHud:update()
    elseif HUD_DISPLAY == "Hide on Interface" then
        compassHud.layout.props.visible = currentUiMode == nil and I.UI.isHudVisible() and chargenFinished() and
            self.cell.isExterior
        compassHud:update()
    else --if HUD_DISPLAY == "Hide on Dialogue Only" then
        compassHud.layout.props.visible = currentUiMode ~= "Dialogue" and I.UI.isHudVisible() and chargenFinished() and
            self.cell.isExterior
        compassHud:update()
    end
end

function UiModeChanged(data)
    if not compassHud then return end
    -- print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')
    currentUiMode = data.newMode
    refreshUiVisibility()
    shouldRefreshUiVisibility = 3
end

local function onFrame()
    if shouldRefreshUiVisibility then
        shouldRefreshUiVisibility = shouldRefreshUiVisibility - 1
        if shouldRefreshUiVisibility == 0 then
            shouldRefreshUiVisibility = nil
            refreshUiVisibility()
        end
    end

    updateCompass()
end

return {
    engineHandlers = {
        onInit = onLoad,
        onLoad = onLoad,
        onSave = onSave,
        onMouseWheel = onMouseWheel,
        onFrame = onFrame,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
    }
}
