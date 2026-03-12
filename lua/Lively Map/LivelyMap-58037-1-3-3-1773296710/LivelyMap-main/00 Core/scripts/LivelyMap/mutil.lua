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
local MOD_NAME = require("scripts.LivelyMap.ns")
local storage = require('openmw.storage')
local mapData = storage.globalSection(MOD_NAME .. "_mapData")
local util = require('openmw.util')

local phi = 2 * math.pi
local eps = 1e-12

-- https://github.com/LuaLS/lua-language-server/wiki/Annotations

---@class HasID
---@field ID number

---@class Connection
---@field east number?
---@field west number?
---@field south number?
---@field north number?

---Extents are inclusive!
---@class Extents
---@field Top number
---@field Bottom number
---@field Left number
---@field Right number

---@class StoredMapData : HasID
---@field ID number
---@field Extents Extents
---@field ConnectedTo Connection
---@field CenterX number
---@field CenterY number

---Returns immutable map metadata.
---@param data string | number | HasID
---@return StoredMapData
local function getMap(data)
    if type(data) == "string" then
        -- find the full map data
        return mapData:asTable()[data]
    elseif type(data) == "number" then
        -- find the full map data
        return mapData:asTable()[tostring(data)]
    elseif type(data) == "table" then
        return mapData:asTable()[tostring(data.ID)]
    end
    error("getMap: unknown type")
end

---Returns immutable map metadata for the map closest to the provided cell coordinates.
---@param x number Cell grid X.
---@param y number Cell grid y.
---@return StoredMapData
local function getClosestMap(x, y)
    local myLocation = util.vector2(x, y)
    local closest = nil
    local closestDist = 0
    for _, v in pairs(mapData:asTable()) do
        local thisDist = (util.vector2(v.CenterX, v.CenterY) - myLocation):length2()
        if closest == nil then
            closest = v
            closestDist = thisDist
        else
            if thisDist < closestDist then
                closest = v
                closestDist = thisDist
            end
        end
    end
    return closest
end

--- getScale returns a number that is the scaling factor to use
--- with this map.
--- This is used to ensure that all extents have the same in-game
--- DPI.
---@param map StoredMapData
---@return number
local function getScale(map)
    local extents = getMap(map).Extents
    -- the "default" size is 16x16 cells
    return (extents.Top - extents.Bottom) / 16
end

local function lerpVec3(a, b, t)
    return util.vector3(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t
    )
end

local function lerpVec2(a, b, t)
    return util.vector2(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t
    )
end

local function lerpColor(a, b, t)
    return util.color.rgba(
        a.r + (b.r - a.r) * t,
        a.g + (b.g - a.g) * t,
        a.b + (b.b - a.b) * t,
        a.a + (b.a - a.a) * t
    )
end

local CELL_SIZE = 64 * 128 -- 8192

---@param worldPos WorldSpacePos
---@return CellPos
local function worldPosToCellPos(worldPos)
    if worldPos == nil then
        error("worldPos is nil")
        return
    end

    --- Position in world space, but units have been changed to match cell lengths.
    --- To get the cell grid position, take the floor of these elements.
    return util.vector3(worldPos.x / CELL_SIZE, worldPos.y / CELL_SIZE, worldPos.z / CELL_SIZE)
end

---@param cellPos CellPos
---@return WorldSpacePos
local function cellPosToWorldPos(cellPos)
    if cellPos == nil then
        error("cellPos is nil")
    end

    return util.vector3(cellPos.x * CELL_SIZE, cellPos.y * CELL_SIZE, cellPos.z * CELL_SIZE)
end

local function inBox(position, box)
    local normalized = box.transform:inverse():apply(position)
    return math.abs(normalized.x) <= 1
        and math.abs(normalized.y) <= 1
        and math.abs(normalized.z) <= 1
end

---@param data table?
---@param ... table?
---@return table
local function shallowMerge(data, ...)
    local copy = {}
    if data ~= nil then
        for k, v in pairs(data) do
            copy[k] = v
        end
    end
    local arg = { ... }
    for _, extraData in ipairs(arg) do
        if extraData ~= nil then
            for k, v in pairs(extraData) do
                copy[k] = v
            end
        end
    end
    return copy
end

