local core = require("openmw.core")

-- just enums, not for cell name usage
EXTERIOR = "exterior"
GENERIC_INTERIOR = "generic interior"
DAGOTH_UR = "dagoth ur"
FACILITY_CAVERN = "dagoth ur, facility cavern"
AKULAKHANS_CHAMBER = "akulakhan's chamber"

local l10n_cellNames = core.l10n("ItBeats_CellNames")

function GetRMCellType(cell)
    if string.lower(cell.name) == l10n_cellNames("akulakhan_chamber") then                  return AKULAKHANS_CHAMBER
    elseif string.lower(cell.name) == l10n_cellNames("facility_cavern") then                return FACILITY_CAVERN
    elseif string.find(string.lower(cell.name), l10n_cellNames("dagoth_ur")) ~= nil then    return DAGOTH_UR
    elseif cell.isExterior then                                                             return EXTERIOR
    elseif not cell.isExterior then                                                         return GENERIC_INTERIOR
    end
end