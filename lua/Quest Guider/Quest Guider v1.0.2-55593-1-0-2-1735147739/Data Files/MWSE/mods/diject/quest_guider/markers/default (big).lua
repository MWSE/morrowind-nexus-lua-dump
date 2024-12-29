---@type questGuider.markers.data
return {
    ---@type string
    name = "default (big)",
    ---@type { marker : questGuider.ui.markerImage }
    journal = {
        marker = { path = "diject\\quest guider\\defaultArrow32x32.dds", shiftX = -12, shiftY = 23, scale = 0.75 },
    },
    ---@type { localMarker : questGuider.tracking.markerImage, doorMarker : questGuider.tracking.markerImage, worldMarker : questGuider.tracking.markerImage, questGiverMarker : questGuider.tracking.markerImage }
    tracking = {
        ---@type questGuider.tracking.markerImage
        localMarker = { path = "diject\\quest guider\\defaultArrow32x32.dds", pathAbove = "diject\\quest guider\\defaultArrowUp32x32.dds",
            pathBelow = "diject\\quest guider\\defaultArrowDown32x32.dds", shiftX = -12, shiftY = 23, scale = 0.75 },

        ---@type questGuider.tracking.markerImage
        doorMarker = { path = "diject\\quest guider\\defaultDoorArrow32x32.dds", pathAbove = "diject\\quest guider\\defaultDoorArrowUp32x32.dds",
            pathBelow = "diject\\quest guider\\defaultDoorArrowDown32x32.dds", shiftX = -12, shiftY = 23, scale = 0.75 },

        ---@type questGuider.tracking.markerImage
        worldMarker = { path = "diject\\quest guider\\defaultArrow32x32.dds", pathAbove = "diject\\quest guider\\defaultArrowUp32x32.dds",
            pathBelow = "diject\\quest guider\\defaultArrowDown32x32.dds", shiftX = -12, shiftY = 23, scale = 0.75 },

        ---@type questGuider.tracking.markerImage
        questGiverMarker = { path = "diject\\quest guider\\exclamationMark16x32.dds", pathAbove = "diject\\quest guider\\exclamationMarkUp32x32.dds",
            pathBelow = "diject\\quest guider\\exclamationMarkDown32x32.dds", shiftX = -5, shiftY = 12, scale = 0.6 },
    },
}