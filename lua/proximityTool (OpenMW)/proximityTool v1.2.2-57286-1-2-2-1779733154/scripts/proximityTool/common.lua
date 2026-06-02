local util = require('openmw.util')

local this = {}

this.worldCellLabel = "__world_cell__"

this.objectsLabel = "__objects__"
this.referencesLabel = "__references__"
this.positionsLabel = "__positions__"
this.textMarkerLabel = "__text__"

this.defaultGroupId = "~__default__"
this.hiddenGroupId = "~__hidden__"

this.playerStorageId = "proximityTool:LocalStorage"

this.settingStorageId = "Settings:proximityTool"
this.settingStorageToRemoveId = "Settings:proximityTool:toremove"

this.localSettingStorageId = "proximityTool:LocalSettings"

this.uniqueIdKey = "UniqueId"

this.mapMarkersKey = "MapMarkers"

this.mapRecordsKey = "MapRecords"

this.hudmMarkersKey = "HUDMRecords"

this.mapDataVersionKey = "MapVersion"

this.l10nKey = "proximityTool"

this.settingPage = "proximityTool:Settings"

this.toggleHUDTriggerId = "proximityTool:trigger.toggleHUD"


this.defaultColorData = {202/255, 165/255, 96/255}
this.defaultColor = util.color.rgb(this.defaultColorData[1], this.defaultColorData[2], this.defaultColorData[3])


return this