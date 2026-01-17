local OMWUtil = require("openmw.util")

---@class WAY.StorageData
local defaultSave = {}
defaultSave.selectedMapId = ""
---@type {[string]: {imageOffset: userdata, zoom: number}}
defaultSave.mapData = {}
defaultSave.windowOffset = OMWUtil.vector2(0, 0)
defaultSave.windowSize = OMWUtil.vector2(700, 500)

return defaultSave
