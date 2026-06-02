local util = require("openmw.util")

-- handlers get called from end to beginning
-- must be an array
local handlers = {}

local met = {}
function met:updateHandlerOrder()
    table.sort(handlers, function(a, b)
        return (a.priority or -math.huge) < (b.priority or -math.huge)
    end)
end

function met:getIndex(name)
    for index, handler in ipairs(handlers) do
        if handler.name == name:lower() then
            return index
        end
    end
end

function met:get()
    return handlers
end

function met:add(fn, name, priority)
    if type(fn) ~= "function" then error("must provide a valid function for handler", 2) end
    if type(name) ~= "string" then error("must provide a valid name for handler", 2) end
    if self:getIndex(name) then error("handler with that name already exist", 2) end
    table.insert(handlers, util.makeReadOnly { name = name:lower(), fn = fn, added = true, priority = priority })
    self:updateHandlerOrder()
    print(string.format("`%s` added to pursuit handlers", name))
end

function met:remove(name)
    local index = self:getIndex(name)
    if not index then
        error(string.format("Handler `%s` not found", name), 2)
    end
    if not handlers[index].added then
        error(string.format("Unable to remove core handler `%s`", name), 2)
    end
    table.remove(handlers, index)
    self:updateHandlerOrder()
    print(string.format("`%s` removed from pursuit handlers", name))
end

function met:updateHandlers()
    local vfs = require("openmw.vfs")
    local extraSettings = {}
    for file in vfs.pathsWithPrefix("scripts\\pursuit\\handlers") do
        if file:sub(-4) == ".lua" then
            local module = file:sub(1, -5)
            local handler = require(module:gsub("[/\\]", "."))
            if handler then
                table.insert(handlers,
                    util.makeReadOnly { name = handler.name:lower(), fn = handler.fn, priority = handler.priority })
                for _, setting in ipairs(handler.settings or {}) do
                    table.insert(extraSettings, setting)
                end
            end
        end
    end
    self:updateHandlerOrder()
    return extraSettings
end

setmetatable(handlers, {
    __index = function(t, name)
        local index = met:getIndex(name)
        return rawget(handlers, index)
    end
})
return met
