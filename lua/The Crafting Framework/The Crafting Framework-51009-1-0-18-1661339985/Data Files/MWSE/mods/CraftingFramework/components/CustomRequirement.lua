local Util = require("CraftingFramework.util.Util")

---@class craftingFrameworkCustomRequirement
local CustomRequirement = {
    schema = {
        name = "CustomRequirement",
        fields = {
            getLabel = { type = "function",  required = true},
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
    return data
end

function CustomRequirement:getLabel()
    return nil
end

function CustomRequirement:check()
    return nil
end

return CustomRequirement