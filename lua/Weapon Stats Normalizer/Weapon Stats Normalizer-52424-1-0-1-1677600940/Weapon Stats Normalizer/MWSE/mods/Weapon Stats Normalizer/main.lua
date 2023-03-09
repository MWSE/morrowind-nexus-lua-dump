local default_config = {
    use_max = true
}

local config = mwse.loadConfig(config_name, default_config)
local EasyMCM = require("easyMCM.EasyMCM")


local function iterate_weapons()

    for weapon in tes3.iterateObjects(tes3.objectType.weapon) do
        if config.use_max then
            if weapon.slashMax > weapon.chopMax then
                if weapon.slashMax > weapon.thrustMax then
                    weapon.chopMin = weapon.slashMin
                    weapon.chopMax = weapon.slashMax
                    weapon.thrustMin = weapon.slashMin
                    weapon.thrustMax = weapon.slashMax
                else
                    weapon.slashMin = weapon.thrustMin
                    weapon.slashMax = weapon.thrustMax
                    weapon.chopMin = weapon.thrustMin
                    weapon.chopMax = weapon.thrustMax
                end
            else
                if weapon.chopMax > weapon.thrustMax then
                    weapon.slashMin = weapon.chopMin
                    weapon.slashMax = weapon.chopMax
                    weapon.thrustMin = weapon.chopMin
                    weapon.thrustMax = weapon.chopMax
                else
                    weapon.slashMin = weapon.thrustMin
                    weapon.slashMax = weapon.thrustMax
                    weapon.chopMin = weapon.thrustMin
                    weapon.chopMax = weapon.thrustMax
                end
            end 
        else
            if weapon.slashMin + weapon.slashMax > weapon.chopMin + weapon.chopMax then
                if weapon.slashMin + weapon.slashMax > weapon.thrustMin + weapon.thrustMax then
                    weapon.chopMin = weapon.slashMin
                    weapon.chopMax = weapon.slashMax
                    weapon.thrustMin = weapon.slashMin
                    weapon.thrustMax = weapon.slashMax
                else
                    weapon.slashMin = weapon.thrustMin
                    weapon.slashMax = weapon.thrustMax
                    weapon.chopMin = weapon.thrustMin
                    weapon.chopMax = weapon.thrustMax
                end
            else
                if weapon.chopMin + weapon.chopMax > weapon.thrustMin + weapon.thrustMax then
                    weapon.slashMin = weapon.chopMin
                    weapon.slashMax = weapon.chopMax
                    weapon.thrustMin = weapon.chopMin
                    weapon.thrustMax = weapon.chopMax
                else
                    weapon.slashMin = weapon.thrustMin
                    weapon.slashMax = weapon.thrustMax
                    weapon.chopMin = weapon.thrustMin
                    weapon.chopMax = weapon.thrustMax
                end
            end
        end
    end
end

event.register("initialized", iterate_weapons)

-- MCM --

local resetConfig = false

local function modConfigReady()

	local template = mwse.mcm.createTemplate("Weapon Stats Normalizer")

	template.onClose = function()
		if resetConfig then
			resetConfig = false
			config = default_config
		end
		mwse.saveConfig(config_name, config, {indent = false})
	end

	local main_page = template:createSideBarPage({
    label = "Settings",
    description = [[
    Weapon Stats Normalizer - Settings.
    ]]
  })

  local category_main_settings = main_page:createCategory("Main")

  category_main_settings:createOnOffButton{
    label = "Use Max Values",
    description = [[
        Use max values for the weapon damage values, instead of averages.
        
        Default: On
      ]],
    variable = mwse.mcm.createTableVariable{ id = "use_max", table = config }
  }

  mwse.mcm.register(template)
end

event.register('modConfigReady', modConfigReady)