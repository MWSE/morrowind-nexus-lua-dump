local Class = require("seph.hudCustomizer.lib.class")

--- @class Version : Class
--- @field major number The major version number.
--- @field minor number The minor version number.
--- @field patch number The patch version number.
local Version = Class()

Version.major = 0
Version.minor = 0
Version.patch = 0

--- Creates a new Version instance from a table.
--- @param from table The table to convert to a new Version instance. Must have the number fields 'major', 'minor' and 'patch'.
--- @return Version
function Version.fromTable(from)
    assert(type(from) == "table", "from must be a table")
    return Version{major = tonumber(from.major or 0), minor = tonumber(from.minor or 0), patch = tonumber(from.patch or 0)}
end

--- Creates a new Version instance from a string.
--- @param from string The string to convert to a new Version instance.
--- @param separator string Optional. Defaults to ".". The string used to separate the major, minor and patch fields.
--- @return Version
function Version.fromString(from, separator)
    assert(type(from) == "string", "from must be a string")
    assert(separator == nil or type(separator) == "string", "separator must be a string or nil")
    local versions = string.split(from, separator or ".")
    return Version{major = tonumber(versions[1] or 0), minor = tonumber(versions[2] or 0), patch = tonumber(versions[3] or 0)}
end

--- Creates a new Version instance from a number. Only the major field will be set.
--- @param from number The number to convert to a new Version instance.
--- @return Version
function Version.fromNumber(from)
    assert(type(from) == "number", "from must be a number")
    return Version{major = math.floor(from), minor = 0, patch = 0}
end

--- Creates a new Version instance from any value. A default new Version instance will be returned if no valid value has been passed as an argument.
--- @param from any The value to convert to a new Version instance.
--- @return Version
function Version.fromAny(from)
    if Version:isClassOf(from) then
        return from:copy()
    elseif type(from) == "table" then
        return Version.fromTable(from)
    elseif type(from) == "string" then
        return Version.fromString(from)
    elseif type(from) == "number" then
        return Version.fromNumber(from)
    else
        return Version()
    end
end

--- Converts this Version to a table that contains the number fields 'major', 'minor' and 'patch'.
--- @return table
function Version:toTable()
    return {major = self.major, minor = self.minor, patch = self.patch}
end

--- Converts this Version to a printable string.
--- @param separator string Optional. Defaults to ".". The string used to separate the major, minor and patch fields.
--- @return string
function Version:toString(separator)
    assert(separator == nil or type(separator) == "string", "separator must be a string or nil")
    separator = separator or "."
    return string.format("%d%s%d%s%d", self.major, separator, self.minor, separator, self.patch)
end

--- Checks if this Version is equal to another Version.
--- @param version Version The Version to check against.
--- @return boolean
function Version:isEqualTo(version)
    assert(Version:isClassOf(version), "version must be a Version")
    return self.major == version.major and self.minor == version.minor and self.patch == version.patch
end

--- Checks if this Version is greater than another Version.
--- @param version Version The Version to check against.
--- @return boolean
function Version:isGreaterThan(version)
    assert(Version:isClassOf(version), "version must be a Version")
    local values = {self.major, self.minor, self.patch}
    local versionValues = {version.major, version.minor, version.patch}
    for index = 1, #values, 1 do
        local compare = values[index] - versionValues[index]
        if compare < 0 then
            return false
        elseif compare > 0 then
            return true
        end
    end
    return false
end

--- Checks if this Version is smaller than another Version.
--- @param version Version The Version to check against.
--- @return boolean
function Version:isLessThan(version)
    return not self:isEqualTo(version) and not self:isGreaterThan(version)
end

return Version