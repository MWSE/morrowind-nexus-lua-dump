local util = require("openmw.util")

local this = {}

this.l10nKey = "advanced_world_map_tracking"

this.objectScriptPath = "scripts/advanced_world_map_tracking/objectLocal.lua"

this.worldCellLabel = "__world_cell__"

this.recordsLabel = "__records__"
this.objectsLabel = "__objects__"
this.positionsLabel = "__positions__"
this.typesLabel = "__types__"
this.defaultMarkerLabel = "__default__"

this.userDataMarkerType = "adwWMap_t:marker"

this.defaultGroupId = "~__default__"
this.hiddenGroupId = "~__hidden__"

this.defaultStorageId = "advWMap_tracking:DefaultStorage"

this.settingStorageId = "Settings:advWMap_tracking"
this.settingStorageToRemoveId = "Settings:advWMap_tracking:toremove"

this.playerSaveStorageId = "advWMap_tracking:SaveStorage"

this.uniqueIdKey = "UniqueId"

this.mapMarkersKey = "MapMarkers"
this.mapTemplatesKey = "MapTemplates"

this.mapDataVersionKey = "MapVersion"

this.settingPage = "advWMap_tracking:Settings"

this.exteriorCellIdFormat = "Esm3ExteriorCell:%d:%d"

this.detectTexture = "textures/icons/advanced_world_map/detectObjectMarker.dds"


this.defaultColorData = {202/255, 165/255, 96/255}
this.defaultColor = util.color.rgb(this.defaultColorData[1], this.defaultColorData[2], this.defaultColorData[3])
this.detectAnimalColor = util.color.rgb(0.85, 0.55, 0)
this.detectAnimalNPCColor = util.color.rgb(0.6, 0.8, 0)
this.detectAnimalEnemyColor = util.color.rgb(1, 0, 0)
this.detectKeyColor = util.color.rgb(0.7, 0.7, 0)
this.detectEnchantmentColor = util.color.rgb(0.2, 0.2, 1)


function this.distance2D(vector1, vector2)
    local a = vector1.x - vector2.x
    local b = vector1.y - vector2.y
    return math.sqrt(a * a + b * b)
end

function this.getGridCoordinates(pos)
    local gridX = math.floor(pos.x / 8192)
    local gridY = math.floor(pos.y / 8192)
    return gridX, gridY
end

function this.getCellIdByPos(pos)
    return this.exteriorCellIdFormat:format(this.getGridCoordinates(pos))
end

function this.getCellIdByGrid(gridX, gridY)
    return this.exteriorCellIdFormat:format(gridX, gridY)
end


---@param region AdvancedWorldMap.MapWidget.Region
---@return boolean
function this.isPointInRegion(region, pos)
    return pos.x >= region.left and pos.x <= region.right and pos.y >= region.bottom and pos.y <= region.top
end


return this