local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData = {
	{ id = "t_de_dreugh_boots_01", description = "Remarkably tough for their weight, Dreugh boots are created from the carapace of the ancient aquatic Dreughs inhabiting the seas of Tamriel. Their humanoid structure allows for relatively easy implementation of the shell into a piece of armor, but acquiring the material is another matter.", itemType = "armor" },
	{ id = "t_de_dreugh_bracerl_01", description = "Remarkably tough for their weight, Dreugh bracers are created from the carapace of the ancient aquatic Dreughs inhabiting the seas of Tamriel. Their humanoid structure allows for relatively easy implementation of the shell into a piece of armor, but acquiring the material is another matter.", itemType = "armor" },
	{ id = "t_de_dreugh_bracerr_01", description = "Remarkably tough for their weight, Dreugh bracers are created from the carapace of the ancient aquatic Dreughs inhabiting the seas of Tamriel. Their humanoid structure allows for relatively easy implementation of the shell into a piece of armor, but acquiring the material is another matter.", itemType = "armor" },
	{ id = "t_de_dreugh_greaves_01", description = "Remarkably tough for their weight, Dreugh greaves are created from the carapace of the ancient aquatic Dreughs inhabiting the seas of Tamriel. Their humanoid structure allows for relatively easy implementation of the shell into a piece of armor, but acquiring the material is another matter.", itemType = "armor" },
	{ id = "t_de_dreugh_pauldronl_01", description = "Remarkably tough for their weight, Dreugh pauldrons are created from the carapace of the ancient aquatic Dreughs inhabiting the seas of Tamriel. Their humanoid structure allows for relatively easy implementation of the shell into a piece of armor, but acquiring the material is another matter.", itemType = "armor" },
	{ id = "t_de_dreugh_pauldronr_01", description = "Remarkably tough for their weight, Dreugh pauldrons are created from the carapace of the ancient aquatic Dreughs inhabiting the seas of Tamriel. Their humanoid structure allows for relatively easy implementation of the shell into a piece of armor, but acquiring the material is another matter.", itemType = "armor" },
	{ id = "t_imp_studdedleather_boots_01", description = "Less commonly employed by the Legion, Imperial Studded Leather boots are fashioned from tough leather that has been reinforced with close-set steel rivets.", itemType = "armor" },
	{ id = "t_imp_studdedleather_bracerl_01", description = "Less commonly employed by the Legion, Imperial Studded Leather bracers are fashioned from tough leather that has been reinforced with close-set steel rivets.", itemType = "armor" },
	{ id = "t_imp_studdedleather_bracerr_01", description = "Less commonly employed by the Legion, Imperial Studded Leather bracers are fashioned from tough leather that has been reinforced with close-set steel rivets.", itemType = "armor" },
	{ id = "t_imp_studdedleather_greaves_01", description = "Less commonly employed by the Legion, Imperial Studded Leather greaves are fashioned from tough leather that has been reinforced with close-set steel rivets.", itemType = "armor" },
	{ id = "t_imp_studdedleather_helm_01", description = "Less commonly employed by the Legion, Imperial Studded Leather helms are fashioned from tough leather that has been reinforced with close-set steel rivets.", itemType = "armor" },
	{ id = "t_imp_studdedleather_pauldrl_01", description = "Less commonly employed by the Legion, Imperial Studded Leather pauldrons are fashioned from tough leather that has been reinforced with close-set steel rivets.", itemType = "armor" },
	{ id = "t_imp_studdedleather_pauldrr_01", description = "Less commonly employed by the Legion, Imperial Studded Leather pauldrons are fashioned from tough leather that has been reinforced with close-set steel rivets.", itemType = "armor" },
	{ id = "t_nor_iron_boots_01", description = "Native to the northern province of Skyrim, Nordic Iron boots are crafted from common iron but designed in the cultural flavour of the Nords. While stronger than both Imperial iron and steel, it is notably heavier.", itemType = "armor" },
	{ id = "t_nor_iron_gauntletl_01", description = "Native to the northern province of Skyrim, Nordic Iron gauntlets are crafted from common iron but designed in the cultural flavour of the Nords. While stronger than both Imperial iron and steel, it is notably heavier.", itemType = "armor" },
	{ id = "t_nor_iron_gauntletr_01", description = "Native to the northern province of Skyrim, Nordic Iron gauntlets are crafted from common iron but designed in the cultural flavour of the Nords. While stronger than both Imperial iron and steel, it is notably heavier.", itemType = "armor" },
	{ id = "t_nor_iron_greaves_01", description = "Native to the northern province of Skyrim, Nordic Iron greaves are crafted from common iron but designed in the cultural flavour of the Nords. While stronger than both Imperial iron and steel, it is notably heavier.", itemType = "armor" },
	{ id = "t_nor_iron_pauldronl_01", description = "Native to the northern province of Skyrim, Nordic Iron pauldrons are crafted from common iron but designed in the cultural flavour of the Nords. While stronger than both Imperial iron and steel, it is notably heavier.", itemType = "armor" },
	{ id = "t_nor_iron_pauldronr_01", description = "Native to the northern province of Skyrim, Nordic Iron pauldrons are crafted from common iron but designed in the cultural flavour of the Nords. While stronger than both Imperial iron and steel, it is notably heavier.", itemType = "armor" },
	{ id = "_rv_Daedric_helm_dagon", description = "Among the most rare and valuable treasures of Tamriel, the Daedric Face of the Husband of Fire depicts an aspect of the Daedric Prince of Darkness and Destruction, Mehrunes Dagon. Having once been widely worshipped among the Chimer ancestors of the Dark Elves, the Daedroth now stands as one of the Four Corners of the House of Troubles.", itemType = "armor" },
	{ id = "_rv_Daedric_helm_molag", description = "Among the most rare and valuable treasures of Tamriel, the Daedric Face of the Forbidden Tickle depicts an aspect of the Daedric Prince of Domination, Molag Bal. Having once been widely worshipped among the Chimer ancestors of the Dark Elves, the Daedroth now stands as one of the Four Corners of the House of Troubles.", itemType = "armor" },
	{ id = "_rv_Daedric_helm_sheo", description = "Among the most rare and valuable treasures of Tamriel, the Daedric Face of Comforting Tendrils depicts an aspect of the Daedric Prince of Madness, Sheogorath. Having once been widely worshipped among the Chimer ancestors of the Dark Elves, the Daedroth now stands as one of the Four Corners of the House of Troubles.", itemType = "armor" },
	{ id = "_RV_Duke's_helmet", description = "Fashioned from silver imported from the Empire, Duke's Guard helmets are worn by the personal guard of Vedam Dren, Duke of the Imperial District of Vvardenfell and Grandmaster of House Hlaalu.", itemType = "armor" },
	{ id = "_RV_Duke's_greaves", description = "Fashioned from silver imported from the Empire, Duke's Guard greaves are worn by the personal guard of Vedam Dren, Duke of the Imperial District of Vvardenfell and Grandmaster of House Hlaalu.", itemType = "armor" },
	{ id = "_RV_Duke's_Boots", description = "Fashioned from silver imported from the Empire, Duke's Guard boots are worn by the personal guard of Vedam Dren, Duke of the Imperial District of Vvardenfell and Grandmaster of House Hlaalu.", itemType = "armor" },
	{ id = "_RV_Duke's_pauld_R", description = "Fashioned from silver imported from the Empire, Duke's Guard pauldrons are worn by the personal guard of Vedam Dren, Duke of the Imperial District of Vvardenfell and Grandmaster of House Hlaalu.", itemType = "armor" },
	{ id = "_RV_Duke's_pauld_L", description = "Fashioned from silver imported from the Empire, Duke's Guard pauldrons are worn by the personal guard of Vedam Dren, Duke of the Imperial District of Vvardenfell and Grandmaster of House Hlaalu.", itemType = "armor" },
	{ id = "_RV_Duke's_Gauntlet_R", description = "Fashioned from silver imported from the Empire, Duke's Guard gauntlets are worn by the personal guard of Vedam Dren, Duke of the Imperial District of Vvardenfell and Grandmaster of House Hlaalu.", itemType = "armor" },
	{ id = "_RV_Duke's_Gauntlet_L", description = "Fashioned from silver imported from the Empire, Duke's Guard gauntlets are worn by the personal guard of Vedam Dren, Duke of the Imperial District of Vvardenfell and Grandmaster of House Hlaalu.", itemType = "armor" },
}

