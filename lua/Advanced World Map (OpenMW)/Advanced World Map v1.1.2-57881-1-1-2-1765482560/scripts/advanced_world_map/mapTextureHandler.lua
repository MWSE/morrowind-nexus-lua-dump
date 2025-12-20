local vfs = require("openmw.vfs")
local markup = require("openmw.markup")
local core = require("openmw.core")
local ui = require("openmw.ui")
local util = require("openmw.util")

local log = require("scripts.advanced_world_map.utils.log")

local commonData = require("scripts.advanced_world_map.common")

local config = require("scripts.advanced_world_map.config.config")

local mapData = require("scripts.advanced_world_map.mapDataHandler")


---@class advancedWorldMap.mapImageInfo
---@field version integer
---@field time integer
---@field file string
---@field width integer
---@field height integer
---@field pixelsPerCell integer
---@field gridX {min : integer, max : integer}
---@field gridY {min : integer, max : integer}

---@class advancedWorldMap.localCellInfo
---@field mX integer?
---@field mY integer
---@field nA number
---@field width integer
---@field height integer

local this = {}


local directories = {
    [commonData.dataInitializerTypes[2]] = commonData.customMapDir,
    [commonData.dataInitializerTypes[3]] = commonData.questDataMapDir,
    [commonData.dataInitializerTypes[4]] = commonData.defaultTRMapDir,
    [commonData.dataInitializerTypes[5]] = commonData.defaultBaseMapDir,
}


---@type string
this.mapImagePath = nil
---@type advancedWorldMap.mapImageInfo?
this.mapInfo = nil

this.localMapTextureCache = {}

this.localCellTextureCache = {}

this.worldTextureCache = {}

---@type table<string, advancedWorldMap.localCellInfo>
this.localCellInfo = {}


---@return string?
---@return advancedWorldMap.mapImageInfo?
local function getMapImage(dirPath)
    local mapInfo
    local imagePath

    local mapInfoPath = dirPath.."mapInfo.yaml"

    if vfs.fileExists(mapInfoPath) then
        local s, res = pcall(function ()
            mapInfo = markup.loadYaml(mapInfoPath)
            local path = dirPath..mapInfo.file
            if vfs.fileExists(path) then
                imagePath = path
            end
        end)
    else
        return
    end

    return imagePath, mapInfo
end


