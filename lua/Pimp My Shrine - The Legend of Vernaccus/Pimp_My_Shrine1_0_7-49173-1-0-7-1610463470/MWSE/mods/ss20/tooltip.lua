local common = require('ss20.common')
local config = common.config

local function onTooltip(e)

    --Add special case for Soul Shards

    config.tooltipMapping.ss20_Bottle_of_Souls = function()
        return string.format("Soul Shards: %d", common.getSoulShards() )
    end


    for id, message in pairs(config.tooltipMapping) do
        if e.object.id:lower() == id:lower() then
            local msg
            if type(message) == 'function' then
                msg = message()
            elseif type(message) == 'string' then
                msg = message
            end
            common.addTooltipMessage(e.tooltip, msg)
        end
    end
end
event.register("uiObjectTooltip", onTooltip, { priority = -1 })