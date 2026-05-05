---@class Trait
---@field id string id of the trait
---@field type string type of the trait
---@field name string The name of the trait
---@field description string A description of the trait
---@field checkDisabled? fun():boolean  *(Optional)* Returns true if this trait is disabled
---@field doOnce? fun(self:Trait) *(Optional)* Called once when trait is selected.
---@field onLoad? fun(self:Trait) *(Optional)* Called on load and when trait is selected.
local Trait = {}
Trait.__index = Trait

local function validateRequiredFields(data)
    assert(
        data.id,
        "Trait must have an id."
    )
    assert(
        data.type,
        string.format("Trait '%s' must have a name.", data.id)
    )
    assert(
        data.name,
        string.format("Trait '%s' must have a name.", data.id)
    )
    assert(
        data.description,
        string.format("Trait '%s' must have a description.", data.id)
    )
end

function Trait:new(data)
    validateRequiredFields(data)

    local obj = setmetatable({}, Trait)

    obj.id = data.id:lower()
    obj.type = data.type:lower()
    obj.name = data.name
    obj.description = data.description
    obj.checkDisabled = data.checkDisabled or function() return false end
    obj.doOnce = data.doOnce or function() end
    obj.onLoad = data.onLoad or function() end

    return obj
end

function Trait:__tostring()
    return "{" ..
        "\n  id: " .. self.id ..
        "\n  type: " .. self.type ..
        "\n  name: " .. self.name ..
        "\n  description: " .. self.description ..
        "\n  checkDisabled: " .. ("present" or "nil") ..
        "\n  doOnce: " .. ("present" or "nil") ..
        "\n  onLoad: " .. ("present" or "nil") ..
        "\n}"
end

return Trait
