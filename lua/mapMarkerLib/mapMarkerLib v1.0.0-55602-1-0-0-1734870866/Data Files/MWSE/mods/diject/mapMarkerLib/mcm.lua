local markerLib = include("diject.mapMarkerLib.marker")
local logLib = include("diject.mapMarkerLib.utils.log")

local configFileName = "mapMarkerLib_settings"

local this = {}

local default = {
    enabled = markerLib.enabled,
    logging = logLib.enabled,
    minDelayBetweenUpdates = math.round(markerLib.minDelayBetweenUpdates * 1000),
    updateInterval = math.round(markerLib.updateInterval * 1000),
}

this.config = mwse.loadConfig(configFileName, default)

local mcm = mwse.mcm

local function onSearch(searchText)
    local text = searchText:lower()
    if text:find("map") or text:find("marker") or text:find("lib") then
        return true
    end
    return false
end

local function onClose()
    mwse.saveConfig(configFileName, this.config)
end

local function callback(self)
    markerLib.enabled = this.config.enabled
    logLib.enabled = this.config.logging
    markerLib.minDelayBetweenUpdates = this.config.minDelayBetweenUpdates / 1000
    markerLib.updateInterval = this.config.updateInterval / 1000
end

callback()

function this.registerModConfig()
    local template = mcm.createTemplate{name = "mapMarkerLib", config = this.config, onSearch = onSearch, onClose = onClose}

    local page = template:createPage{label = "Main"}

    page:createOnOffButton{configKey = "enabled", restartRequired = true, label = "Enable map markers."}
    page:createOnOffButton{configKey = "logging", label = "Enable logging."}

    page:createSlider{min = 10, max = 1000, configKey = "updateInterval",
        label = "%s - Minimum interval for updating the map menu. Usually the map menu is updated automatically, but sometimes, for example when you are standing still, it is not - this option is for such cases. In milliseconds.",
        callback = callback,
    }
    page:createSlider{min = 0, max = 100, configKey = "minDelayBetweenUpdates", callback = callback,
        label = "%s - Interval between updates for the minimap. The minimap is updated every frame. If after the last update less milliseconds have passed than this option, the minimap will not be updated. The option to reduce unnecessary load.",
    }
    page:createButton{inGameOnly = true, buttonText = "Flush all data", label = "Removes all data from mod storage. Requires saving and loading.",
        callback = function (self)
            markerLib.flush()
        end,
    }

    template:register()
end

return this