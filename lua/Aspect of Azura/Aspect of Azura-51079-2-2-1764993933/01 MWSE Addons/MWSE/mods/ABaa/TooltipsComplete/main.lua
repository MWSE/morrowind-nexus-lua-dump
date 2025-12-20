local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData = {
    { id = "ABaa_Gatekey", description = "A rose-colored gemstone which crackles with daedric energy.", itemType = "miscItem" }
}
local function initialized()
    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end
event.register("initialized", initialized)