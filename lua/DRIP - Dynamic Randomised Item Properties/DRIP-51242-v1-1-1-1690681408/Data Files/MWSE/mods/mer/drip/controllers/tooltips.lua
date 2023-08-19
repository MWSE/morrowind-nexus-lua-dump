local common = require("mer.drip.common")
local logger = common.createLogger("tooltipsController")
local UI = require("mer.drip.common.ui")
local Modifier = require("mer.drip.components.Modifier")

---@param e uiObjectTooltipEventData
local function applyTooltips(e)
    logger:trace("tooltip")
    local id = e.object and e.object.id:lower()
    local data = common.config.persistent.generatedLoot[id]
    if data and data.modifiers then
        logger:trace("Looking at Loot")
        for _, modifierData in ipairs(data.modifiers) do
            local modifier = Modifier:new(modifierData)
            if modifier then
                if modifier.description then
                    logger:trace("Creating tooltip")
                    UI.createEffectBlock{
                        tooltip = e.tooltip,
                        text = modifier.description,
                        icon = modifier.icon,
                        color = { 0.1, 0.8, 0.1}
                    }
                end
            end
        end
    end
end

event.register("uiObjectTooltip", applyTooltips)