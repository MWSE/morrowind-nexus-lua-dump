local data = require("ConsistentKeys.data")

local this = {}

this.checkKey = function(object)
    if object.isKey or data.keyList[object.id:lower()] then
        return true
    end

    local nameLower = object.name:lower()

    -- Dynamically detects keys that aren't in the data table based on names.
    if string.find(nameLower, "key ") == 1
    or string.endswith(nameLower, " key")
    or string.find(nameLower, " key ") then
        return true
    end

    return false
end

this.checkValidObject = function(object)
    local name = object.name

    if ( not name )
    or name == "" then
        return false
    end

    return true
end

return this