---@meta

---@class craftingFrameworkCustomRequirementData
---@field getLabel fun(): string **Required.** This method should return the text that needs to be displayed for this `customRequirement` in the Crafting Menu.
---@field description string The description for the requirement.
---@field check fun(): boolean, string **Required.** This method will be called on this `customRequirement` object when performing checks whether an item can be crafted. The function should return `false` if the conditions aren't met, and also a reason (string), why the item can't be crafted.
---@field showInMenu boolean *Default*: `true`. This property controls if this `customRequirement` will be shown in the Crafting Menu.

---@class craftingFrameworkCustomRequirement
---@field getLabel fun(): string This method should return the text that needs to be displayed for this `customRequirement` in the Crafting Menu.
---@field description string The description for the requirement.
---@field check fun(): boolean, string This method will be called on this `customRequirement` object when performing checks whether an item can be crafted. The function should return `false` if the conditions aren't met, and also a reason (string), why the item can't be crafted.
---@field showInMenu boolean This property controls if this `customRequirement` will be shown in the Crafting Menu.
craftingFrameworkCustomRequirement = {}

---@param data craftingFrameworkCustomRequirementData This table accepts following values:
---
--- `getLabel`: fun():string — **Required.** This method should return the text that needs to be displayed for this `customRequirement` in the Crafting Menu.
---
--- `description`: string — The description for the requirement.
---
--- `check`: fun():boolean, string — **Required.** This method will be called on this `customRequirement` object when performing checks whether an item can be crafted. The function should return `false` if the conditions aren't met, and also a reason (string), why the item can't be crafted.
---
--- `showInMenu`: boolean —  *Default*: `true`. This property controls if this `customRequirement` will be shown in the Crafting Menu.
---@return craftingFrameworkCustomRequirement customRequirement
function craftingFrameworkCustomRequirement:new(data) end
