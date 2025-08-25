---@diagnostic disable: param-type-mismatch

local tableLib = require("scripts.quest_guider_lite.utils.table")

local this = {}

--- Returns string like ' "1", "2" and 3 more '
---@param tb table<any, string>
---@param max integer
---@param framePattern string|nil pattern with %s into which result will packed if max more than 0
---@param returnTable boolean? return an array with values
---@param customNumber integer? number of elements in the table
---@return string|string[]|nil
function this.getValueEnumString(tb, max, framePattern, returnTable, customNumber, valueFormat)
    local str = returnTable and {} or ""
    local count = 0
    valueFormat = valueFormat or "\"%s\""

    if max <= 0 then
        return str
    end

    for _, value in pairs(tb) do
        if count >= max then
            if returnTable then
                table.insert(str, string.format("and %d more", (customNumber or tableLib.size(tb)) - count))
            else
                str = string.format("%s and %d more", str, (customNumber or tableLib.size(tb)) - count)
            end
            break
        end

        local valueForm = string.format(valueFormat, value)

        if returnTable then
            table.insert(str, string.format(framePattern or "%s", valueForm))
        else
            str = string.format("%s%s%s", str, str:len() ~= 0 and ", " or "", valueForm)
        end
        count = count + 1

    end

    if framePattern and not returnTable then
        return string.format(framePattern, str)
    end

    return str
end


---@param name string
---@return string
function this.convertDialogueName(name)
    return string.sub(name, 7)
end


---@param text string
---@return string
function this.removeSpecialCharactersFromJournalText(text)
    return text:gsub("@", ""):gsub("#", "") ---@diagnostic disable-line: redundant-return-value
end


return this