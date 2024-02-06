
local common = require("Virnetch.ShrineTooltips.common")


--- Returns the default value for a setting
--- @param id string The setting to get the value for, subtables within the config file can be separated with dots.
--- @param valueMult number Optional. A multiplier for the value stored in the config file.
--- @return string defaultValue The default value of the setting. Booleans are converted to sOn/sOff.
local function getDefaultSetting(id, valueMult)
	local defaultValue = common.defaultConfig
	local keys = string.split(id, "%.")
	for _, key in ipairs(keys) do
		defaultValue = defaultValue[key]
	end

	if defaultValue == true then
		defaultValue = tes3.findGMST(tes3.gmst.sOn).value
	elseif defaultValue == false then
		defaultValue = tes3.findGMST(tes3.gmst.sOff).value
	elseif valueMult and tonumber(defaultValue) then
		defaultValue = valueMult * tonumber(defaultValue)
	end

	return tostring(defaultValue)
end

--- Returns a string of commonly used information for a mcm setting, including its default value and if the setting requires the game to be restarted
--- @param id string The setting to get the value for, subtables within the config file can be separated with dots.
--- @param restartRequired? boolean Optional. True if the setting requires the game to be restarted.
--- @param valueMult? number Optional. A multiplier for the value stored in the config file.
--- @return string
local function descriptionDefaults(id, restartRequired, valueMult)
	local defaultSetting = getDefaultSetting(id, valueMult)

	local description = "\n\n"..common.i18n("mcm.default", { defaultSetting = defaultSetting })
	if restartRequired then
		description = description.."\n"..common.i18n("mcm.restartRequired")
	end

	return description
end



local template = mwse.mcm.createTemplate(common.mod.name)
template:saveOnClose("ShrineTooltips", common.config)

local pageGeneral = template:createSideBarPage{
	label = common.i18n("mcm.page.general.label"),
	-- description = common.i18n("mcm.page.general.description")
}

-- Add the default sidebar description
do
	-- Mod name, version and link
	local header = pageGeneral.sidebar:createCategory(common.i18n("mcm.mainDescription.header", { version = common.mod.version }))
	header:createHyperlink{
		text = common.i18n("mcm.link.ShrineTooltips.link"),
		url = common.i18n("mcm.link.ShrineTooltips.link"),
	}

	-- Main description
	header:createInfo{ text = common.i18n("mcm.mainDescription.description") }
end


-- General Settings
do

	local generalCategory = pageGeneral:createCategory(common.i18n("mcm.category.general"))
	generalCategory:createOnOffButton{	-- modEnabled
		label = common.i18n("mcm.general.modEnabled.label"),
		description = common.i18n("mcm.general.modEnabled.description")
			.. descriptionDefaults("modEnabled", true),
		restartRequired = true,
		variable = mwse.mcm.createTableVariable{
			id = "modEnabled",
			table = common.config
		}
	}

	generalCategory:createOnOffButton{	-- detailedTooltip
		label = common.i18n("mcm.general.detailedTooltip.label"),
		description = common.i18n("mcm.general.detailedTooltip.description")
			.. descriptionDefaults("detailedTooltip"),
		variable = mwse.mcm.createTableVariable{
			id = "detailedTooltip",
			table = common.config
		}
	}

	local miscCategory = pageGeneral:createCategory(common.i18n("mcm.category.misc"))
	miscCategory:createDropdown{		-- logLevel
		label = "Logging Level",
		description = "Set the log level."
			.. descriptionDefaults("logLevel"),
		options = {
			{ label = "TRACE", value = "TRACE"},
			{ label = "DEBUG", value = "DEBUG"},
			{ label = "INFO", value = "INFO"},
			{ label = "ERROR", value = "ERROR"},
			{ label = "NONE", value = "NONE"},
		},
		variable = mwse.mcm.createTableVariable{
			id = "logLevel",
			table = common.config
		},
		callback = function(self)
			common.log:setLogLevel(self.variable.value)
		end
	}
end

mwse.mcm.register(template)