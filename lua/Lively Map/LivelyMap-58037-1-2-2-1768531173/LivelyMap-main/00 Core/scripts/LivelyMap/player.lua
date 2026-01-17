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

-- This file is in charge of tracking and exposing path information.
-- Interact with it via the interface it exposes.

local MOD_NAME = require("scripts.LivelyMap.ns")
local types    = require('openmw.types')
local json     = require('scripts.LivelyMap.json.json')
local mutil    = require('scripts.LivelyMap.mutil')
local core     = require('openmw.core')
local pself    = require("openmw.self")
local util     = require("openmw.util")
local vfs      = require('openmw.vfs')
local aux_util = require('openmw_aux.util')
local settings = require("scripts.LivelyMap.settings")
local async    = require("openmw.async")


local settingCache = {
    volatileNeravarinesJourney = settings.main.volatileNeravarinesJourney,
}
settings.main.subscribe(async:callback(function(_, key)
    settingCache[key] = settings.main[key]
end))


local magicPrefix = "!!" .. MOD_NAME .. "!!STARTOFENTRY!!"
local magicSuffix = "!!" .. MOD_NAME .. "!!ENDOFENTRY!!"

local function wrapInMagic(str)
    return magicPrefix .. str .. magicSuffix
end
local function unwrapMagic(str)
    return string.sub(str, #magicPrefix + 1, #str - #magicSuffix)
end

local playerName = types.NPC.record(pself.recordId).name

-- Merge two SaveData-like tables: a and b
-- Returns a new table shaped like SaveData
local function merge(a, b)
    a = a or {
        id = playerName,
        paths = {},
        extra = {},
    }
    b = b or {
        id = playerName,
        paths = {},
        extra = {},
    }
    -- If a or b is empty, easy cases
    local result_paths = {}
    if #a.paths == 0 then
        for _, p in ipairs(b.paths) do
            table.insert(result_paths, p)
        end
        return { id = b.id, paths = result_paths, extra = b.extra }
    end
    if #b.paths == 0 then
        for _, p in ipairs(a.paths) do
            table.insert(result_paths, p)
        end
        return { id = b.id, paths = result_paths, extra = a.extra }
    end

    -- Find newest timestamp in b
    local b_newest = b.paths[#b.paths].t

    -- Copy from a until timestamps overlap
    for i = 1, #a.paths do
        if a.paths[i].t >= b_newest then
            break
        end
        result_paths[#result_paths + 1] = a.paths[i]
    end

    -- Append all of b
    for i = 1, #b.paths do
        result_paths[#result_paths + 1] = b.paths[i]
    end

    return {
        id = b.id or a.id,
        paths = result_paths,
        extra = mutil.shallowMerge(a, b),
    }
end

local cellsVisited = {}

---@param pathEntry PathEntry
local function markCell(pathEntry)
    local x = math.floor(pathEntry.x / mutil.CELL_SIZE)
    local y = math.floor(pathEntry.y / mutil.CELL_SIZE)
    if not cellsVisited[x] then
        cellsVisited[x] = {}
    end
    cellsVisited[x][y] = 1
    for xi = x - 1, x + 1, 2 do
        for yi = y - 1, y + 1, 2 do
            if not cellsVisited[xi] then
                cellsVisited[xi] = {}
            end
            if not cellsVisited[xi][yi] then
                cellsVisited[xi][yi] = 0.5
            end
        end
    end
end

-- fromSave contains the data from this savegame.
local fromSave = {
    id = playerName,
    paths = {},
    extra = {},
}

---@class PathEntry
---@field t number Timestamp.
---@field x number? Exterior world position component.
---@field y number? Exterior world position component.
---@field z number? Exterior world position component.

---@class SavedPlayerData
---@field id string
---@field paths PathEntry[]
---@field extra any

--- mergedData contains the merged data from the savegame and file,
--- for all saves. The key is the playerName.
---@type {[string]: SavedPlayerData}
local allData = {}
allData[playerName] = {
    id = playerName,
    paths = {},
    extra = {},
}

local function onSave()
    if settingCache.volatileNeravarinesJourney then
        return nil
    end
    -- debug
    --print("onSave:" .. aux_util.deepToString(fromSave, 3))
    -- do the save. this needs to be in json
    -- so the Go code can unmarshal it.
    return { json = wrapInMagic(json.encode(fromSave)) }
end


local function parseFile(path)
    local handle, err = vfs.open(path)
    if handle == nil then
        print("OnLoad: Failed to read " .. path .. " - " .. tostring(err))
        return
    end
    return json.decode(handle:read("*all"))
end

local function endsWith(str, ending)
    if ending == "" then
        return true
    end
    if #str < #ending then
        return false
    end
    return str:sub(- #ending) == ending
end

local loadDone = false
local function onLoad(data)
    if settingCache.volatileNeravarinesJourney then
        return nil
    end

    if loadDone then
        error("onLoad called twice")
    end
    loadDone = true


    local path = "scripts\\" .. MOD_NAME .. "\\data\\paths\\" .. playerName .. ".json"
    print("onLoad: Started. Path file: " .. path)

    -- load from in-game storage
    if data ~= nil then
        fromSave = json.decode(unwrapMagic(data.json))
    end

    -- load from file. this is produced by the Go portion of the mod.
    local fromFile = parseFile(path)

    -- merge them
    allData[playerName] = merge(fromFile, fromSave)

    -- debug
    --print("onLoad: " .. aux_util.deepToString(allData, 3))

    -- now load all other character data
    local allSaves = "scripts\\" .. MOD_NAME .. "\\data\\paths\\"
    for fileName in vfs.pathsWithPrefix(allSaves) do
        if fileName ~= path and endsWith(fileName, ".json") then
            -- this is for a different character
            local lastSlash = math.max(path:find("/", 1, true) or 0, path:find("\\", 1, true) or 0)
            local characterName = fileName:sub(lastSlash):gsub("%.json", "")
            if not allData[characterName] then
                allData[characterName] = parseFile(path)
                print("onLoad completed for " .. characterName)
            end
        end
    end

    -- update cells visited
    local count = 0
    for _, pathEntry in ipairs(allData[playerName].paths) do
        if pathEntry and pathEntry.x and pathEntry.y then
            markCell(pathEntry)
            count = count + 1
        end
    end
    print("Marked " .. tostring(count) .. " cells as visited.")
end

---@return PathEntry
local function newEntry()
    return {
        t = math.ceil(core.getGameTime()),
        x = pself.position.x or nil,
        y = pself.position.y or nil,
        z = pself.position.z or nil,
    }
end

local function addEntry(entry)
    -- make a new list and add the entry to it
    if allData[playerName] == nil then
        allData[playerName] = {
            id = playerName,
            paths = { entry }
        }
        markCell(entry)
        print("Initialized new local storage with entry: " .. aux_util.deepToString(entry, 3))
        return
    end
    if not allData[playerName].paths or #allData[playerName].paths == 0 then
        allData[playerName].paths = { entry }
        markCell(entry)
        return
    end
    local tail = allData[playerName].paths[#(allData[playerName].paths)]
    if tail.x and tail.y then
        -- also don't do anything if the distance is too close
        -- 7456540 is a third of cell length, squared
        if (util.vector2(entry.x, entry.y) - util.vector2(tail.x, tail.y)):length2() < 7456540 then
            return
        end
    end

    -- ok, now add to the end of the list.
    markCell(entry)
    table.insert(allData[playerName].paths, entry)
    table.insert(fromSave.paths, entry)
    print("Added new entry: " .. aux_util.deepToString(entry, 3))
    print("#allData[" ..
        playerName ..
        "] = " .. tostring(#(allData[playerName].paths)) .. ", #fromSave.paths = " .. tostring(#fromSave.paths))
end


local lastExteriorPosition = nil
---@param data ExteriorLocationResult
local function onReceiveExteriorLocation(data)
    if not data then
        return
    end
    if data.args.source ~= MOD_NAME .. "_player.lua" then
        return
    end
    lastExteriorPosition = {
        pos = util.vector3(data.pos.x, data.pos.y, data.pos.z),
        facing = util.vector2(data.facing.x, data.facing.y),
    }
    addEntry({
        t = math.ceil(core.getGameTime()),
        x = data.pos.x,
        y = data.pos.y,
        z = data.pos.z,
    })
end


local lastInteriorCell = nil
local function onUpdate(dt)
    if dt == 0 then
        -- don't do anything if paused.
        return
    end
    if pself.cell.isExterior then
        lastInteriorCell = nil
        addEntry(newEntry())
    elseif lastInteriorCell == pself.cell then
        return
    else
        lastInteriorCell = pself.cell
        core.sendGlobalEvent(MOD_NAME .. "onGetExteriorLocation", {
            object = pself,
            callbackObject = pself,
            source = MOD_NAME .. "_player.lua",
        })
    end
end

---@class PositionAndFacing
---@field pos util.vector3
---@field facing util.vector2

---@return PositionAndFacing?
local function getExteriorPositionAndFacing()
    if pself.cell.isExterior then
        local forward = pself.rotation:apply(util.vector3(0.0, 1.0, 0.0)):normalize()
        return {
            pos = pself.position,
            facing = util.vector2(forward.x, forward.y):normalize(),
        }
    elseif lastExteriorPosition then
        return lastExteriorPosition
    end
end

local function renewExteriorPositionAndFacing()
    core.sendGlobalEvent(MOD_NAME .. "onGetExteriorLocation", {
        object = pself,
        callbackObject = pself,
        source = MOD_NAME .. "_player.lua",
    })
end

return {
    interfaceName = MOD_NAME .. "Player",
    interface = {
        version = 1,
        getPaths = function() return allData end,
        playerName = playerName,
        getExteriorPositionAndFacing = getExteriorPositionAndFacing,
        renewExteriorPositionAndFacing = renewExteriorPositionAndFacing,
        cellVisited = function(x, y)
            return cellsVisited[x] and cellsVisited[x][y] or 0
        end
    },
    eventHandlers = {
        [MOD_NAME .. "onReceiveExteriorLocation"] = onReceiveExteriorLocation,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
        onInit = function() onLoad(nil) end,
    }
}
