local function initialized()
	tes3.addSoulGem({ item = "Misc_SoulGem_Magnificent" })
end
event.register("initialized", initialized)
local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData = {
    { id = "misc_soulgem_magnificent", description = "A wondrous magical gem thought to be capable of trapping the soul of any living creature. Such gems are essential to the creation and recharging of magical items, but those with the means to utilize a device of this splendor may find that destructive process a waste of potential.", itemType = "soulGem" }
}
local function initialized()
    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end
event.register("initialized", initialized)