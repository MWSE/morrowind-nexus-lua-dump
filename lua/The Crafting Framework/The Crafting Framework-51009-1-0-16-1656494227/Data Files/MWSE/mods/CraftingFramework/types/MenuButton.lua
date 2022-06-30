---@meta

---@class craftingFrameworkTooltipData
---@field header string|fun(): string The header text for the tooltip or a function that returns one.
---@field text string The description text of the tooltip.

---@class craftingFrameworkMenuButtonData
---@field text string **Required.** The text on the button.
---@field callback function This function is called after the associated button is created.
---@field tooltip craftingFrameworkTooltipData This is the tooltip shown when the button is enabled.
---@field tooltipDisabled craftingFrameworkTooltipData This tooltip is shown when the button is disabled.
---@field enableRequirements fun(reference: tes3reference): boolean If this function returns `flase`, the associated button will be disabled.
---@field showRequirements fun(reference: tes3reference): boolean If this function returns `false`, the associated button will not be created.
