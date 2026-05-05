local core = require('openmw.core')
local util = require('openmw.util')

local Helpers = {}

Helpers.deepCopy = function(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            copy[k] = Helpers.deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

Helpers.deepPrint = function(tbl, indent)
    indent = indent or 0
    local toprint = string.rep(" ", indent) .. "{\n"
    indent = indent + 2 
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint  .. k ..  " = "   
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\n"
        elseif (type(v) == "table") then
            toprint = toprint .. Helpers.deepPrint(v, indent + 2) .. ",\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent-2) .. "}"
    return toprint
end

Helpers.uiDeepPrint = function(layoutOrElement, lvl)
    lvl = lvl or 0
    local isElement = type(layoutOrElement) == 'userdata'
    local layout = isElement and layoutOrElement.layout or layoutOrElement
    if layout.name then
        print(string.rep('-', lvl), layoutOrElement, layout.name)
    end
    if layout.content then
        for _, child in pairs(layout.content) do
            Helpers.uiDeepPrint(child, lvl + 1)
        end
    end
end

-- Checks if two tables contain the same elements (ignoring order)
Helpers.tableEquals = function(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return t1 == t2
    end
    local t1Keys = {}
    local t2Keys = {}
    for k in pairs(t1) do table.insert(t1Keys, k) end
    for k in pairs(t2) do table.insert(t2Keys, k) end
    table.sort(t1Keys)
    table.sort(t2Keys)
    if #t1Keys ~= #t2Keys then return false end
    for i = 1, #t1Keys do
        if t1Keys[i] ~= t2Keys[i] then return false end
        if not Helpers.tableEquals(t1[t1Keys[i]], t2[t2Keys[i]]) then return false end
    end
    return true
end

Helpers.mapEquals = function(m1, m2)
    for k, v in pairs(m1) do
        if type(v) == 'table' and type(m2[k]) == 'table' then
            if not Helpers.mapEquals(v, m2[k]) then
                return false
            end
        else
            if m2[k] ~= v then
                return false
            end
        end
    end
    for k, v in pairs(m2) do
        if type(v) == 'table' and type(m1[k]) == 'table' then
            if not Helpers.mapEquals(v, m1[k]) then
                return false
            end
        else
            if m1[k] ~= v then
                return false
            end
        end
    end
    return true
end

Helpers.roundToPlaces = function(num, places)
    local mult = 10^(places or 0)
    return math.floor(num * mult + 0.5) / mult
end

Helpers.colorFromGMST = function(gmst)
    local colorString = core.getGMST(gmst)
    local numberTable = {}
    for numberString in colorString:gmatch("([^,]+)") do
        if #numberTable == 3 then break end
        local number = tonumber(numberString:match("^%s*(.-)%s*$"))
        if number then
            table.insert(numberTable, number / 255)
        end
    end

    if #numberTable < 3 then error('Invalid color GMST name: ' .. gmst) end

    return util.color.rgb(table.unpack(numberTable))
end

return Helpers