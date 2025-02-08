local common = require("mer.drip.common")
local logger = common.createLogger("tooltipsController")
local UI = require("mer.drip.common.ui")
local Modifier = require("mer.drip.components.Modifier")

---@param e uiObjectTooltipEventData
local function applyTooltips(e)
    logger:trace("tooltip")

    local modifiers = Modifier.getObjectModifiers(e.object)
    if modifiers and #modifiers > 0 then
        for _, modifier in ipairs(modifiers) do
            if modifier.description then
                logger:trace("Creating tooltip")
                UI.createEffectBlock{
                    tooltip = e.tooltip,
                    text = modifier.description,
                    color = { 0.1, 0.8, 0.1}
                }
            end
        end
    end
end

event.register("uiObjectTooltip", applyTooltips)