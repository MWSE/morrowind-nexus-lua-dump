local modInfo = require("mtrStateBasedMagicka.modInfo")
local config = require("mtrStateBasedMagicka.config")

local function createTableVar(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config,
    }
end

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod calculates your Magicka based on your current Intelligence, Willpower, and Level.\n" ..
            "\n" ..
            "Anything that influences your Intelligence or Willpower, such as any Fortify or Drain effects (or Attribute Damage) will affect your Magicka. Any Fortify Magicka effects are taken into account.\n" ..
            "\n" ..
            "Hover over a setting to learn more about it." ..
			"\n" ..
			"\n" ..
			"Thanks to " .. modInfo.credits .. "\n",
    }

    page:createOnOffButton{
        label = "Maintain Magicka difference",
        description =
            "By default, whenever this mod changes your Magicka, it will maintain the ratio of your Current and Max Magicka.\n" ..
            "\n" ..
            "For example, let's say your Magicka is 10/60 (a ratio of 1/6) when you're subject to a Drain Willpower effect that lowers your Max Magicka to 30. The ratio of 1/6 will be maintained, and your new Magicka will be 5/30.\n" ..
            "\n" ..
            "If this setting is enabled, the mod will maintain the difference between your Current and Max Magicka, rather than the ratio.\n" ..
            "\n" ..
            "To use the example above, with a Magicka of 10/60, the difference is 50. When your Max Magicka is lowered to 30 due to the Drain Willpower effect, that difference of 50 will be maintained, and your new Magicka will be -20/30 (in other words, you cannot cast spells).\n" ..
            "\n" ..
            "This setting is beneficial when your Magicka is being increased, but detrimental when your Magicka is being decreased.\n" ..
            "\n" ..
            "Default: Off",
        variable = createTableVar("maintainDifference"),
        defaultSetting = false,
    }

    page:createSlider{
        label = "Minimum Max Magicka",
        description =
            "This setting will prevent the mod from setting your Maximum Magicka below the specified value. It acts as a safety net to prevent a bad Attribute Drain (for example, Ash Woe Blight can Drain both your Intelligence and Willpower to 0) making it impossible to cast spells at all.\n" ..
            "\n" ..
            "This will not prevent you from being unable to cast spells when your Intelligence/Willpower is lowered if you're maintaining difference rather than ratio, and you've spent enough Magicka to be have none left with your new Maximum Magicka.\n" ..
            "\n" ..
            "Default: 0",
        variable = createTableVar("minMaxMagicka"),
        max = 20,
        defaultSetting = 0,
    }
	
	-- Maximum Max Magicka
	
	page:createSlider{
        label = "Maximum Max Magicka",
        description =
            "This setting will set a hard cap on your Maximum Magicka, so the player doesn't grow too powerful.\n" ..
            "\n" ..
            "Default: 10000",
        variable = createTableVar("maxMaxMagicka"),
		min = 1000,
        max = 10000,
        defaultSetting = 10000,
    }
	
	-- Fortify Maximum Magicka affects only Intelligence or Entire Formula
	
	page:createOnOffButton{
        label = "Fortify Maximum Magicka affects entire formula",
        description =
			"By default, whenever this mod changes your Maximum Magicka, Fortify Maximum Magicka effects will affect only part of the formula containing your Intelligence. It will mimic the behaviour of vanilla game where it's only Intelligence that is taken into account while calculating Maximum Magicka and the mod addition of Willpower to Maximum Magicka formula will be taken into consideration only after Fortify Maximum Magicka effect was already accounted for.\n" ..
            "\n" ..
            "For example, let's say your Maximum Magicka is 100, Intelligence is 75, Willpower is 50, Level is 51, and you have no Fortify Maximum Magicka effects; when you put on Mantle of Woe, your new Maximum Magicka will increase to 475.\n" ..
            "\n" ..
			"If this setting is enabled, Fortify Maximum Magicka effects will affect entire Maximum Magicka formula.\n" ..
            "\n" ..
			"To use the example above, with Maximum Magicka of 100 and no Fortify Maximum Magicka effects, when you put on Mantle of Woe, which has Fortify Maximum Magicka effect with magnitude of 5, your new Maximum Magicka will increase to 600.\n" ..
            "\n" ..
			"Enabling this setting will raise your Maximum Magicka potential.\n" ..
            "\n" ..
			"Changing this setting during the game won't have immediate effect, you will have to change your Maximum Magicka by other means for the value to update correctly.\n" ..
			"\n" ..
            "Default: Off",
        variable = createTableVar("affectFormula"),
        defaultSetting = false,
    }
	
	page:createSlider{
        label = "Willpower Magicka Multiplier",
        description =
            "This setting governs the magnitude of the effect your Willpower has on your Maximum Magicka.\n" ..
            "\n" ..
            "With default value of 1 your Maximum Magicka will increase by 0.01 for every 1 Willpower point per Level.\n" ..
            "\n" ..
			"Changing this value during the game won't have immediate effect, you will have to change your Maximum Magicka by other means for the value to update correctly.\n" ..
			"\n" ..
            "Default: 1",
        variable = createTableVar("mtrMagickaMult"),
        max = 10,
        defaultSetting = 1,
    }

    page:createOnOffButton{
        label = "Logging",
        description =
            "This option enables extensive logging to MWSE.log.\n" ..
            "\n" ..
            "Default: Off",
        variable = createTableVar("logging"),
        defaultSetting = false,
    }

    return page
end

local template = mwse.mcm.createTemplate("MTR-StateBasedMagicka")
template:saveOnClose("mtrStateBasedMagicka", config)

createPage(template)

mwse.mcm.register(template)