local util = require('openmw.util')

local this = {}


this.l10nKey = "advanced_world_map"

this.settingPage = "AdvancedWorldMap:Settings"

this.inputBindingsSection = "AdvWMap:InputBindings"

this.configMainSectionName = "Settings:AdvWMap:Main"
this.configLegendSectionName = "Settings:AdvWMap:Legend"
this.configTilesetSectionName = "Settings:AdvWMap:Tileset"
this.configFastTravelSectionName = "Settings:AdvWMap:FastTravel"
this.configDataSectionName = "Settings:AdvWMap:Data"
this.configInputSectionName = "Settings:AdvWMap:Input"
this.configUISectionName = "Settings:AdvWMap:UI"
this.configNotesSectionName = "Settings:AdvWMap:Notes"
this.configMiscSectionName = "Settings:AdvWMap:Misc"

this.menuKeyId = "AdvWMap:menuKey"
this.toggleMapTypeKeyId = "AdvWMap:toggleMapTypeKey"
this.togglePinKeyId = "AdvWMap:togglePinKey"

this.localDataName = "AdvancedWorldMap:playerData"

this.mapMenuId = "__MAP__"
this.firstInitMenuId = "__FIRSTINIT__"
this.messageBoxMenuId = "__MESSAGEBOX__"

this.mapDataStorageName = "AdvancedWorldMap:mapDataStorage"

this.messageLayer = "AdvWMap:Message"

-- local storage
this.visitedLocsFieldId = "visitedLocationsHashSet"
this.discoveredLocsFieldId = "discoveredLocationsHashSet"
this.sortByDistanceFieldId = "searchSortByDistance"
this.showUnrevealedFieldId = "searchShowUnrevealed"
this.searchAllLocationsFieldId = "searchSearchInInteriors"
this.disabledDoorsFieldId = "disabledDoors"
this.localMapZoomFieldId = "localMapScale"
this.worldMapZoomFieldId = "worldMapScale"
this.lastCellIdFieldId = "lastCellId"
this.notesFieldId = "notes"
this.fastTravelTimestampFieldId = "fastTravelTimestampFieldId"
this.fastTravelRealTimestampFieldId = "fastTravelRealTimestampFieldId"
this.lastMapPosFieldId = "lastMapPosFieldId"
this.pinnedStateFieldId = "pinnedStateFieldId"
this.hideInInterfaceMenuFieldId = "hideInInterfaceMenuFieldId"


this.rightClickMenuId = "__MAP:RIGHTCLICKMENU__"
this.mapWidgetHeaderLayoutId = "__MAP:WIDGETHEADERLAYOUT__"
this.mapWidgetWindowLayoutId = "__MAP:WIDGETWINDOWLAYOUT__"

this.doorMarkerType = "AdvWMap:DoorMarker"
this.doorDescrMarkerType = "AdvWMap:DoorDescrMarker"
this.cityRegionMarkerType = "AdvWMap:CityRegionMarker"
this.noteMarkerType = "AdvWMap:NoteMarker"
this.noteNameMarkerType = "AdvWMap:NoteNameMarker"

this.widgetPriorityField = "AdvWMap:widgetPriority"

this.defaultColorData = {202/255, 165/255, 96/255}
this.defaultColor = util.color.rgb(this.defaultColorData[1], this.defaultColorData[2], this.defaultColorData[3])

this.markerDefaultColorData = {202/255, 165/255, 96/255}
this.markerDefaultColor = util.color.rgb(this.markerDefaultColorData[1], this.markerDefaultColorData[2], this.markerDefaultColorData[3])

this.defaultDarkColorData = {141/255, 115/255, 67/255}
this.defaultDarkColor = util.color.rgb(this.defaultDarkColorData[1], this.defaultDarkColorData[2], this.defaultDarkColorData[3])

this.defaultLightColorData = {238/255, 238/255, 204/255}
this.defaultLightColor = util.color.rgb(this.defaultLightColorData[1], this.defaultLightColorData[2], this.defaultLightColorData[3])

