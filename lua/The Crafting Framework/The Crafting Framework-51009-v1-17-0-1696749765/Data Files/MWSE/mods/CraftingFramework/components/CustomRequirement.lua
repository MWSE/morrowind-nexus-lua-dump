local Util = require("CraftingFramework.util.Util")

---@class CraftingFramework.CustomRequirement.data
---@field getLabel fun(): string **Required.** This method should return the text that needs to be displayed for this `customRequirement` in the Crafting Menu.
---@field description? string The description for the requirement.
---@field check fun(): boolean, string? **Required.** This method will be called on this `customRequirement` object when performing checks whether an item can be crafted. The function should return `false` if the conditions aren't met, and also a reason (string), why the item can't be crafted.
---@field showInMenu? boolean *Default*: `true`. This property controls if this `customRequirement` will be shown in the Crafting Menu.


---@class CraftingFramework.CustomRequirement : CraftingFramework.CustomRequirement.data
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
---@param data CraftingFramework.CustomRequirement.data
---@return CraftingFramework.CustomRequirement customRequirement
function CustomRequirement:new(data)
    Util.validate(data, CustomRequirement.schema)
    data = table.copy(data)
    setmetatable(data, self)
    self.__index = self
    ---@cast data -CraftingFramework.CustomRequirement.data
    ---@type CraftingFramework.CustomRequirement
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