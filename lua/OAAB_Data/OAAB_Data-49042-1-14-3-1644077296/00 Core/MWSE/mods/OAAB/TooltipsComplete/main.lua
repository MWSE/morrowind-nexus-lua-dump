local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData = {
    { id = "ab_dri_sillapi", description = "Sillapi is an egg miner's drink, sometimes used as a medicine as it can dull the pain and induce tranquil sleep. It's brewed from various kwama products, often right in the mines, and traditionally stored in a jug made of a treated kwama egg.", itemType = "ingredients" },
	{ id = "ab_ingcrea_dungcake", description = "A flat, crumbly patty made of dried manure. Has a slight musky smell.", itemType = "ingredients" },
	{ id = "ab_c_commonamulet02", description = "A common amulet fashioned from slaughterfish teeth. The teeth have an iridescent coating which makes them popular adornments.", itemType = "clothing" },
	{ id = "ab_misc_sfishhead", description = "A severed slaughterfish head. Frequently used as chum to attract other slaughterfish.", itemType = "miscItem" }
}
local function initialized()
    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end
event.register("initialized", initialized)