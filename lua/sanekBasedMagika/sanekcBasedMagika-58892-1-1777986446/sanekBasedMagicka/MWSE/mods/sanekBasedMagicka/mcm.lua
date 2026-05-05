local modInfo = require("sanekBasedMagicka.modInfo")
local config = require("sanekBasedMagicka.config")

local templateRef
local minSlider
local maxSlider
local willSlider
local multSlider
local powSlider
local levelSlider

local function createTableVar(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local function getMultiplierScaling(magickaBonus)
    if config.softScale then
        return 1 + config.multMod * (magickaBonus ^ config.powExp)
    else
        return 1 + config.multMod * magickaBonus
    end
end

local function calcVanillaMagicka(intelligence, magickaBonus)
    return math.floor(intelligence * (1 + magickaBonus) + 0.5)
end

local function calcCurrentMagicka(intelligence, willpower, level, magickaBonus)
    local multiplierScaling

    if config.softScale then
        multiplierScaling = 1 + config.multMod * (magickaBonus ^ config.powExp)
    else
        multiplierScaling = 1 + config.multMod * magickaBonus
    end

    local result =
        (intelligence + config.willpowerMod * willpower)
        * multiplierScaling
        * (1 + config.levelMod * level)

    result = math.max(result, config.minMaxMagicka)
    result = math.min(result, config.maxMaxMagicka)

    return math.floor(result + 0.5)
end

local function buildExamplesText()
        
    local INT = 100
    local WILL = 100
    local LEVEL = 25

    local altmerBonus = 3.5 -- Altmer + Atronach
    local dunmerBonus = 1.5 -- Dark Elf + Apprentice

    local altVanilla = calcVanillaMagicka(INT, altmerBonus)
    local dunVanilla = calcVanillaMagicka(INT, dunmerBonus)

    local altCurrent = calcCurrentMagicka(INT, WILL, LEVEL, altmerBonus)
    local dunCurrent = calcCurrentMagicka(INT, WILL, LEVEL, dunmerBonus)
	
	local modeText = config.softScale and
    string.format("Mode: Pow scaling", config.powExp) or
    "Mode: Linear scaling"

    return string.format(
        
		"Current examples (INT 100 / WILL 100 / Level 25)\n" ..
        "\n" ..
        "Altmer + Atronach\n" ..
        "Vanilla: %d MP\n" ..
        "Current: %d MP\n" ..
        "\n" ..
        "Dark Elf + Apprentice\n" ..
        "Vanilla: %d MP\n" ..
        "Current: %d MP\n" ..
        "\n" ..
        "Ratio: %.2fx"..
		"\n" ..
		"\n" ..
		"%s\n",
        altVanilla,
        altCurrent,
        dunVanilla,
        dunCurrent,
        altCurrent / dunCurrent,
		modeText
    )
end

local function buildWillDescription()
    return
        "Controls how much Willpower contributes to the base part of the formula.\n" ..
        "\n" ..
        "At 0.5, each point of Willpower counts as half a point of Intelligence.\n" ..
        "\n" ..
        buildExamplesText() ..
        "\n" ..
        "\n" ..
        "Default: 0.5"
end

local function buildMultDescription()
    return
        "Controls how strongly race, birthsign, and Fortify Maximum Magicka bonuses affect the formula.\n" ..
        "\n" ..
        "Lower = less total magicka.\n" ..
        "Higher = more total magicka.\n" ..
        "\n" ..
        buildExamplesText() ..
        "\n" ..
        "\n" ..
        "Default: 0.75"
end

local function buildPowDescription()
    return
        "Controls how strongly large magicka bonuses are compressed.\n" ..
        "\n" ..
        "Lower = smaller gap between moderate and extreme magicka builds.\n" ..
        "Higher = closer to linear scaling.\n" ..
        "\n" ..
        buildExamplesText() ..
        "\n" ..
        "\n" ..
        "Default: 0.75"
end

local function buildLevelDescription()
    return
        "Controls how strongly Level scales the final result of the formula.\n" ..
        "\n" ..
        "At 0.015, each level adds a 1.5 percent multiplier to Maximum Magicka.\n" ..
        "\n" ..
        buildExamplesText() ..
        "\n" ..
        "\n" ..
        "Default: 0.015"
end

local function buildSoftScaleDescription()
    return  
	    "Switches between exponent-based and linear scaling for race, birthsign, and Fortify Maximum Magicka bonuses.\n" ..
        "\n" ..
        "On = Pow scaling. Extreme magicka multipliers are compressed.\n" ..
        "Off = Linear scaling. Bonuses scale directly like in Vanilla\n" ..
        "\n" ..
        buildExamplesText() ..
        "\n" ..
        "\n" ..
        "Default: On"
end		

local function getMouseOverInfo()
    local page = templateRef and templateRef.currentPage
    if page and page.elements and page.elements.mouseOver then
        return page.elements.mouseOver
    end
    return nil
end

local function refreshDynamicDescriptions(activeSetting)

    if willSlider then
        willSlider.description = buildWillDescription()
    end

    if multSlider then
        multSlider.description = buildMultDescription()
    end

    if powSlider then
        powSlider.description = buildPowDescription()
    end

    if levelSlider then
        levelSlider.description = buildLevelDescription()
    end
	
	if softScaleButton then
	    softScaleButton.description = buildSoftScaleDescription()
    end
	
    local mouseOverInfo = getMouseOverInfo()
    if mouseOverInfo and activeSetting then
        mouseOverInfo:updateInfo(activeSetting)
    end
end

local function createPage(template)
    templateRef = template

    local page = template:createSideBarPage{
        label = "sanekBasedMagicka",
        description =
		    modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod calculates your Magicka based on your current Intelligence, Willpower, and Level.\n" ..
            "\n" ..
            "By default the formula is:\n" ..
            "base * multiplier scaling * level scaling\n" ..
            "\n" ..
            "base = INT + willMod * WILL\n" ..
            "multiplier scaling = 1 + multMod * (Fortify Maximum Magicka ^ powExp)\n" ..
            "level scaling = 1 + lvlMod * level\n" ..
            "\n" ..
            "Hover over a setting to see live examples.\n" ..
			"\n" ..
			"\n" ..
			"Thanks to " .. modInfo.credits .. "\n",
    }


    softScaleButton = page:createOnOffButton{
        label = "Mode",
        description = buildSoftScaleDescription(),
        variable = createTableVar("softScale"),
        defaultSetting = true,
        callback = function(self)
        refreshDynamicDescriptions(self)
    end,

    }

    

    willSlider = page:createSlider{
        label = "Willpower",
        description = buildWillDescription(),
        variable = createTableVar("willpowerMod"),
        max = 1.0,
        min = 0.0,
        step = 0.1,
        jump = 0.1,
        decimalPlaces = 1,
        defaultSetting = 0.5,
        callback = function(self)
            refreshDynamicDescriptions(self)
        end,
    }

    multSlider = page:createSlider{
        label = "Multiplier",
        description = buildMultDescription(),
        variable = createTableVar("multMod"),
        max = 1.0,
        min = 0.1,
        step = 0.01,
        jump = 0.1,
        decimalPlaces = 2,
        defaultSetting = 0.75,
        callback = function(self)
            refreshDynamicDescriptions(self)
        end,
    }

    powSlider = page:createSlider{
        label = "PowExp",
        description = buildPowDescription(),
        variable = createTableVar("powExp"),
        max = 1.0,
        min = 0.1,
        step = 0.01,
        jump = 0.1,
        decimalPlaces = 2,
        defaultSetting = 0.75,
        callback = function(self)
            refreshDynamicDescriptions(self)
        end,
    }

    levelSlider = page:createSlider{
        label = "Level",
        description = buildLevelDescription(),
        variable = createTableVar("levelMod"),
        max = 0.10,
        min = 0.00,
        step = 0.001,
        jump = 0.01,
        decimalPlaces = 3,
        defaultSetting = 0.015,
        callback = function(self)
            refreshDynamicDescriptions(self)
        end,
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
	
	minSlider = page:createSlider{
        label = "Minimum Max Magicka",
        description = "This setting will prevent the mod from setting your Maximum Magicka below the specified value. It acts as a safety net to prevent a bad Attribute Drain (for example, Ash Woe Blight can Drain both your Intelligence and Willpower to 0) making it impossible to cast spells at all.\n" ..
            "\n" ..
            "This will not prevent you from being unable to cast spells when your Intelligence/Willpower is lowered if you're maintaining difference rather than ratio, and you've spent enough Magicka to be have none left with your new Maximum Magicka.\n" ..
            "\n" ..
            "Default: 0",
        variable = createTableVar("minMaxMagicka"),
        max = 20,
        defaultSetting = 0,
        
    }

    maxSlider = page:createSlider{
        label = "Maximum Max Magicka",
        description = "This setting will set a hard cap on your Maximum Magicka, so the player doesn't grow too powerful.\n" ..
            "\n" ..
            "Default: 10000",
        variable = createTableVar("maxMaxMagicka"),
        min = 1000,
        max = 10000,
        defaultSetting = 10000,
        
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

    refreshDynamicDescriptions()

    return page
end

local template = mwse.mcm.createTemplate("sanekBasedMagicka")
template:saveOnClose("sanekBasedMagicka", config)

createPage(template)

mwse.mcm.register(template)