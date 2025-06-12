-- ZModUtils - Utility.lua
-- Convenience file to gather the sub libraries.

local items = require("scripts.ZModUtils.Utility.Items")
local magic = require("scripts.ZModUtils.Utility.Magic")
local stats = require("scripts.ZModUtils.Utility.Stats")


-- Utility Function
-- Traverses content in layouts recursively until it finds a layout with the right name,
-- may be slow for large content hierarchies
local function findLayoutByNameRecursive(content, layoutName)
    if type(content) ~= 'table' then
        return nil
    end

    local result = nil

    for i=1, #content do
        if content[i].name == layoutName then
            return content[i]
        end

        if content[i].content ~= nil then
            result = findLayoutByNameRecursive(content[i].content, layoutName)
        end

        if result ~= nil then break end
    end

    return result
end

------------------------------------------------
-- Implementation of bind like std::bind
-- Just grabbed online
------------------------------------------------
local function packn(...)
    return {n = select('#', ...), ...}
end
  
local function unpackn(t)
    return table.unpack(t, 1, t.n)
end
  
local function mergen(...)
    local res = {n=0}
    for i = 1, select('#', ...) do
      local t = select(i, ...)
      for j = 1, t.n do
        res.n = res.n + 1
        res[res.n] = t[j]
      end
    end
    return res
  end
  
local function bind(func, ...)
    local args = packn(...)
    return function (...)
      return func(unpackn(mergen(args, packn(...))))
    end
end

local function round(val, decimal)
    if not val then return 0 end

    if (decimal) then
        return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
    else
        return math.floor(val+0.5)
    end
end

local lib = {
    version = 1,

    -- Sub Libraries
    Items = items,
    Magic = magic,
    Misc = misc,
    Stats = stats,

    -- Capitalizes the first letter of text
    capitalize = function(text)
        if type(text) ~= 'string' then return nil end
        if #text < 2 then return string.upper(text) end

        return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2, #text)
    end,

    round = round,

    -- Formats numbers the same way that the default tooltips do, ie 0.75 => '0.75', 0.30 => '0.3'.
    formatNumber = function(num)
        local r = round(num, 2)
        local numStr = string.format('%.2f', r)
    
        -- Get the integer and decimal parts of the string
        local i, d = numStr:match('([0-9]*).([0-9]*)')
        numStr = i

        -- Remove any trailing zeroes from the decimal part
        d = d:gsub('0*$', '')

        -- if the decimal part still contains anything, re attach it.
        if #d > 0 then
            numStr = numStr .. '.' .. d
        end

        return numStr
    end,

    -----------------------
    -- General/Function
    -----------------------
    
    -- similar to std bind. 
    -- function(a, b, c) ...
    -- bindFunction(func, a, b) => function(c)
    bindFunction = bind,

    -- Helper for checking if thing is equal to any of the other parameters
    -- example equalAnyOf(myColor, 'blue', 'green', 'red')) is equivalent to
    -- ((myColor == 'blue') or (myColor == 'green') or (myColor == 'red'))
    equalAnyOf = function(thing, ...)
        local args = { ... }
        for i, v in pairs(args) do
            if (thing == v) then return true end
        end
        return false
    end,

    -- Searches for a layout with the paramter name recursively through a content hierarchy.
    -- It's usually best to avoid using it but it can be helpful.
    findLayoutByNameRecursive = findLayoutByNameRecursive,
}

return lib