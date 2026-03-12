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
local json = require('scripts.LivelyMap.json.json')
local vfs = require('openmw.vfs')
local storage = require('openmw.storage')

-- This file just loads the JSON map data into global storage.
-- This makes it available to player and global scripts alike.
-- Do NOT `require` this file anywhere.

local mapData = storage.globalSection(MOD_NAME .. "_mapData")
mapData:setLifeTime(storage.LIFE_TIME.Temporary)

local heightData = storage.globalSection(MOD_NAME .. "_heightData")
heightData:setLifeTime(storage.LIFE_TIME.Temporary)

local function loadMapData()
    -- load from file
    local path = "scripts\\" .. MOD_NAME .. "\\data\\maps.json"
    print("onLoad: Started. Path file: " .. path)
    local handle, err = vfs.open(path)
    if handle == nil then
        error("OnLoad: Failed to read " .. path .. " - " .. tostring(err))
        return
    end

    -- augment maps with object
    -- also turn it into a map instead of array
    local fileData = json.decode(handle:read("*all"))
    mapData:reset(fileData.Maps)
    heightData:set("MaxHeight", fileData.MaxHeight)
    if fileData.MaxHeight == nil then
        error("missing maxheight")
    end
end

loadMapData()
