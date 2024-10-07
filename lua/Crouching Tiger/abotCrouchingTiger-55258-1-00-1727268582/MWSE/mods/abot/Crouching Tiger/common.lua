local unit = {}

local defaultConfig = {
---modEnabled = true,
jumpDelay = 0.42, -- delay between sneak and jump 0.2 .. 0.6 sec

-- temporary percentual acrobatics buff for jumping from sneaking (0 = no buff) 0 .. 50%
acrobaticsBuffPerc = 30,
logLevel = 0,
}

local author = 'abot'
local modName = 'Crouching Tiger'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

local function notYetImplemented(funcName)
	mwse.log('%s: %s not yet implemented', modPrefix, funcName)
end

-- to be overriden
function unit.mcmOnClose()
  notYetImplemented('mcmOnClose()')
end
function unit.updateFromConfig()
  notYetImplemented('updateFromConfig()')
end

local function saveConfig()
	mwse.saveConfig(configName, config, {indent = true})
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId, table = config}
end

local function modConfigReady()
	local template = mwse.mcm.createTemplate(mcmName)

	local info = [[Allow to jump from crouching position (giving player a temporary Acrobatics buff in the process).]]

	local preferences = template:createSideBarPage(
		{label = '',--- showHeader = true,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.1
			self.elements.sideToSideBlock.children[2].widthProportional = 0.9
		end
	})
	local sidebar = preferences.sidebar
	sidebar:createInfo({text = info})
	local controls = preferences:createCategory({})

	template.onClose = unit.mcmOnClose

	local optionList = {'Off', 'Low'} ---, 'Medium', 'High'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end

	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s. %s', i, optionList[i+1]))
	end

	controls:createSlider({
		label = 'Jump animation delay: %s',
		description = getDescription([[Default: %.02f sec.
Delay between starting of "out-of sneak" and "jump" animations.]], 'jumpDelay'),
		variable = createConfigVariable('jumpDelay'),
		decimalPlaces = 2, min = 0.1, max = 1, step = 0.01, jump = 0.05
	})

	controls:createSlider({
		label = 'Acrobatics Buff Perc: %s%%',
		description = getDescription([[Default: %s%%
Temporary percentual player Acrobatics buff for jumping from crouching (0.0 = no buff).]], 'acrobaticsBuffPerc'),
		variable = createConfigVariable('acrobaticsBuffPerc'),
		decimalPlaces = 1, min = 0.0, max = 100, step = 0.1, jump = 0.5
	})

	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	mwse.mcm.register(template)

end

-- public
unit.author = author
unit.modName = modName
unit.modPrefix = modPrefix
unit.configName = configName
unit.mcmName = mcmName
unit.defaultConfig = defaultConfig
unit.config = config
unit.saveConfig = saveConfig
unit.modConfigReady = modConfigReady

return unit