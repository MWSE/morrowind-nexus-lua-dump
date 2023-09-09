local mc_data = require("JosephMcKean.commands.data")
local mc_config = require("JosephMcKean.commands.config")

local data_mc = {}

---@param text string
---@return table
function data_mc.suggestObjectType(text)
    local suggestions = {}
    local midSuggestions = {}

    for key, value in pairs(mc_data.objectType) do
        if (key:lower():startswith(text)) then
            table.insert(suggestions, key)
        elseif (key:lower():contains(text)) then
            table.insert(midSuggestions, key)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data_mc.suggestItem(text)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.dataHandler.nonDynamicData.objects) do
        local isDynamicObject = false
        for key, objectType in pairs(mc_data.objectType) do
            if (value.objectType == objectType) then
                isDynamicObject = true
                break
            end
        end
        if (isDynamicObject) then
            if (value.id:lower():startswith(text)) then
                table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
            elseif (value.id:lower():contains(text)) then
                table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
            end
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data_mc.suggestCell(text)
    local suggestions = {}
    local midSuggestions = {}

    for key, value in ipairs(tes3.dataHandler.nonDynamicData.cells) do
        if (value.id:lower():startswith(text)) then
            table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        elseif (value.id:lower():contains(text)) then
            table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data_mc.suggestFaction(text)
    local suggestions = {}
    local midSuggestions = {}

    for key, value in ipairs(tes3.dataHandler.nonDynamicData.factions) do
        if (value.id:lower():startswith(text)) then
            table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        elseif (value.id:lower():contains(text)) then
            table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data_mc.suggestSkill(text)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in pairs(tes3.dataHandler.nonDynamicData.skills) do
        if (value.id:lower():startswith(text)) then
            table.insert(suggestions, value.id)
        elseif (value.id:lower():contains(text)) then
            table.insert(midSuggestions, value.id)
        end
    end

    for key, value in pairs(mc_data.skillModuleSkills) do
        if (key:lower():startswith(text)) then
            table.insert(suggestions, key)
        elseif (key:lower():contains(text)) then
            table.insert(midSuggestions, key)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data_mc.suggestNPC(text)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.dataHandler.nonDynamicData.objects) do
        if (value.objectType == tes3.objectType["npc"]) then
            if (value.id:lower():startswith(text)) then
                table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
            elseif (value.id:lower():contains(text)) then
                table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
            end
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data_mc.suggestMark(text)
    local suggestions = {}
    local midSuggestions = {}

    for key, value in pairs(mc_config.marks) do
        if (key:lower():startswith(text)) then
            table.insert(suggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        elseif (key:lower():contains(text)) then
            table.insert(midSuggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data_mc.suggestAttribute(text)
    local suggestions = {}
    local midSuggestions = {}

    for key, value in pairs(tes3.attribute) do
        if (key:lower():startswith(text)) then
            table.insert(suggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        elseif (key:lower():contains(text)) then
            table.insert(midSuggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        end
    end

    for key, value in pairs(tes3.dataHandler.nonDynamicData.skills) do
        if (key:lower():startswith(text)) then
            table.insert(suggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        elseif (key:lower():contains(text)) then
            table.insert(midSuggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data_mc.suggestOwnership(text)
    local suggestions = {}
    local otherSuggestions = {}

    suggestions = data_mc.suggestNPC(text)
    otherSuggestions = data_mc.suggestFaction(text)

    for index, value in ipairs(otherSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data_mc.suggestObject(text)
    local suggestions = {}
    local midSuggestions = {}

    for index, value in ipairs(tes3.dataHandler.nonDynamicData.objects) do
        if (value.id:lower():startswith(text)) then
            table.insert(suggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        elseif (value.id:lower():contains(text)) then
            table.insert(midSuggestions, value.id:lower():contains(" ") and ("\"" .. value.id .. "\"") or value.id)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

---@param text string
---@return table
function data_mc.suggestWeather(text)
    local suggestions = {}
    local midSuggestions = {}

    for key, value in ipairs(tes3.weather) do
        if (key:lower():startswith(text)) then
            table.insert(suggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        elseif (key:lower():contains(text)) then
            table.insert(midSuggestions, key:lower():contains(" ") and ("\"" .. key .. "\"") or key)
        end
    end

    for index, value in ipairs(midSuggestions) do
        table.insert(suggestions, value)
    end

    return suggestions
end

return data_mc