local function lerpAngle(startAngle, endAngle, t)
    startAngle = util.normalizeAngle(startAngle)
    endAngle = util.normalizeAngle(endAngle)

    local diff = (endAngle - startAngle) % phi

    -- if > pi, go the negative way (diff - 2pi)
    if diff > math.pi then
        diff = diff - phi
    elseif math.abs(diff - math.pi) < eps then
        -- tie (exact half-turn): choose the positive rotation (+pi)
        diff = math.pi
    end

    local result = startAngle + diff * t
    return util.normalizeAngle(result)
end

---@generic T
---@param arr T[]
--- Sorted array over which the predicate transitions from false → true.
--- The predicate MUST be monotonic:
---   - For all i < j: if predicate(arr[i]) is true, predicate(arr[j]) is also true
--- In other words, there exists a single boundary index where the predicate
--- first becomes true, and remains true for all later elements.
---
---@param predicate fun(item: T): boolean
--- Returns true if the element satisfies the search condition.
--- This function will find the *first* index for which predicate(item) == true.
---
---@return integer index
--- The lowest index i such that predicate(arr[i]) is true.
--- Returns #arr+1 if the predicate is false for all elements.
local function binarySearchFirst(arr, predicate)
    local lo = 1
    local hi = #arr
    local result = #arr + 1

    -- Standard binary search over a monotonic predicate.
    -- Invariant:
    --   - All indices < lo are known to be false
    --   - All indices > hi are known to be true
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)

        if predicate(arr[mid]) then
            -- mid is a valid candidate; keep searching left
            -- to ensure we return the *first* true index.
            result = mid
            hi = mid - 1
        else
            -- mid does not satisfy the predicate; discard left half
            lo = mid + 1
        end
    end

    if result == 0 then
        error("binarySearchFirst returned 0")
    end

    return result
end

---@param array any[]
---@param fn (fun(e:any): util.vector3)?
---@return util.vector3?
local function averageVector3s(array, fn)
    if not array then
        return nil
    end
    if not fn then
        fn = function(e)
            return e
        end
    end
    local centerX = 0
    local centerY = 0
    local centerZ = 0
    local count = #array
    for i = 1, #array, 1 do
        local pos = fn(array[i])
        if pos then
            centerX = centerX + pos.x
            centerY = centerY + pos.y
            centerZ = centerZ + (pos.z or 0)
        else
            count = count - 1
        end
    end
    if count > 0 then
        centerX = centerX / count
        centerY = centerY / count
        centerZ = centerZ / count
        return util.vector3(centerX, centerY, centerZ)
    end
    return nil
end

-- TODO: l10n this
local forbiddenWords = {
    canton = true,
    the = true,
    a = true,
    of = true,
}
-- Canonicalize a string for fuzzy matching
local function canonicalizeId(s)
    if not s then
        return ""
    end

    -- Normalize case and separators in one pass
    s = string.lower(s):gsub("[_%-%./]+", " ")

    local tokens = {}

    -- Tokenize and strip punctuation per token
    for w in s:gmatch("%S+") do
        -- remove punctuation inside token
        w = w:gsub("%p", "")
        if (w ~= "") and (not forbiddenWords[w]) then
            tokens[#tokens + 1] = w
        end
    end

    table.sort(tokens)
    return table.concat(tokens, " ")
end


local BASE62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

local function toBase62(n)
    if n == 0 then
        return "0"
    end
    local t = {}
    while n > 0 do
        local r = n % 62
        t[#t + 1] = BASE62:sub(r + 1, r + 1)
        n = math.floor(n / 62)
    end
    return table.concat(t):reverse()
end

--- Hash a string to an alphanumeric string
--- Deterministic, non-cryptographic
--- @param s string
--- @return string
local function hashString(s)
    local hash = 2166136261 -- FNV offset basis (32-bit)

    for i = 1, #s do
        hash = util.bitXor(hash, s:byte(i))
        hash = (hash * 16777619) % 2 ^ 32
    end

    return toBase62(hash)
end



return {
    CELL_SIZE = CELL_SIZE,
    getMap = getMap,
    getScale = getScale,
    getClosestMap = getClosestMap,
    lerpVec3 = lerpVec3,
    lerpVec2 = lerpVec2,
    lerpColor = lerpColor,
    lerpAngle = lerpAngle,
    worldPosToCellPos = worldPosToCellPos,
    cellPosToWorldPos = cellPosToWorldPos,
    binarySearchFirst = binarySearchFirst,
    inBox = inBox,
    shallowMerge = shallowMerge,
    averageVector3s = averageVector3s,
    hashString = hashString,
    canonicalizeId = canonicalizeId,
}
