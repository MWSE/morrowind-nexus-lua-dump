local mod = require("Spammer\\Map Icons\\mod")
local sort = require("Spammer\\Map Icons\\sort")
local skyIcons = require("Spammer\\Map Icons\\skyIcons")
local vanillaIcons = require("Spammer\\Map Icons\\vanillaIcons")
local cf = mwse.loadConfig(mod.name, mod.cf)

---@param cell tes3cell|table
---@param config table
---@return boolean
local function validCell(cell, config)
    cf = config or cf
    return cell.isOrBehavesAsExterior
        --or (string.startswith(cell.id:lower(), "sadrith mora"))
        --or (string.find(cell.id:lower(), " plaza") ~= nil)
        --or (string.find(cell.id, "works") ~= nil)
        or cf.whiteList[cell.id]
end
---
---@param refCell tes3cell|table
---@param cell tes3cell|table
---@param default string|nil
---@param config table|nil
return function(refCell, cell, default, config)
    cf = config or cf
    local icons = (cf.switch and table.copy(skyIcons)) or table.copy(vanillaIcons)
    default = default or icons.active_door
    local newPath
    if cf.blocked[cell.id] and lfs.fileexists("Data Files\\" .. cf.blocked[cell.id]) then
        newPath = cf.blocked[cell.id]
    else
        for _, pattern in ipairs(sort) do
            if validCell(refCell, cf) then
                newPath = ((string.find(cell.id:lower(), pattern, 1, true) ~= nil) and icons[pattern]) or newPath
                --mwse.log(pattern)
            end
        end
    end
    return newPath or default
end
