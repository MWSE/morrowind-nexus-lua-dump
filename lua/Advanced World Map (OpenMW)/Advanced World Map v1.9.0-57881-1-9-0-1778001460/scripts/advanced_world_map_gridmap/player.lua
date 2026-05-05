
local I = require("openmw.interfaces")
local util = require("openmw.util")
local async = require("openmw.async")
local markup = require("openmw.markup")
local ui = require("openmw.ui")
local vfs = require("openmw.vfs")
local core = require("openmw.core")
local storage = require("openmw.storage")


local l10n = core.l10n("advanced_world_map_gridmap")
local settingStorage = storage.playerSection("Settings:advWMap_gridmap")



local totspEsm = "solstheim tomb of the snow prince.esm"

local baseDir = "textures/advanced_world_map/gridmap/base/"
local totspDir = "textures/advanced_world_map/gridmap/totsp/"

local protectedConfigs = {
    ["data.initializer"] = true,

    ["ui.worldDefaultColor"] = true,
    ["ui.worldDefaultDarkColor"] = true,
    ["ui.worldDefaultLightColor"] = true,
    ["ui.worldMarkerShadowColor"] = true,
    ["ui.worldMarkerShadow"] = true,
    ["legend.alpha.city"] = true,
    ["legend.alpha.region"] = true,
}


local function restoreConfig(data)
    data.ui.worldDefaultColor = settingStorage:get("worldDefaultColor") or util.color.rgb(0, 0, 0.1)
    data.ui.worldDefaultDarkColor = settingStorage:get("worldDefaultDarkColor") or util.color.rgb(0.1333, 0.2666, 0.2666)
    data.ui.worldDefaultLightColor = settingStorage:get("worldDefaultLightColor") or util.color.rgb(1, 1, 1)
    data.ui.worldMarkerShadowColor = settingStorage:get("worldMarkerShadowColor") or util.color.rgb(0.5, 0.5, 0.5)
    local shadow = settingStorage:get("worldMarkerShadow")
    data.ui.worldMarkerShadow = (shadow == nil or shadow == true) and true or false
    data.legend.alpha.city = settingStorage:get("alpha.city") or 90
    data.legend.alpha.region = settingStorage:get("alpha.region") or 7
end

settingStorage:subscribe(async:callback(function(s, key)
    if key and I.AdvancedWorldMap then
        restoreConfig(I.AdvancedWorldMap.getConfig())
    end
end))


local function init()
    ---@type AdvancedWorldMap.Interface
    local interface = I.AdvancedWorldMap

    if not interface or interface.version < 12 then return end

    local dir = baseDir
    local mapInfo = markup.loadYaml(dir .. "mapInfo.yaml")
    if not mapInfo then return end

    local wColor = settingStorage:get("waterColor") or util.color.rgb(0.521569, 0.643137, 0.701961)
    mapInfo.bColor = {wColor.r, wColor.g, wColor.b}

    interface.events.registerHandler(interface.events.EVENT.onWorldMapTextureInit, function (e)
        if not e.internal then return end

        e.dirPath = dir
        e.mapInfo = mapInfo
        e.imagePath = nil
    end, -123)

    if not interface.setWorldMapInfo(mapInfo, dir) then return end


    if core.contentFiles.has(totspEsm) then
        interface.events.registerHandler(interface.events.EVENT.onWorldMapTextureGet, function (e)
            if not e.mapInfo then return end

            local id = string.format("(%d,%d).png", e.x, e.y)
            local path = totspDir..id

            if vfs.fileExists(path) then
                e.path = path
            end
        end, -123)
    end


    local config = interface.getConfig()

    interface.events.registerHandler(interface.events.EVENT.onConfigChanged, function (e)
        if not protectedConfigs[e.key] then return end
        ui.showMessage(l10n("ConfigChangeWarning", {id = e.key}))
        restoreConfig(interface.getConfig())
    end, -123)

    restoreConfig(interface.getConfig())
end


async:newUnsavableSimulationTimer(0.01, init)


return {}