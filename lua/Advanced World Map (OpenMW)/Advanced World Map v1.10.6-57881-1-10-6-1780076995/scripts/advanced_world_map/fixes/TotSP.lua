local core = require("openmw.core")
local vfs = require("openmw.vfs")

local eventSys = require("scripts.advanced_world_map.eventSys")
local commonData = require("scripts.advanced_world_map.common")

if not core.contentFiles.has(commonData.TotSPFileName) then return end


eventSys.registerHandler(eventSys.EVENT.onWorldMapTextureGet, function (e)
    if not e.mapInfo then return end

    if not e.path:find(commonData.defaultTRMapDir, nil, true) and
            not e.path:find(commonData.defaultBaseMapDir, nil, true) then return end

    local id = string.format("(%d,%d).png", e.x, e.y)
    local path = commonData.TotSPFixMapDir..id

    if vfs.fileExists(path) then
        e.path = path
    end
end, 999999)