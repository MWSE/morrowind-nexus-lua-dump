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
local imageAtlas   = require('scripts.LivelyMap.h3.imageAtlas')
local aux_util     = require('openmw_aux.util')
local MOD_NAME     = require("scripts.LivelyMap.ns")

--- Fog is horribly, horribly inefficient right now.

local settingCache = {
    fog = settings.main.fog,
    debug = settings.main.debug,
}
settings.main.subscribe(async:callback(function(_, key)
    settingCache[key] = settings.main[key]
end))

local TOTAL_TILES    = 30
local FOG_SIZE       = 5

local smokeAtlas     = imageAtlas.constructAtlas({
    totalTiles = TOTAL_TILES,
    tilesPerRow = 6,
    atlasPath = "textures/LivelyMap/smoke_atlas.png",
    tileSize = util.vector2(256, 256), -- 1279 length, 1536 width. 5 rows, 6 cols
    create = true,
})

---@type MeshAnnotatedMapData?
local currentMapData = nil

local fogIcons       = {}

---@class Vec2
---@field x number
---@field y number

--- Return a set of non-overlapping Extents which don't contain any cells in "seen".
--- The union of all returned Extents and "seen" should exactly equal the passed-in "extents".
--- Every Extent should be as large as possible (best effort).
---@param extents Extents
---@param seen Vec2[]
---@return Extents[]
local function mergeVisibleCells(extents, seen)
    -- Build a lookup of blocked (seen) cells
    local blocked = {}
    for _, v in ipairs(seen) do
        blocked[v.y] = blocked[v.y] or {}
        blocked[v.y][v.x] = true
    end

    -- Track remaining free cells
    local free = {}
    for y = extents.Bottom, extents.Top do
        free[y] = {}
        for x = extents.Left, extents.Right do
            free[y][x] = not (blocked[y] and blocked[y][x])
        end
    end

    local results = {}

    for y = extents.Bottom, extents.Top do
        for x = extents.Left, extents.Right do
            if free[y][x] then
                -- Find maximum square size
                local size = 1

                while true do
                    local next = size + 1
                    local maxX = x + next - 1
                    local maxY = y + next - 1

                    if maxX > extents.Right or maxY > extents.Top then
                        break
                    end

                    -- Check new row
                    for ix = x, maxX do
                        if not free[maxY][ix] then
                            goto stop
                        end
                    end

                    -- Check new column
                    for iy = y, maxY - 1 do
                        if not free[iy][maxX] then
                            goto stop
                        end
                    end

                    size = next
                end
                ::stop::

                local right = x + size - 1
                local top   = y + size - 1

                -- Consume the square
                for iy = y, top do
                    for ix = x, right do
                        free[iy][ix] = false
                    end
                end

                results[#results + 1] = {
                    Left   = x,
                    Right  = right,
                    Bottom = y,
                    Top    = top,
                }
            end
        end
    end

    --print(aux_util.deepToString(results, 3))
    return results
end


-- creates an unattached icon and registers it.
local idxSeed = 1
local function newIcon()
    idxSeed = ((idxSeed + 7) % TOTAL_TILES) + 1
    local element = smokeAtlas:spawn({
        visible = false,
        relativePosition = util.vector2(0.7, 0.7),
        anchor = util.vector2(0.5, 0.5),
        relativeSize = iutil.iconSize() * FOG_SIZE,
    }, idxSeed)

    local icon = {
        element = element,
        cachedPos = nil,
        size = 1,
        pos = function(s)
            return s.cachedPos
        end,
        ---@param posData ViewportData
        onDraw = function(s, posData, parentAspectRatio)
            -- s is this icon.
            if s.cachedPos == nil or (not posData.viewportPos.onScreen) then
                s.element.layout.props.visible = false
            else
                s.element.layout.props.relativeSize = iutil.iconSize(posData, parentAspectRatio) * FOG_SIZE * s.size
                s.element.layout.props.visible = true
                s.element.layout.props.relativePosition = posData.viewportPos.pos
            end
            --s.element:update()
        end,
        onHide = function(s)
            -- s is this icon.
            s.element.layout.props.visible = false
            s.element:update()
        end,
        priority = -5000,
    }
    icon.element:update()
    interfaces.LivelyMapDraw.registerIcon(icon)
    return icon
end

local iconPool = pool.create(newIcon, settingCache.fog and 100 or 0)

local function makeIcon(cachedPos, size)
    local icon = iconPool:obtain()
    icon.pool = iconPool
    icon.cachedPos = cachedPos
    icon.size = size
    table.insert(fogIcons, icon)
end

---@param extents Extents
local function makeIconsPerCell(extents)
    if not settingCache.fog then
        return
    end
    for x = extents.Left - 1, extents.Right + 1 do
        for y = extents.Bottom - 1, extents.Top + 1 do
            --print("Making for fr x=" .. tostring(x) .. ", y=" .. tostring(y))
            makeIcon(mutil.cellPosToWorldPos({ x = x + .5, y = y + .5, z = 0 }))
        end
    end
end

---@param extents Extents
local function makeIcons(extents)
    if not settingCache.fog then
        return
    end
    local center = {
        x = (extents.Left + extents.Right) / 2,
        y = (extents.Bottom + extents.Top) / 2,
        z = 0,
    }
    makeIcon(mutil.cellPosToWorldPos(center), 1 + extents.Right - extents.Left)
end

local function freeIcons()
    for _, icon in ipairs(fogIcons) do
        icon.element.layout.props.visible = false
        icon.cachedPos = nil
        icon.currentIdx = nil
        icon.pool:free(icon)
    end
    fogIcons = {}
end

interfaces.LivelyMapToggler.onMapMoved(function(mapData)
    print("map up")
    currentMapData = mapData
    local seen = {}
    makeIcons(interfaces.LivelyMapDraw.getVisibleExtent(), seen)
end)

interfaces.LivelyMapToggler.onMapHidden(function(mapData)
    print("map down")
    currentMapData = mapData
    freeIcons()
end)

local seen = {
    {
        -- todo: this position is bad, get it from global
        x = math.floor(pself.position.x / mutil.CELL_SIZE),
        y = math.floor(pself.position.y / mutil.CELL_SIZE),
    }
}

---@type Extents
local lastExtent = nil
local function onRenderStart()
    if not currentMapData then
        return
    end
    ---@type Extents
    local newExtent = interfaces.LivelyMapDraw.getVisibleExtent()
    newExtent.Bottom = newExtent.Bottom - 1
    if (not lastExtent) or lastExtent.Bottom ~= newExtent.Bottom or lastExtent.Left ~= newExtent.Left or lastExtent.Right ~= newExtent.Right or lastExtent.Top ~= newExtent.Top then
        lastExtent = newExtent
        freeIcons()
        for _, block in ipairs(mergeVisibleCells(newExtent, seen)) do
            makeIcons(block)
        end
    end
end

interfaces.LivelyMapDraw.onRenderStart(onRenderStart)


return {}
