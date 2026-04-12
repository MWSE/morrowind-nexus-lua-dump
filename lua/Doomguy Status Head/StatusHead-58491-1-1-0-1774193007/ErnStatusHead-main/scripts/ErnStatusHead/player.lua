--[[
ErnStatusHead for OpenMW.
Copyright (C) 2026 Erin Pentecost

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
local MOD_NAME = require("scripts.ErnStatusHead.ns")
local pself = require("openmw.self")
local util = require('openmw.util')
local async = require("openmw.async")
local ui = require('openmw.ui')
local interfaces = require("openmw.interfaces")
local settings = require("scripts.ErnStatusHead.settings")

local baseSize = 64

local attacking = false

local attackGroups = {
    weapononehand = true,
    weapontwohand = true,
    bowandarrow = true,
    handtohand = true,
    -- darts? crossbow?
}

local castKeyStart = {
    ["target start"] = true,
    ["touch start"] = true,
}
local castKeyEnd = {
    ["target release"] = true,
    ["touch release"] = true,
}

local function hasSuffix(str, suffix)
    return suffix == "" or str:sub(- #suffix) == suffix
end
local function hasPrefix(str, prefix)
    return prefix == "" or str:sub(1, #prefix) == prefix
end

interfaces.AnimationController.addTextKeyHandler("", function(groupname, key)
    if attackGroups[groupname] then
        print(key)
        if hasPrefix(key, "unequip") or hasPrefix(key, "equip") then
            attacking = false
        elseif hasSuffix(key, "start") then
            attacking = true
        elseif hasSuffix(key, "stop") then
            attacking = false
        end
    elseif groupname == "spellcast" then
        if castKeyStart[key] then
            attacking = true
        elseif castKeyEnd[key] then
            attacking = false
        end
    end
end)


local function layerElem(path)
    return ui.create {
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = path },
            relativePosition = util.vector2(0, 0),
            size = util.vector2(baseSize * settings.main.scale, baseSize * settings.main.scale)
        },
        events = {},
    }
end

local function updateSize(elem)
    elem.layout.props.size = util.vector2(baseSize * settings.main.scale, baseSize * settings.main.scale)
    elem:update()
end

local heads = {
    hurt_somewhat = layerElem("Textures/ErnStatusHead/hurt_somewhat.png"),
    hurt_medium = layerElem("Textures/ErnStatusHead/hurt_medium.png"),
    hurt_very = layerElem("Textures/ErnStatusHead/hurt_very.png"),
    malice = layerElem("Textures/ErnStatusHead/malice.png"),
    malice_hurt = layerElem("Textures/ErnStatusHead/malice_hurt.png"),
    neutral = layerElem("Textures/ErnStatusHead/neutral.png"),
    tired = layerElem("Textures/ErnStatusHead/tired.png"),
}

local fatigueStat = pself.type.stats.dynamic.fatigue(pself)
local healthStat = pself.type.stats.dynamic.health(pself)
local magickaStat = pself.type.stats.dynamic.magicka(pself)

local function selectHead()
    if healthStat.current < healthStat.base * .2 then
        return "hurt_very"
    elseif healthStat.current < healthStat.base * .5 then
        return "hurt_medium"
    elseif healthStat.current < healthStat.base * .8 then
        if attacking then
            return "malice_hurt"
        end
        return "hurt_somewhat"
    elseif attacking then
        return "malice"
    elseif fatigueStat.current < (fatigueStat.base * settings.main.fatigueWarning) then
        return "tired"
    end
    return "neutral"
end

local earrings = {
    left = layerElem("Textures/ErnStatusHead/earrings_left.png"),
    down = layerElem("Textures/ErnStatusHead/earrings_down.png"),
    right = layerElem("Textures/ErnStatusHead/earrings_right.png"),
}

local function selectearrings()
    if pself.controls.sideMovement > 0.5 then
        return "left"
    elseif pself.controls.sideMovement < -0.5 then
        return "right"
    else
        return "down"
    end
end

local gem = layerElem("Textures/ErnStatusHead/gem.png")

local function lerpColor(a, b, t)
    return util.color.rgba(
        a.r + (b.r - a.r) * t,
        a.g + (b.g - a.g) * t,
        a.b + (b.b - a.b) * t,
        a.a + (b.a - a.a) * t
    )
end


local noMagickaColor = util.color.hex("173e56")
local maxMagickaColor = util.color.hex("fedf63")

local function setGemColor()
    gem.layout.props.color = lerpColor(noMagickaColor, maxMagickaColor, magickaStat.current / magickaStat.base)
    gem:update()
end

local rootElement = ui.create {
    name = "rootStatusHead",
    layer = settings.main.lock and 'Scene' or 'Modal',
    type = ui.TYPE.Widget,
    props = {
        relativePosition = util.vector2(settings.main.positionX, settings.main.positionY),
        size = util.vector2(baseSize * settings.main.scale, baseSize * settings.main.scale),
        anchor = util.vector2(0.5, 0.5),
        visible = true,
        autoSize = false,
    },
    content = ui.content {}
}
local screenSize = ui.screenSize()
rootElement.layout.events = {
    mousePress = async:callback(function(data, elem)
        if data.button == 1 then -- Left mouse button
            if settings.main.lock then
                return
            end
            print("left click start head")
            if not elem.userData then
                elem.userData = {}
            end
            elem.userData.isDragging = true
            elem.userData.dragStartPosition = data.position
            elem.userData.windowStartPosition = rootElement.layout.props.relativePosition or util.vector2(0, 0)
        end
        rootElement:update()
    end),

    mouseRelease = async:callback(function(data, elem)
        print("left click release head")
        if elem.userData then
            elem.userData.isDragging = false
        end
        rootElement:update()
    end),

    mouseMove = async:callback(function(data, elem)
        if elem.userData and elem.userData.isDragging then
            -- Calculate new position based on mouse movement
            local deltaX = data.position.x - elem.userData.dragStartPosition.x
            local deltaY = data.position.y - elem.userData.dragStartPosition.y
            local newPosition = util.vector2(
                elem.userData.windowStartPosition.x + deltaX / screenSize.x,
                elem.userData.windowStartPosition.y + deltaY / screenSize.y
            )
            settings.main.section:set("positionX", newPosition.x)
            settings.main.section:set("positionY", newPosition.y)
            print("x: " .. tostring(newPosition.x) .. ", y: " .. tostring(newPosition.y))
            --rootElement.layout.props.relativePosition = newPosition
            rootElement:update()
        end
    end),
}

settings.main.subscribe(async:callback(function(_, key)
    for k, v in pairs(heads) do
        updateSize(v)
    end
    for k, v in pairs(earrings) do
        updateSize(v)
    end
    updateSize(gem)

    -- root stuff
    rootElement.layout.props.layer = settings.main.lock and 'Scene' or 'Modal'
    rootElement.layout.props.relativePosition = util.vector2(settings.main.positionX, settings.main.positionY)
    updateSize(rootElement)
end))

local delta = 0.2
local function onUpdate(dt)
    delta = delta - dt
    if delta < 0 then
        setGemColor()
        rootElement.layout.props.visible = interfaces.UI.isHudVisible()
        rootElement.layout.content = ui.content({
            heads[selectHead()],
            earrings[selectearrings()],
            gem
        })
        rootElement:update()
        delta = 0.2
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
