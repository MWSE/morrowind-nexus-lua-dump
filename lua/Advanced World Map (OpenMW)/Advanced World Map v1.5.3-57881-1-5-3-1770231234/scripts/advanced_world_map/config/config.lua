local util = require('openmw.util')

local commonData = require("scripts.advanced_world_map.common")
local tableLib = require("scripts.advanced_world_map.utils.table")


local this = {}

---@class questGuider.config
this.default = {
    version = 8,
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
        fastClose = true, -- used only for initializing the pinned state
        clearCacheOnClose = true,
        overrideDefault = false,
        saveVisibilityStateInInterfaceMenu = false,
        resetSizePos = false,
    },
    legend = {
        markerSize = 6,
        zoomToGroup = 7,
        onlyDiscovered = true,
        visitedCellsOnWorldMap = false,
        alpha = {
            region = 8,
            entrance = 80,
            city = 60,
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
        markerVisibility = {
            personal = true,
            global = false,
        },
        listForAllCharacters = false,
    },
    data = {
        initializer = commonData.dataInitializerTypes[1],
    },
    input = {
        gamepadControls = true,
        gamepadControlsBumperMode = false,
        togglePinHotkey = nil,
        toggleMapTypeHotkey = nil,
        contextMenuHotkey = "C_Y",
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