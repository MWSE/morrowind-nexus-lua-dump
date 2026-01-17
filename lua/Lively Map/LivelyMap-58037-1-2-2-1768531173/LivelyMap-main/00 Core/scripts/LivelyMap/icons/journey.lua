--[[
LivelyMap for OpenMW.
Copyright (C) Erin Pentecost 2025

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
local interfaces   = require('openmw.interfaces')
local ui           = require('openmw.ui')
local util         = require('openmw.util')
local pself        = require("openmw.self")
local types        = require("openmw.types")
local core         = require("openmw.core")
local nearby       = require("openmw.nearby")
local iutil        = require("scripts.LivelyMap.icons.iutil")
local pool         = require("scripts.LivelyMap.pool.pool")
local settings     = require("scripts.LivelyMap.settings")
local mutil        = require("scripts.LivelyMap.mutil")
local async        = require("openmw.async")
local aux_util     = require('openmw_aux.util')
local MOD_NAME     = require("scripts.LivelyMap.ns")

local settingCache = {
    palleteColor1 = settings.main.palleteColor1,
    palleteColor2 = settings.main.palleteColor2,
    drawLimitNeravarinesJourney = settings.main.drawLimitNeravarinesJourney,
    debug = settings.main.debug,
}
settings.main.subscribe(async:callback(function(_, key)
    settingCache[key] = settings.main[key]
end))


local mapUp        = false
local pathIcons    = {}

local myPaths      = nil
local minimumIndex = 1

local pathIcon     = "textures/LivelyMap/journey.png"

-- creates an unattached icon and registers it.
local function newIcon()
    local element = ui.create {
        name = "path",
        type = ui.TYPE.Image,
        props = {
            visible = false,
            relativePosition = util.vector2(0.2, 0.2),
            anchor = util.vector2(0.5, 0.5),
            relativeSize = iutil.iconSize(),
            color = settingCache.palleteColor2,
            resource = ui.texture {
                path = pathIcon,
            }
        },
        events = {
        },
    }
    local icon = {
        element = element,
        currentIdx = nil,
        partialStep = 0,
        cachedPos = nil,
        pos = function(s)
            return s.cachedPos
        end,
        ---@param posData ViewportData
        onDraw = function(s, posData, parentAspectRatio)
            -- s is this icon.
            if s.cachedPos == nil or (not posData.viewportPos.onScreen) then
                s.element.layout.props.visible = false
            else
                s.element.layout.props.relativeSize = iutil.iconSize(posData, parentAspectRatio) / 2
                s.element.layout.props.visible = true
                s.element.layout.props.relativePosition = posData.viewportPos.pos
            end
            --s.element:update()
        end,
        onHide = function(s)
            -- s is this icon.
            s.element.layout.props.visible = false
            --s.element:update()
        end,
        priority = -900,
    }
    icon.element:update()
    interfaces.LivelyMapDraw.registerIcon(icon)
    return icon
end

local iconPool = pool.create(newIcon, 0)

local function color(currentIdx)
    return mutil.lerpColor(settingCache.palleteColor2, settingCache.palleteColor1,
        currentIdx / (1 + #myPaths - minimumIndex))
end

local function makeIcon(startIdx)
    local floored = math.floor(startIdx)
    local icon = iconPool:obtain()
    local name = icon.element.layout.name
    print("made journey icon at index " .. startIdx .. ". name= " .. tostring(name))
    icon.element.layout.props.visible = false
    icon.element.layout.props.color = color(floored)
    icon.currentIdx = floored
    icon.partialStep = startIdx - floored
    icon.pool = iconPool
    table.insert(pathIcons, icon)

    if settings.main.debug then
        local registered = interfaces.LivelyMapDraw.getIcon(name)
        print("post-register: " .. aux_util.deepToString(registered, 2))
        print(aux_util.deepToString(registered.ref.element.layout, 3))
    end
end

local function makeIcons()
    myPaths = interfaces.LivelyMapPlayer.getPaths()
        [interfaces.LivelyMapPlayer.playerName].paths


    if settingCache.drawLimitNeravarinesJourney then
        local oldDuration = 4 * 60 * 60 * core.getGameTimeScale()
        local oldestTime = core.getGameTime() - oldDuration
        minimumIndex = mutil.binarySearchFirst(myPaths, function(p) return p.t > oldestTime end)
        --- hard limit to 1000
        if #myPaths - minimumIndex > 1000 then
            minimumIndex = #myPaths - 1000
        end
        --- don't limit too much if we haven't moved in a long time
        if minimumIndex >= #myPaths and #myPaths > 10 then
            minimumIndex = #myPaths - 10
        end
    else
        minimumIndex = 1
    end

    print("#myPaths: " .. tostring(#myPaths) .. ", minimumIndex:" .. minimumIndex)
    if #myPaths <= 0 or minimumIndex >= #myPaths then
        return
    end

    local totalPips = math.max(1, 10 * math.log(#myPaths - minimumIndex + 1))
    local stepSize = (#myPaths - minimumIndex + 1) / totalPips

    for i = minimumIndex, #myPaths, stepSize do
        makeIcon(i)
    end
end

local function freeIcons()
    for _, icon in ipairs(pathIcons) do
        icon.element.layout.props.visible = false
        icon.cachedPos = nil
        icon.currentIdx = nil
        icon.pool:free(icon)
    end
    pathIcons = {}
end

local displaying = false

interfaces.LivelyMapToggler.onMapMoved(function(mapData)
    print("map up")
    mapUp = true
end)

interfaces.LivelyMapToggler.onMapHidden(function(mapData)
    print("map down")
    if not mapData.swapped then
        print("map closed")
        mapUp = false
        displaying = false
        freeIcons()
    end
end)



--- how long it takes to move between two adjacent points.
local speed = 1.1

local function onUpdate(dt)
    -- Don't run if the map is not up.
    if not mapUp then
        return
    end

    if not displaying then
        return
    end

    -- Fake a duration if we're paused.
    if dt <= 0 then
        dt = core.getRealFrameDuration()
    end

    for _, icon in ipairs(pathIcons) do
        icon.partialStep = icon.partialStep + dt * speed
        local fullStep = math.floor(icon.partialStep)
        if fullStep >= 1 then
            --print("step " .. icon.currentIdx .. " done. pt: " .. icon.partialStep)
            icon.currentIdx = icon.currentIdx + fullStep
            icon.partialStep = icon.partialStep - fullStep
        end
        if icon.currentIdx >= #myPaths then
            icon.currentIdx = minimumIndex
        end
        if not myPaths[icon.currentIdx].x then
            error("bad path: " .. aux_util.deepToString(myPaths[icon.currentIdx], 3))
        end
        --print("pt: " .. icon.partialStep)
        icon.cachedPos = mutil.lerpVec3(myPaths[icon.currentIdx], myPaths[icon.currentIdx + 1], icon.partialStep)
        icon.element.layout.props.color = color(icon.currentIdx)
    end
end

return {
    interfaceName = MOD_NAME .. "JourneyIcons",
    interface = {
        version = 1,
        toggleJourney = function()
            if displaying then
                freeIcons()
            else
                makeIcons()
            end
            displaying = not displaying
        end,
    },
    engineHandlers = {
        onUpdate = onUpdate,
    },
}
