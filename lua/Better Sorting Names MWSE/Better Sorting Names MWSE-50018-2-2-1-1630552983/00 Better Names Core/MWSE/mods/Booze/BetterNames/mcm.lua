local this = {}
local config = require("Booze.BetterNames.config")
local confTable = config:get()

-- MCM Code by Merlord

local sideBarDefault =
[[
Welcome to Better Sorting Names v2.1.

Use the configuration menu to select which items get renamed, and decide if you want to cheat a little as well. Note that you need to restart the game whenever you change the settings for them to apply.

Hover over individual settings to see more information.
]]

if not confTable then

    confTable = {

	DoArmorNames = true,
	DoClothingNames = true,
	DoPotionNamesEffect = true,
	DoPotionNamesPotion = false,
	DoPotionIcons = true,
	DoSoulgemNames = true,
	DoToolNames = true,
	DoWeaponNames = true,
	DoHighQualityTools = true,
	DoTrainingBookNames = false,
	showDebug = false
    }

    config.save(confTable)
end

local function registerConfig()

    local template = mwse.mcm.createtemplate{ name = "Better Sorting Names" }
    template:saveOnClose( config.path, confTable )
    template:register()

    local settingsPage = template:createSideBarPage("Settings")

    settingsPage.sidebar:createInfo{ text = sideBarDefault}

    settingsPage:createOnOffButton{
        label = "Rename Armors?",
        description = "Armor sets are grouped together (as per normal) but Left/Right items will sort better, i.e. Steel Left Pauldron > Steel Pauldron Left.",
        variable = mwse.mcm.createTableVariable{ id = "DoArmorNames", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Rename Clothing?",
        description = "This is especially useful with Korana's Clothiers, where all dresses will sort together, but also useful for standard clothing, i.e. Common Pants > Pants Common.",
        variable = mwse.mcm.createTableVariable{ id = "DoClothingNames", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Rename Potions by Effect?",
        description = "Potions of the same effect will sort together and by quality, from cheapest to most expensive, i.e. Exclusive Potion of Fortify Luck > Fortify Luck Select.",
        variable = mwse.mcm.createTableVariable{ id = "DoPotionNamesEffect", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Rename Potions with Potion...?",
        description = "Potion names all start with 'Potion' and then the effect name, and finally the quality. So potions of the same effect will sort together and by quality, but also, all potions will sort together since they all start with Potion, i.e. Exclusive Potion of Fortify Luck > Potion Fortify Luck Select.",
        variable = mwse.mcm.createTableVariable{ id = "DoPotionNamesPotion", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Add effect badges to Potions' iventory icons?",
        description = "Adds an effect badge on top of the potion image in the inventory; works only on potions defined in Morrowind/Trib/BM ESM's.",
        variable = mwse.mcm.createTableVariable{ id = "DoPotionIcons", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Rename SoulGems?",
        description = "All soulgems will sort together and by quality, i.e. Soulgem IV Greater.",
        variable = mwse.mcm.createTableVariable{ id = "DoSoulgemNames", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Rename Tools?",
        description = "Lockpicks, Probes, Repair and Alchemist's tools will sort by quality.",
        variable = mwse.mcm.createTableVariable{ id = "DoToolNames", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Rename Weapons?",
        description = "Weapons will sort by kind (i.e. Sword Long Iron) and ammo will sort together (i.e. Arrow of Cruel Viper).",
        variable = mwse.mcm.createTableVariable{ id = "DoWeaponNames", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Cheat: Rename training books?",
        description = "Identify training books easily, Skill Numbers are: 0=Block, 1=Armorer, 2=Medium Armor, 3=Heavy Armor, 4=Blunt Weapon, 5=Long Blade, 6=Axes, 7=Spear, 8=Athletics, 9=Enchanting, 10=Destruction, 11=Alteration, 12=Illusion, 13=Conjuration, 14=Mysticism, 15=Restoration, 16=Alchemy, 17=UnArmored, 18=Security, 19=Sneak, 20=Acrobatics, 21=Light Armor, 22=Short Blade, 23=Marksman, 24=Mercantile, 25=SpeechCraft, 26=Hand-To-Hand.",
        variable = mwse.mcm.createTableVariable{ id = "DoTrainingBookNames", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Cheat: Higher quality Tools have more uses?",
        description = "Better tools should last longer than cheaper ones...",
        variable = mwse.mcm.createTableVariable{ id = "DoHighQualityTools", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Enable verbose logging in MWSE.log?",
        description = "Will show missing items in the logfile.",
        variable = mwse.mcm.createTableVariable{ id = "showDebug", table = confTable }
    }

end

event.register("modConfigReady", registerConfig)

return this
