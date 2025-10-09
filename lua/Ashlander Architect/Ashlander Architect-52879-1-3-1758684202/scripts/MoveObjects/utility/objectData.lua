local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local interfaces = require("openmw.interfaces")
local vfs = require("openmw.vfs")
local celldata = storage.globalSection("cellData")

local ObjectData = {}

local function onSave()
    return {
        ObjectData = ObjectData,
    }
end
local function onLoad(data)
    if data then
        ObjectData = data.ObjectData
    end
end

local function getGameObject(obj)
    local wrapper = {
        __object = obj
    }
end
local function wrapObject(obj)
    if obj.__isWrapped then
        return obj -- Already wrapped, just return
    end

    local wrapper = {
        __object = obj,
        __id = obj.id,
        __data = ObjectData[obj.id] or {},
        __isWrapped = true, -- marker to avoid double wrapping
    }

    setmetatable(wrapper, {
        __index = function(tbl, key)
            local data = rawget(tbl, "__data")
            local inner = rawget(tbl, "__object")

            if data and data[key] ~= nil then
                return data[key]
            end

            local val = inner[key]
            if type(val) == "function" then
                return function(_, ...)
                    return val(inner, ...)
                end
            else
                return val
            end
        end,

        __newindex = function(tbl, key, value)
            local data = rawget(tbl, "__data")
            data[key] = value
        end
    })

    return wrapper
end
return {
    interfaceName = "ObjectData",
    interface = {
        wrapObject = wrapObject,
        getGameObject = getGameObject,
        version = 1,
    },
    eventHandlers = {
    },
    engineHandlers = {
        onLoad = onLoad, onSave = onSave
    },

}
