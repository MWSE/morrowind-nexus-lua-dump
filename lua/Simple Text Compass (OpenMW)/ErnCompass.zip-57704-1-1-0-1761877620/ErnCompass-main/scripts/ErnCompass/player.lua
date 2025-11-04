--[[
ErnOneStick for OpenMW.
Copyright (C) 2025 Erin Pentecost

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
local MOD_NAME = require("scripts.ErnCompass.ns")
local camera = require('openmw.camera')
local util = require('openmw.util')
local interfaces = require("openmw.interfaces")
local ui = require('openmw.ui')
local storage = require("openmw.storage")
local async = require('openmw.async')
local pself = require("openmw.self")

local anchors = { "topleft", "topright", "bottomleft", "bottomright" }

interfaces.Settings.registerPage {
    key = MOD_NAME,
    l10n = MOD_NAME,
    name = "name",
    description = "description"
}

interfaces.Settings.registerGroup {
    key = 'Settings' .. MOD_NAME,
    l10n = MOD_NAME,
    name = "modSettingsAdminTitle",
    page = MOD_NAME,
    permanentStorage = true,
    settings = { {
        key = "anchor",
        name = "anchor_name",
        description = "anchor_description",
        argument = { items = anchors, l10n = MOD_NAME },
        default = anchors[4],
        renderer = "select",
    }, {
        key = "offsetX",
        name = "offsetX_name",
        default = 46,
        renderer = "number",
        argument = {
            integer = true,
            min = -500,
            max = 500
        }
    }, {
        key = "offsetY",
        name = "offsetY_name",
        default = 85,
        renderer = "number",
        argument = {
            integer = true,
            min = -500,
            max = 500
        }
    }, {
        key = "size",
        name = "size_name",
        default = 16,
        renderer = "number",
        argument = {
            integer = true,
            min = 1,
            max = 40
        }
    },
        {
            key = "invertColor",
            name = "invertColorName",
            default = false,
            renderer = "checkbox",
        },
    }
}

local adminSettings = storage.playerSection('Settings' .. MOD_NAME)
local anchor
local offsetX
local offsetY
local size
local invertColor
local function persistSettings()
    anchor = adminSettings:get("anchor")
    offsetX = adminSettings:get("offsetX")
    offsetY = adminSettings:get("offsetY")
    size = adminSettings:get("size")
    invertColor = adminSettings:get("invertColor")
end
persistSettings()

local north = util.vector3(0, 1, 0)
local west = util.vector3(1, 0, 0)

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

local function anchorVec()
    --(0,0) is top left of screen.
    if anchor == anchors[1] then
        return util.vector2(0, 0)
    elseif anchor == anchors[2] then
        return util.vector2(1, 0)
    elseif anchor == anchors[3] then
        return util.vector2(0, 1)
    elseif anchor == anchors[4] then
        return util.vector2(1, 1)
    end
    error("bad value for anchor: " .. tostring(anchor))
end

local lightColor = util.color.rgb(223 / 255, 201 / 255, 159 / 255)
local darkColor = util.color.rgb(96 / 255, 3 / 255, 0)

local function makeCompass()
    local anchorV = anchorVec()
    local posSwap = util.vector2(1, 1) + (anchorV * (-2))
    local pos = util.vector2(offsetX, offsetY):emul(posSwap)

    local textColor = lightColor
    local shadowColor = darkColor
    if invertColor then
        textColor = darkColor
        shadowColor = lightColor
    end

    local box = ui.create {
        name = 'compass',
        layer = 'HUD',
        type = ui.TYPE.Container,
        --template = interfaces.MWUI.templates.boxSolid,
        props = {
            position = pos,
            anchor = util.vector2(0.5, 0.5),
            relativePosition = anchorV,
        },
        content = ui.content {
            {
                name = 'compass',
                layer = 'HUD',
                type = ui.TYPE.Text,
                template = interfaces.MWUI.templates.textHeader,
                props = {
                    textColor = textColor,
                    textShadowColor = shadowColor,
                    textShadow = true,
                    text = "???",
                    textSize = size
                },
            }
        }
    }
    return box
end

local compassElement = makeCompass()


adminSettings:subscribe(async:callback(function()
    persistSettings()

    compassElement:destroy()
    compassElement = makeCompass()
    compassElement:update()
end))

local function onUpdate(dt)
    -- Reduce calls to update UI.
    local changed = false

    local visible = interfaces.UI.isHudVisible() and pself.cell.isExterior
    if compassElement.layout.props.visible ~= visible then
        changed = true
        compassElement.layout.props.visible = visible
    end

    if visible then
        local facing = facingAs16wind(getFacing())
        if compassElement.layout.content.compass.props.text ~= facing then
            compassElement.layout.content.compass.props.text = facing
            changed = true
        end
    end

    if changed then
        compassElement:update()
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}
