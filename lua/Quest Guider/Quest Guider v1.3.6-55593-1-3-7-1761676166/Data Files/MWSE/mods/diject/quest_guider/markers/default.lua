---@class questGuider.markers.data
return {
    ---@type string
    name = "default", -- the profile name
    ---@type { marker : questGuider.ui.markerImage?, zoneMarker : questGuider.ui.markerImage? }
    journal = { -- markers in the journal menu
        ---@type questGuider.tracking.markerImage?
        marker = { path = "diject\\quest guider\\defaultArrow32x32.dds", shiftX = -8, shiftY = 15, scale = 0.5 }, -- regular marker
        ---@type questGuider.tracking.markerImage?
        zoneMarker = { path = "diject\\quest guider\\circleZoneMarker128x128.dds", shiftX = -64, shiftY = 64, scale = 128, }, -- "approximate" marker. scale value is the image size
    },
    ---@type { localMarker : questGuider.tracking.markerImage?, doorMarker : questGuider.tracking.markerImage?, worldMarker : questGuider.tracking.markerImage?, questGiverMarker : questGuider.tracking.markerImage?, zoneMarker : questGuider.tracking.markerImage? }
    tracking = { -- markers in the map menu
        ---@type questGuider.tracking.markerImage?
        localMarker = { path = "diject\\quest guider\\defaultArrow32x32.dds", pathAbove = "diject\\quest guider\\defaultArrowUp32x32.dds", -- marker for the local map menu that point an object
            pathBelow = "diject\\quest guider\\defaultArrowDown32x32.dds", shiftX = -8, shiftY = 15, scale = 0.5 },

        ---@type questGuider.tracking.markerImage?
        doorMarker = { path = "diject\\quest guider\\defaultDoorArrow32x32.dds", pathAbove = "diject\\quest guider\\defaultDoorArrowUp32x32.dds", -- marker for a door
            pathBelow = "diject\\quest guider\\defaultDoorArrowDown32x32.dds", shiftX = -8, shiftY = 15, scale = 0.5 },

        ---@type questGuider.tracking.markerImage?
        worldMarker = { path = "diject\\quest guider\\defaultArrow32x32.dds", pathAbove = "diject\\quest guider\\defaultArrowUp32x32.dds", -- marker for the world map menu
            pathBelow = "diject\\quest guider\\defaultArrowDown32x32.dds", shiftX = -8, shiftY = 15, scale = 0.5 },

        ---@type questGuider.tracking.markerImage?
        questGiverMarker = { path = "diject\\quest guider\\exclamationMark16x32.dds", pathAbove = "diject\\quest guider\\exclamationMarkUp32x32.dds", -- marker for quest givers
            pathBelow = "diject\\quest guider\\exclamationMarkDown32x32.dds", shiftX = -3, shiftY = 12, scale = 0.4 },

        ---@type questGuider.tracking.markerImage?
        zoneMarker = { path = "diject\\quest guider\\circleZoneMarker128x128.dds", shiftX = -64, shiftY = 64, scale = 128 }, -- "approximate" marker. scale value is the image size
    },
}
-- Notes:
-- shiftX - by default, the marker texture points to the object with its upper left corner. This value shifts the texture. *Negative values shift left, positive values shift right.* The value is applied after scaling
-- shiftY - *Negative values shift down, positive values shift up.* The value is applied after scaling
-- pathAbove - icon when the tracked point is above the player, can be nil
-- pathBelow - is below, can be nil