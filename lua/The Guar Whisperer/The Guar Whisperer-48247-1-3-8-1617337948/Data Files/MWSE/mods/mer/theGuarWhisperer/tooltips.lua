local tooltipsComplete = include("Tooltips Complete.interop")
local common = require("mer.theGuarWhisperer.common")

local tooltipData = {
    { id =  common.packId, description = "This pack allows a well trained guar to carry a large amount of gear."},
    { id = common.ballId, description = "Guars love playing fetch. Avoid ruining your boots and have them retrieve this ball instead."},
    { id = common.fluteId, description = "If your guar companion ever gets lost, simply play a tune on this flute and they will come back to you."}
}

for _, data in ipairs(tooltipData) do
    if tooltipsComplete then
        tooltipsComplete.addTooltip(data.id, data.description)
    end
end