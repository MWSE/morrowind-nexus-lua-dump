---A formatter allows you to register a set of substitutions to make when formatting a string.
---@class GuarWhisperer.Formatter
---@field substitutions table<string, function> A table of substitutions to make when formatting a string
local Formatter = {}

---A function that returns a string to substitute
---@alias GuarWhisperer.Formatter.substitution fun():string

---@param e { substitutions?: table<string, GuarWhisperer.Formatter.substitution> }
function Formatter.new(e)
    local self = setmetatable({}, { __index = Formatter })
    self.substitutions = {}
    if e.substitutions then
        for key, getValue in pairs(e.substitutions) do
            self:addSubstitution(key, getValue)
        end
    end
    return self
end

--- Returns the provided string with the first letter capitalised
function Formatter.capitaliseFirst(str)
    return str:gsub("^%l", string.upper)
end

--- Adds a substitution to the syntax.
---
--- The key is the string to replace, e.g "{name}"
---
--- The getValue function is called when formatting a string, and should return the value to substitute.
---
--- The key is added to the substitutions table, and a capitalised version of the key is also added.
---
--- i.e if you add a substitution for "{name}", a substitution for "{Name}" will also be added.
---@param key string The key to use for the substitution, e.g "{name}"
---@param getValue function A function that returns the value to substitute
function Formatter:addSubstitution(key, getValue)
    self.substitutions["{" .. key .. "}"] = getValue
    self.substitutions["{" .. Formatter.capitaliseFirst(key) .. "}"] = function() return Formatter.capitaliseFirst(getValue()) end
end

--- Returns the provided string with substitutions applied.
---
---@param message string
---@vararg any #Any additional arguments are passed to string.format
---@return string #The string with substutions made
function Formatter:format(message, ...)
    for key, getValue in pairs(self.substitutions) do
        message = message:gsub(key, getValue)
    end
    if ... then
        message = string.format(message, ...)
    end
    return message
end

return Formatter