local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData = {
    { id = "mdWW_Misc_SilverLark", description = "This intricately crafted figurine of a lark is made from fine silver. The ring it makes when struck softly is reminiscent of a bird's song.", itemType = "miscItem" },
    { id = "mdWW_Misc_AshStatue", description = "The glowing red eyes of the statue seem to be watching you.", itemType = "miscItem" }
}
local function initialized()
    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end
event.register("initialized", initialized)