---@return boolean
local function initMapImage(initializerType)
    local imagePath, mapInfo

    if initializerType == commonData.dataInitializerTypes[2] then
        imagePath, mapInfo = getMapImage(commonData.customMapDir)
    elseif initializerType == commonData.dataInitializerTypes[3] then
        imagePath, mapInfo = getMapImage(commonData.questDataMapDir)
    elseif initializerType == commonData.dataInitializerTypes[4] then
        imagePath, mapInfo = getMapImage(commonData.defaultTRMapDir)
    elseif initializerType == commonData.dataInitializerTypes[5] then
        imagePath, mapInfo = getMapImage(commonData.defaultBaseMapDir)
    elseif initializerType == commonData.dataInitializerTypes[1] then
        local mapGridArea = 1
        if mapData.grid then
            mapGridArea = (mapData.grid.max.x - mapData.grid.min.x) * (mapData.grid.max.y - mapData.grid.min.y)
        end

        do
            local path, info = getMapImage(commonData.customMapDir)
            if path and info then
                local area = (info.gridX.max - info.gridX.min) * (info.gridY.max - info.gridY.min)
                local v = area / mapGridArea
                if v > 0.9 and v < 1.1 then
                    imagePath = path
                    mapInfo = info
                    goto next
                end
            end
        end

        local data = {}
        for id, dir in pairs(directories) do
            local path, info = getMapImage(dir)
            if path and info then
                local area = (info.gridX.max - info.gridX.min) * (info.gridY.max - info.gridY.min)
                table.insert(data, {path, info, area / mapGridArea})
            end
        end

        table.sort(data, function (a, b)
            return (a[3] < b[3]) or (a[3] == b[3] and (a[2].time or 0) > (b[2].time or 0))
        end)

        for _, dt in ipairs(data) do
            local v = dt[3] or 0
            if v > 0.9 then
                imagePath = dt[1]
                mapInfo = dt[2]
                break
            end
        end

        if not imagePath or not mapInfo then
            if next(data) then
                local dt = data[#data]
                imagePath = dt[1]
                mapInfo = dt[2]
            end
        end
    end

    ::next::

    if imagePath and mapInfo then
        this.mapImagePath = imagePath
        this.mapInfo = mapInfo
        log("World map image initialized from: "..imagePath)
        return true
    end
    return false
end


function this.init()
    if initMapImage(config.data.data.initializer) then
        return true
    end

    if config.data.data.initializer ~= commonData.dataInitializerTypes[1] and
            config.data.data.initializer ~= commonData.dataInitializerTypes[6] and
            initMapImage(commonData.dataInitializerTypes[1]) then
        return true
    end

    log("Map image wasn't set up")
    this.mapImagePath = nil
    this.mapInfo = nil
    return false
end



function this.getLocalMapTexture(gridX, gridY)
    local path = string.format("%s(%d,%d)", commonData.localMapTexturesDir, gridX, gridY)
    local pathPng = path..".png"
    local pathTga = path..".tga"

    if this.localMapTextureCache[path] then return this.localMapTextureCache[path] end

    local foundPath
    if vfs.fileExists(pathPng) then
        foundPath = pathPng
    elseif vfs.fileExists(pathTga) then
        foundPath = pathTga
    else
        return
    end

    local texture = ui.texture{ path = foundPath }
    this.localMapTextureCache[path] = texture

    return texture
end


function this.getLocalCellInfo(cellId)
    if this.localCellInfo[cellId] then
        return this.localCellInfo[cellId]
    end

    local path = string.format("%s%s.yaml", commonData.localMapTexturesDir, cellId:gsub(":", ""))
    if not vfs.fileExists(path) then
        this.localCellInfo[cellId] = {} ---@diagnostic disable-line: missing-fields
    else
        this.localCellInfo[cellId] = markup.loadYaml(path)
    end

    return this.localCellInfo[cellId]
end


function this.getLocalCellMapTextures(cellId)
    if this.localCellTextureCache[cellId] then
        return this.localCellTextureCache[cellId]
    end

    local cellInfo = this.getLocalCellInfo(cellId)
    if not cellInfo.mX then return end

    local res = {}
    for y = 1, cellInfo.height do
        local arr = {}
        for x = 1, cellInfo.width do
            local path = string.format("%s%s [%d,%d]", commonData.localMapTexturesDir, cellId:gsub(":", ""), x - 1, y - 1)
            local pathPng = path..".png"
            local pathTga = path..".tga"

            local foundPath
            if vfs.fileExists(pathPng) then
                foundPath = pathPng
            elseif vfs.fileExists(pathTga) then
                foundPath = pathTga
            else
                goto continue
            end

            local texture = ui.texture{ path = foundPath, offset = util.vector2(1, 1), size = util.vector2(254, 254) }
            arr[x] = texture

            ::continue::
        end
        res[y] = arr
    end

    this.localCellTextureCache[cellId] = res
    return res
end


function this.clearInteriorTextureCache()
    for i, _ in pairs(this.localCellTextureCache) do
        this.localCellTextureCache[i] = nil
    end
    for i, _ in pairs(this.localCellInfo) do
        this.localCellInfo[i] = nil
    end
end


function this.getWorldMapTexture()
    if not this.mapImagePath or not vfs.fileExists(this.mapImagePath) then return end

    if this.worldTextureCache[this.mapImagePath] then
        return this.worldTextureCache[this.mapImagePath]
    end

    local texture = ui.texture{ path = this.mapImagePath }
    this.worldTextureCache[this.mapImagePath] = texture
    return texture
end


return this