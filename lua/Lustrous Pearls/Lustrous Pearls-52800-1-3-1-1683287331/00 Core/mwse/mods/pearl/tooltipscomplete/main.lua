local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData = {

	-- Ingredients:
    { id = "pearl_blue_01", description = "Smooth, round, lustrous beads prized for ornamental purposes, Pearls are occasionally produced by the Kollop and other native Morrowind mollusks; their scarcity increasing their market value. This particular pearl has a bluish hue.", itemType = "ingredients" },
    { id = "pearl_blue_flawed_01", description = "Pearls are occasionally produced by the Kollop and other native Morrowind mollusks. This particular blue pearl has several flaws which will reduce its market value.", itemType = "ingredients" },
    { id = "pearl_green_01", description = "Smooth, round, lustrous beads prized for ornamental purposes, Pearls are occasionally produced by the Kollop and other native Morrowind mollusks; their scarcity increasing their market value. This particular pearl has a greenish hue.", itemType = "ingredients" },
    { id = "pearl_green_flawed_01", description = "Pearls are occasionally produced by the Kollop and other native Morrowind mollusks. This particular green pearl has several flaws which will reduce its market value.", itemType = "ingredients" },
    { id = "pearl_pink_01", description = "Smooth, round, lustrous beads prized for ornamental purposes, Pearls are occasionally produced by the Kollop and other native Morrowind mollusks; their scarcity increasing their market value. This particular pearl has a rare pink hue that is prized by artisans.", itemType = "ingredients" },
    { id = "pearl_silver_01", description = "Smooth, round, lustrous beads prized for ornamental purposes, Pearls are occasionally produced by the Kollop and other native Morrowind mollusks; their scarcity increasing their market value. This particular pearl has a silvery hue.", itemType = "ingredients" },
    { id = "pearl_silver_flawed_01", description = "Pearls are occasionally produced by the Kollop and other native Morrowind mollusks. This particular silver pearl has several flaws which will reduce its value.", itemType = "ingredients" },
    { id = "pearl_white_flawed_01", description = "Pearls are occasionally produced by the Kollop and other native Morrowind mollusks. This particular pearl has several flaws which will reduce its market value.", itemType = "ingredients" },
    { id = "pearl_white_rough_01", description = "Pearls are occasionally produced by the Kollop and other native Morrowind mollusks. This particular pearl has many imperfections which will reduce its market value.", itemType = "ingredients" },
    { id = "pearl_ultima", description = "Uncommon, silvery, lustrous, spherical pearls found in kollops. This rare stone has powerful effects.", itemType = "ingredients" },
    { id = "pearl_ultima_uni", description = "An unusual choice for a focusing crystal, this rare stone can be found in kollops. Difficult to properly install in a weapon, this valuable stone has powerful effects.", itemType = "ingredients" },
	
	-- Clothing:
	{ id = "pearl_amulet_common", description = "A common amulet fashioned from a rough pearl.", itemType = "clothing" },
	{ id = "pearl_amulet_expensive", description = "An expensive amulet crafted from silver with a black pearl set in it.", itemType = "clothing" },
	{ id = "pearl_amulet_extravagant", description = "An extravagant amulet with multiple pearls strung along a gold chain.", itemType = "clothing" },
	{ id = "pearl_amulet_exquisite", description = "An exquisite amulet made with a large, gold ornament set with several rare, pink pearls.", itemType = "clothing" },
	{ id = "pearl_amulet_common_en", description = "Enchanted amulet which allows the wearer to fly swiftly into the Blue Horizon.", itemType = "clothing" },
	{ id = "pearl_amulet_expensive_en", description = "Enchanted amulet which grants the wearer the sight and breath to brave the Deep.", itemType = "clothing" },
	{ id = "pearl_amulet_extravagant_en", description = "Enchanted amulet which cleanses the wearer with the purity of Lustrous Pearls.", itemType = "clothing" },
	{ id = "pearl_amulet_exquisite_en", description = "Enchanted amulet which endows the wearer with the skill to seek the Golden Shores.", itemType = "clothing" },
	
	-- Weapons:
	{ id = "pearl_sword", description = "An elegant weapon for a more civilized age.", itemType = "weapon" },
}
local function initialized()
    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end
event.register("initialized", initialized)