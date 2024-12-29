local directoryPath = tes3.installDirectory.."\\Data Files\\MWSE\\mods\\diject\\quest_guider\\markers\\"
local includePath = "diject.quest_guider.markers"
local fileExtension = ".lua"

local this = {}

this.isLoaded = false

---@class questGuider.markers.data
local default = {
    ---@type string
    name = "default",
    ---@type { marker : questGuider.ui.markerImage }
    journal = {
        marker = { path = "diject\\quest guider\\defaultArrow32x32.dds", shiftX = -8, shiftY = 15, scale = 0.5 },
    },
    ---@type { localMarker : questGuider.tracking.markerImage, doorMarker : questGuider.tracking.markerImage, worldMarker : questGuider.tracking.markerImage, questGiverMarker : questGuider.tracking.markerImage }
    tracking = {
        ---@type questGuider.tracking.markerImage
        localMarker = { path = "diject\\quest guider\\defaultArrow32x32.dds", pathAbove = "diject\\quest guider\\defaultArrowUp32x32.dds",
            pathBelow = "diject\\quest guider\\defaultArrowDown32x32.dds", shiftX = -8, shiftY = 15, scale = 0.5 },

        ---@type questGuider.tracking.markerImage
        doorMarker = { path = "diject\\quest guider\\defaultDoorArrow32x32.dds", pathAbove = "diject\\quest guider\\defaultDoorArrowUp32x32.dds",
            pathBelow = "diject\\quest guider\\defaultDoorArrowDown32x32.dds", shiftX = -8, shiftY = 15, scale = 0.5 },

        ---@type questGuider.tracking.markerImage
        worldMarker = { path = "diject\\quest guider\\defaultArrow32x32.dds", pathAbove = "diject\\quest guider\\defaultArrowUp32x32.dds",
            pathBelow = "diject\\quest guider\\defaultArrowDown32x32.dds", shiftX = -8, shiftY = 15, scale = 0.5 },

        ---@type questGuider.tracking.markerImage
        questGiverMarker = { path = "diject\\quest guider\\exclamationMark16x32.dds", pathAbove = "diject\\quest guider\\exclamationMarkUp32x32.dds",
            pathBelow = "diject\\quest guider\\exclamationMarkDown32x32.dds", shiftX = -3, shiftY = 12, scale = 0.4 },
    },
}

this.data = {}

function this.load()
    this.data = {}

    for fileName in lfs.dir(directoryPath) do
        local path = directoryPath..fileName
        local fileWithoutExt = fileName:sub(1, -fileExtension:len() - 1)
        local fileExt = fileName:sub(-fileExtension:len())

        if lfs.attributes(path, "mode") == "file" and fileExt == fileExtension then
            ---@type questGuider.markers.data
            local res = include(includePath.."."..fileWithoutExt)
            if res and res.journal and res.tracking then

                if not res.journal.marker or not res.journal.marker.path then
                    res.journal.marker = table.copy(default.journal.marker)
                end

                if not res.tracking.localMarker or not res.tracking.localMarker.path then
                    res.tracking.localMarker = table.copy(default.tracking.localMarker)
                end

                if not res.tracking.worldMarker or not res.tracking.worldMarker.path then
                    res.tracking.worldMarker = table.copy(default.tracking.worldMarker)
                end

                if not res.tracking.doorMarker or not res.tracking.doorMarker.path then
                    res.tracking.doorMarker = table.copy(default.tracking.doorMarker)
                end

                if not res.tracking.questGiverMarker or not res.tracking.questGiverMarker.path then
                    res.tracking.questGiverMarker = table.copy(default.tracking.questGiverMarker)
                end

                this.data[fileWithoutExt] = res
            end
        end
    end

    this.data["default"] = table.deepcopy(default)

    this.isLoaded = true
end

this.load()

function this.getIds()
    return table.keys(this.data)
end

---@param id string
---@return boolean
function this.apply(id)
    local ret = true
    local profile = this.data[id]

    if not profile then
        profile = default
        ret = false
    end

    local journal = include("diject.quest_guider.UI.journal")
    journal.markers.quest = profile.journal.marker

    local tracking = include("diject.quest_guider.tracking")
    tracking.localMarkerImageInfo = profile.tracking.localMarker
    tracking.worldMarkerImageInfo = profile.tracking.worldMarker
    tracking.localDoorMarkerImageInfo = profile.tracking.doorMarker
    tracking.questGiverImageInfo = profile.tracking.questGiverMarker

    return ret
end

---@param id string
---@return string?
function this.getName(id)
    local profile = this.data[id]
    if profile and profile.name then
        return profile.name
    end
end

local config = include("diject.quest_guider.config")

if not this.apply(config.data.main.iconProfile) then
    config.data.main.iconProfile = "default"
end

return this