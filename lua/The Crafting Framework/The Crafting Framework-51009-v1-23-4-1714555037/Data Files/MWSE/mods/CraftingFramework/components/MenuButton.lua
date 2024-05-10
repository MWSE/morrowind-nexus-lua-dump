---@meta

---@class craftingFrameworkTooltipData
---@field header string|fun(): string The header text for the tooltip or a function that returns one.
---@field text string The description text of the tooltip.

---@class craftingFrameworkMenuButtonData.callbackParams
---@field reference tes3reference

---@class craftingFrameworkMenuButtonData
---@field text string **Required.** The text on the button.
---@field callback? fun(e: craftingFrameworkMenuButtonData.callbackParams | nil) This function is called after the associated button is created.
---@field tooltip? tes3ui.showMessageMenu.params.tooltip|fun(callbackParams: table): tes3ui.showMessageMenu.params.tooltip|nil A table with header and text that will display as a tooltip when an enabled button is hovered over. Can also be a function that returns a tes3ui.showMessageMenu.params.tooltip.
---@field tooltipDisabled? string|tes3ui.showMessageMenu.params.tooltip|fun(callbackParams: table): tes3ui.showMessageMenu.params.tooltip|nil The tooltip to show when the button is disabled. Can be a simple string or a table with header and text that will display as a tooltip when a disabled button is hovered over. Can also be a function that returns a `tes3ui.showMessageMenu.params.tooltip`.
---@field enableRequirements? fun(e: craftingFrameworkMenuButtonData.callbackParams): boolean If this function returns `flase`, the associated button will be disabled.
---@field showRequirements? fun(e: craftingFrameworkMenuButtonData.callbackParams): boolean If this function returns `false`, the associated button will not be created.


local TooltipSchema = {
    name = "Tooltip",
    fields = {
        header = { type = "string|function", required = false },
        text = { type = "string", required = false }
    }
}
local ButtonSchema = {
    name = "MenuButton",
    fields = {
        text = { type = "string", required = true },
        callback = { type = "function", required = false },
        tooltip = { type = TooltipSchema, required = false },
        tooltipDisabled = { type = TooltipSchema, required = false },
        enableRequirements = { type = "function", required = false },
        showRequirements = { type = "function", required = false },
    }
}

local MenuButton = {
    schema = ButtonSchema
}

return MenuButton