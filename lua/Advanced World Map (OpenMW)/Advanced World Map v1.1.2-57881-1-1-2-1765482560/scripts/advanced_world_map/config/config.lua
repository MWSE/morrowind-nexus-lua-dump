local util = require('openmw.util')

local commonData = require("scripts.advanced_world_map.common")
local tableLib = require("scripts.advanced_world_map.utils.table")


local this = {}

---@class questGuider.config
this.default = {
    version = 3,
    main = {
        menuKey = "N",
        relativeSize = {
            x = 70,
            y = 70,
        },
        relativePosition = {
            x = 15,
            y = 15,
        },
        centerOnPlayer = true,
        discoveryRadius = 1500,
        updateFrequency = 30,
        firstInitMenu = true,
        fastClose = false,
        clearCacheOnClose = true,
        overrideDefault = false,
    },
    legend = {
        markerSize = 6,
        onlyDiscovered = true,
        alpha = {
            region = 8,
            entrance = 80,
            city = 40,
        },
        visibility = {
            regions = true,
            cities = true,
            playerMarker = true,
            labels = true,
            markers = true,
        }
    },
    tileset = {
        onlyDiscovered = true,
        zoomToShow = 4,
    },
    fastTravel = {
        enabled = false,
        onlyDiscovered = true,
        allowToInterior = false,
        withFollowers = false,
        onlyReachable = true,
        cooldown = 3,
        baseMagickaCost = 30,
        additionalCost = 4,
    },
    notes = {
        mapFontSize = 10,
    },
    data = {
        initializer = commonData.dataInitializerTypes[1],
    },
    ui = {
        fontSize = 18,
        defaultColor = commonData.defaultColor,
        markerDefaultColor = commonData.markerDefaultColor,
        defaultLightColor = commonData.defaultLightColor,
        defaultDarkColor = commonData.defaultDarkColor,
        whiteColor = commonData.whiteColor,
        backgroundColor = commonData.backgroundColor,
        -- disabledColor = commonData.disabledColor,
        foundMarkerColor = commonData.foundMarkerColor,
        foundMarkerLightColor = commonData.foundMarkerLightColor,
        textShadowColor = commonData.textShadowColor,
        defaultTextureColor = commonData.defaultTextureColor,
        mouseScrollAmount = 36,
        headerBackgroundAlpha = 100,
        scrollArrowSize = 16,
        resizerSize = 16,
        textHeightMul = 0.7,
    },
}


---@class questGuider.config
this.data = tableLib.deepcopy(this.default)

return this