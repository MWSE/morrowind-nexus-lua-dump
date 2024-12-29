---@type questGuider.markers.data
return {
    ---@type string
    name = "Skyrim style",
    ---@type { marker : questGuider.ui.markerImage }
    journal = {
        marker = { path = "diject\\quest guider\\skyrimMarker16x32.dds", shiftX = -4, shiftY = 15, scale = 0.5 },
    },
    ---@type { localMarker : questGuider.tracking.markerImage, doorMarker : questGuider.tracking.markerImage, worldMarker : questGuider.tracking.markerImage, questGiverMarker : questGuider.tracking.markerImage }
    tracking = {
        ---@type questGuider.tracking.markerImage
        localMarker = { path = "diject\\quest guider\\skyrimMarker16x32.dds", pathAbove = "diject\\quest guider\\skyrimMarkerUp32x32.dds",
            pathBelow = "diject\\quest guider\\skyrimMarkerDown32x32.dds", shiftX = -4, shiftY = 15, scale = 0.5 },

        ---@type questGuider.tracking.markerImage
        doorMarker = { path = "diject\\quest guider\\skyrimDoorMarker16x32.dds", pathAbove = "diject\\quest guider\\skyrimDoorMarkerUp32x32.dds",
            pathBelow = "diject\\quest guider\\skyrimDoorMarkerDown32x32.dds", shiftX = -4, shiftY = 10, scale = 0.5 },

        ---@type questGuider.tracking.markerImage
        worldMarker = { path = "diject\\quest guider\\skyrimMarker16x32.dds", pathAbove = "diject\\quest guider\\skyrimMarkerUp32x32.dds",
            pathBelow = "diject\\quest guider\\skyrimMarkerDown32x32.dds", shiftX = -4, shiftY = 10, scale = 0.5 },

        ---@type questGuider.tracking.markerImage
        questGiverMarker = { path = "diject\\quest guider\\skyrimExclamationMark16x32.dds", pathAbove = "diject\\quest guider\\skyrimExclamationMarkUp32x32.dds",
            pathBelow = "diject\\quest guider\\skyrimExclamationMarkDown32x32.dds", shiftX = -3, shiftY = 12, scale = 0.4 },
    },
}