local Util = require("CraftingFramework.util.Util")

---@class craftingFrameworkCustomRequirement
local CustomRequirement = {
    schema = {
        name = "CustomRequirement",
        fields = {
            getLabel = { type = "function",  required = false},
            description = { type = "string", required = false},
            check = { type = "function",  required = true},
            showInMenu = { type = "boolean", default = true, required = false},
        }
    }
}

---Constructor
---@param data craftingFrameworkCustomRequirementData
---@return craftingFrameworkCustomRequirement customRequirement
function CustomRequirement:new(data)
    Util.validate(data, CustomRequirement.schema)
    setmetatable(data, self)
    self.__index = self
    ---@cast data -craftingFrameworkCustomRequirementData
    ---@type craftingFrameworkCustomRequirement
    local customReq = data
    return customReq
end

function CustomRequirement:getLabel()
    return ""
end

function CustomRequirement:check()
    return false
end

return CustomRequirement