local common = {}
---bs.functions
---@param base any The starting value
---@param max any The value it ends at
---@param progressCap any When the value of data hits this max will be the value
---@param data any Where progressCap gets its data
---@param isPositive boolean If true then returns a positive slope, negative if false
---@return number
function common.lerp(base, max, progressCap, data, isPositive)
    local slope = (max - base) / progressCap
    local result = (slope * data + base)
    if isPositive then
        return math.min(result, max)
    else
        return math.max(result, max)
    end
end

function common.yesNoB(page, label, id, configTable, desc, callback)
    local optionTable = { ---@type mwseMCMYesNoButton
        label = label,
        variable = mwse.mcm.createTableVariable{id = id, table = configTable},
        description = desc,
        callback = callback
    }
    local yesNo = page:createYesNoButton(optionTable)
    return yesNo
end

return common