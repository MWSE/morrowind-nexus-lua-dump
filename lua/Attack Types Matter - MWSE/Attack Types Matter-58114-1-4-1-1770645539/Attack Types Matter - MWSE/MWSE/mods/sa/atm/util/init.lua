local log = mwse.Logger.new()

local config = require("sa.atm.config")

local util = {}

function util.replaceTableInPlace(destination, source)
    assert(type(destination) == "table", "replaceInPlace: destination must be a table")
    assert(type(source) == "table", "replaceInPlace: source must be a table")
    for k in pairs(destination) do destination[k] = nil end
    for k, v in pairs(source) do destination[k] = v end
end




return util
