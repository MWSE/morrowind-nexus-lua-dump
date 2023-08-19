local common = require("mer.drip.common")
local config = common.config
local logger = common.createLogger("Unique")

---@type DripUnique
local Unique = {}

function Unique:new(data)
    local unique = {}
    setmetatable(unique, self)
    self.__index = self

    unique.name = data.name
    unique.description = data.description
    unique.baseObject = data.baseObject
    unique.mesh = data.mesh

    return unique
end

return Unique