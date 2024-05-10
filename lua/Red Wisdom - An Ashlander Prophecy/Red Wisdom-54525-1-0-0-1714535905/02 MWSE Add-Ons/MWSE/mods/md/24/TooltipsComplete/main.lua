local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData = {
    { id = "md24_inscguarhide", description = "This ancient guar hide is inscribed with esoteric symbols.", itemType = "miscItem" },
    { id = "md24_c_ashbanegirdle", description = "Crafted from supple leather and dyed in the fiery hues of sunset, the belt exudes a faint warmth reminiscent of the fires of Red Mountain itself.", itemType = "clothing" },
	{ id = "md24_c_stoneofgrounding", description = "The stone's surface is etched with scars from repeated lightning strikes.", itemType = "clothing" },
	{ id = "md24_c_thetwelfthtalisman", description = "A large, aquamarine stone sits in the center of the talisman. Colorful shells woven together by leather straps seem to whisper tales of forgotten shores if you listen closely.", itemType = "clothing" },
	{ id = "md24_c_thewhirlingband", description = "A sleek, ebony ring adorned with swirling glyphs that seem to dance and writhe like tendrils of smoke. When worn, the ring emits a faint hum, as if echoing the wind itself.", itemType = "clothing" },
    { id = "md24_ingcrea_moonjelly", description = "This glowing, gelatinous substance comes from the juvenile life stage of the netch which are commonly known as 'Moon Jellies'.", itemType = "ingredient" },
    { id = "md24_ingflor_lotusblood", description = "The rare Blood Lotus flower represents 'rebirth through death' to the Ashlander tribes of Morrowind.", itemType = "ingredient" },
    { id = "md24_clumsy_spear", description = "The unusually spiny tip of this chitin spear is mystically enchanted to sap the mobility from a foe.", itemType = "weapon" },
    { id = "md24_sureflight_bow", description = "This high quality chitin bow was crafted by an Erabenimsun warrior and is perfect for hunting game.", itemType = "weapon" }
}
local function initialized()
    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end
event.register("initialized", initialized)