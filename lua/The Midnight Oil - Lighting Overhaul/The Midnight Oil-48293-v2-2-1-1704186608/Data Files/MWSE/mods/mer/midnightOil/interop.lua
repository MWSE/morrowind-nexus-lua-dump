local common = require("mer.midnightOil.common")
local config = require("mer.midnightOil.config").getConfig()
local this = {}

---Add an object id to the blacklist
---This will block it from being registered as a light, candle, oil etc
---@param lightId string
function this.addToBlacklist(lightId)
    common.blacklist[lightId:lower()] = true
end

---Add a cell to the blacklist. Provide either the tes3cell or the cell's editor ID (case sensitive)
---This will block any lights in this cell from being toggled.
---@param cell tes3cell|string
function this.blacklistCell(cell)
    if type(cell) ~= "string" then
        cell = cell.editorName
    end
    config.cellBlacklist[cell] = true
end

function this.getCandleIds()
    return common.candle
end

return this