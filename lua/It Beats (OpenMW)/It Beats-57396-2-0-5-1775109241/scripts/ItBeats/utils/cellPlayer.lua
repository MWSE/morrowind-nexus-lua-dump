local storage = require("openmw.storage")

require("scripts.ItBeats.utils.consts")

local sectionVolume = storage.globalSection("SettingsItBeats_volume")

function GetRMCellType(cell)
    if cell.id == "akulakhan's chamber" then            return CellTypes.akulakhansChamber
    elseif cell.id == "dagoth ur, facility cavern" then return CellTypes.facilityCavern
    elseif string.find(cell.id, "dagoth ur") then       return CellTypes.dagothUr
    elseif cell.isExterior then                         return CellTypes.exterior
    elseif not cell.isExterior then                     return CellTypes.genericInterior
    end
end

function GetVolumeByCellType(cellType)
    -- defined in the function so it would actually update with settings changing
    local volumeByCellType = {
        [CellTypes.exterior]          = sectionVolume:get("exteriorVolume"),
        [CellTypes.genericInterior]   = sectionVolume:get("genericInteriorVolume"),
        [CellTypes.dagothUr]          = sectionVolume:get("dagothUrVolume"),
        [CellTypes.facilityCavern]    = sectionVolume:get("facilityCavernVolume"),
        [CellTypes.akulakhansChamber] = sectionVolume:get("akulakhansChamberVolume"),
    }
    local masterVolume = sectionVolume:get("masterVolume")
    return volumeByCellType[cellType] / 50 * masterVolume / 20
end
