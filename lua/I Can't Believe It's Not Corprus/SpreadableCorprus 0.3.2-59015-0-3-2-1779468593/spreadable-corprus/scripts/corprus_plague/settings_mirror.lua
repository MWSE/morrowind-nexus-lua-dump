-- Global script cache of player UI settings (playerSection is not readable from global).
local M = {}

local mirrored = {}

function M.set(values)
    if type(values) ~= 'table' then
        return
    end
    if values.dispositionModifier ~= nil then
        mirrored.dispositionModifier = values.dispositionModifier
    end
    if values.incubationDays ~= nil then
        mirrored.incubationDays = values.incubationDays
    end
end

function M.getDispositionModifier()
    return mirrored.dispositionModifier
end

function M.getIncubationDays()
    return mirrored.incubationDays
end

return M
