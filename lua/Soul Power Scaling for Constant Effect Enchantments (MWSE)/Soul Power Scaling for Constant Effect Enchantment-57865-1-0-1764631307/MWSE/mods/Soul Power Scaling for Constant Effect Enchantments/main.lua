local config = mwse.loadConfig("Soul Power Scaling for Constant Effect Enchantments") or {
}

local function registerModConfig()
	local template = mwse.mcm.createTemplate("Soul Power Scaling for Constant Effect Enchantments")
	template:saveOnClose("Soul Power Scaling for Constant Effect Enchantments", config)
	template:register()
	
	local page = template:createSideBarPage{label="Preferences"}

	page.sidebar:createInfo{
		text = "Soul Power Scaling for Constant Effect Enchantments \n\nThis mod makes the magnitude of constant effects enchantments scale with the power of the soul used, making which soul you use a lot more impactful."
	}
	
	page:createOnOffButton{
        label = "Enable Mod",
		description = "Turn the mod's effects on or off. \n\nDefault: On",
        variable = mwse.mcm.createTableVariable{
			id = "enableMod",
			table = config
		},
		defaultSetting = true,
		showDefaultConfig = true
	}
	
	page:createSlider{
		label = "Scaling Dividencd",
		description = "The magnitude of each effect is multiplied by the soul's value divided by this number. \n\nAny souls stronger than the number set here provide a more powerful enchantment than they normally would. Any souls with less power will provide a weaker enchantment. \n\nDefault: 400",
		min = 100,
        max = 500,
        step = 10,
        jump = 50,
		variable = mwse.mcm.createTableVariable{
			id = "scalingDividend",
			table = config
		},
	    defaultSetting = 400,
	    showDefaultConfig = true
	}
end
event.register("modConfigReady", registerModConfig)



mwse.log("Soul Power Scaling for Constant Effect Enchantments has been initialized.")



local function onEnchantmentCreation(e)
	if (config.enableMod == true and e.object.enchantment.castType == 3) then
		effects = e.object.enchantment.effects
		soul = e.soul.soul
		for i=1, #effects do
			effects[i].min = effects[i].min * (soul / config.scalingDividend)
			effects[i].max = effects[i].max * (soul / config.scalingDividend)
		end
	end
end
event.register(tes3.event.enchantedItemCreated, onEnchantmentCreation)