local function initialized()
    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end
event.register("initialized", initialized)

-- key - Generic keys or other objects used to unlock or activate objects, such as Propylon Indices. Lockpicks do NOT fall under this category.
-- quest - Items required for the completion of a quest.
-- unique - Notable items which may only be found once or rewarded once after a quest, generally have the same appearance as other generic items.
-- artifact - Objects with a unique appearance and lore significance, such as Daedric and Aedric objects.
-- armor - Regular and generic enchanted armor and shields.
-- weapon - Regular and generic enchanted weapons and ammunition.
-- tool - Objects centered around a game mechanic such as alchemical apparatus, lockpicks, probes, and repair hammers.
-- soulGem - Empty gems or similar added object capable of holding a soul.
-- creature - Any creature which might have its soul trapped, descriptions should generally be about the creature in question.
-- misc - Clutter, coins, decorative objects, and any other items that don't fall into another category.
-- light - Objects that emit light and may be picked up and/or equipped by the player.
-- book - Books, notes, and any other readable object the player may acquire.
-- clothing - Regular and generic enchanted clothing and jewelry.
-- alchemy - Magical potions that are pre-made or otherwise have unique IDs, beverages like Sujamma do NOT fall under this category.
-- ingredients - Any items that may be used to brew potions or poisons, as well as beverages like Sujamma.
-- scroll - Enchanted scrolls used to cast magical spells.