this.whiteColorData = {255/255, 255/255, 255/255}
this.whiteColor = util.color.rgb(this.whiteColorData[1], this.whiteColorData[2], this.whiteColorData[3])

this.selectedColorData = {0.3, 1, 0.3}
this.foundMarkerColor = util.color.rgb(this.selectedColorData[1], this.selectedColorData[2], this.selectedColorData[3])

this.selectedLightColorData = {0.6, 0.8, 0.6}
this.foundMarkerLightColor = util.color.rgb(this.selectedLightColorData[1], this.selectedLightColorData[2], this.selectedLightColorData[3])

this.linkColorData = {112 / 255, 126 / 255, 207 / 255}
this.linkColor = util.color.rgb(this.linkColorData[1], this.linkColorData[2], this.linkColorData[3])

this.disabledColorData = {0.5, 0.5, 0.5}
this.disabledColor = util.color.rgb(this.disabledColorData[1], this.disabledColorData[2], this.disabledColorData[3])

this.textShadowColorData = {1, 1, 1}
this.textShadowColor = util.color.rgb(this.textShadowColorData[1], this.textShadowColorData[2], this.textShadowColorData[3])

this.backgroundColorData = {0, 0, 0}
this.backgroundColor = util.color.rgb(this.backgroundColorData[1], this.backgroundColorData[2], this.backgroundColorData[3])

this.missedTextureColorData = {0.15, 0.15, 0.10}
this.defaultTextureColor = util.color.rgb(this.missedTextureColorData[1], this.missedTextureColorData[2], this.missedTextureColorData[3])

this.mapWaterColor = util.color.rgb(36 / 255, 53 / 255, 48 / 255)
this.mapInteriorBackgroundColor = util.color.rgb(0, 0, 0)

this.whiteTexture = nil
pcall(function ()
    local constants = require('scripts.omw.mwui.constants')
    this.whiteTexture = constants.whiteTexture
end)

this.mapMarkerPath = "textures/icons/advanced_world_map/squareMarker.dds"
this.mapMarkerForExPath = "textures/icons/advanced_world_map/squareMarker45.dds"
this.playerMapMarkerPath = "textures/icons/advanced_world_map/playerMapMarker.dds"
this.playerMarkerDir = "textures/icons/advanced_world_map/playerMarker/"
this.pinIconPath = "textures/icons/advanced_world_map/pinIco.png"

this.searchWidgetIcon = "textures/icons/advanced_world_map/widget/searchIco.dds"
this.searchWorldMarkerPath = "textures/icons/advanced_world_map/mapMarker1.png"
this.noteMarkerPath = "textures/icons/advanced_world_map/featherIco.png"


this.customMapDir = "textures/advanced_world_map/custom/"
this.defaultTRMapDir = "textures/advanced_world_map/default/TRmap/"
this.defaultBaseMapDir = "textures/advanced_world_map/default/basemap/"
this.questDataMapDir = "questData/"

this.exteriorMapId = "__Esm3ExteriorMap__"
this.exteriorCellLabel = "Esm3ExteriorCell:"
this.exteriorCellIdFormat = "Esm3ExteriorCell:%d:%d"
this.localMapTexturesDir = "textures/advanced_world_map/local/"

this.dataInitializerTypes = {
    "Auto",
    "Your custom",
    "Quest Guider's Quest Data",
    "Tamriel Rebuilt+",
    "Base game",
    "None",
}


function this.colorToArray(color)
    return {color.r, color.g, color.b, color.a}
end

function this.copyVector3(vector)
    return util.vector3(vector.x, vector.y, vector.z)
end

function this.distance2D(vector1, vector2)
    return math.sqrt((vector1.x - vector2.x)^2 + (vector1.y - vector2.y)^2)
end


---@return string
function this.doorHash(doorRef, destCellId)
    local doorPos = doorRef.position
    local destCellIdHash = destCellId:sub(-10)
    local cellIdHash = doorRef.cell.id:sub(-10)
    return string.format("%s_%d_%d_%s", cellIdHash, math.floor(doorPos.x / 512), math.floor(doorPos.y / 512), destCellIdHash)
end

return this