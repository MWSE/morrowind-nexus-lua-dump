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