local playerRef = require("openmw.self")

local this = {}


---@param text string
---@param objHandler advWMap_tracking.objectHandler?
---@return string, string? -- text, listId
function this.replace(text, objHandler)
    local listId = nil
    local listIdMatch, remainingText = string.match(text, "^@list:(.-)@(.*)")
    if listIdMatch then
        listId = listIdMatch
        text = remainingText
    end

    local mapped = {}
    for codeStr in string.gmatch(text, "@(.-)@") do
        local pattern = "@"..codeStr.."@"
        if codeStr == "name" and objHandler and objHandler:isValid() then
            local name = objHandler.type.record(objHandler.object).name or objHandler.recordId
            mapped[pattern] = name
        end
    end

    for pattern, ret in pairs(mapped) do
        text = text:gsub(pattern:gsub("%(", "."):gsub("%)", "."), ret)
    end

    return text, listId
end


return this