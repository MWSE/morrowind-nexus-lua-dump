local unit = {}

local defaultConfig = {
---modEnabled = true,
minCameraDist = 96, -- e.g. 72 -- 32 .. 256
zoomInWheelSteps = 2, -- 1 .. 5
zoomOutWheelSteps = 4, -- 1 .. 8
zoomStartRate = 2, -- 1 .. 4
zoomEndRate = 0.7, -- 0.25 .. 2
zoomInAmount = 2.2, -- 1 .. 4
zoomOutAmount = 0.055, --0.0625
---mouse3rdsensitivity = 2, -- 1 .. 4
logLevel = 0,
}
local author = 'abot'
local modName = 'SWGTK'
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

	local info = [[Change Player Point Of View/Zoom by scrolling mouse wheel.

(State)>>[Action] sequences:
(3rd person view)>>[scroll up]>>(1st person view)>>[scroll up]>>(zoom in)

(zoomed in)>>[scroll down]>>(zoomed out)>>[scroll down]>>(3rd person view)
]]

	-- Preferences Page
	local preferences = template:createSideBarPage(
		{label = 'Squeaky Wheel Gets The Kick!', showHeader = true,
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

	local optionList = {'Off', 'Low', 'Medium', 'High'}
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

	---local yesOrNo = {[false] = 'No', [true] = 'Yes'}
	---local function getYesNoDescription(frmt, variableId)
		---return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	---end

	---controls:createYesNoButton({
		---label = 'Enabled',
		---description = getYesNoDescription([[Default: %s.
---Toggle mod functionality.
---effective only on game reload.]], 'modEnabled'),
		---variable = createConfigVariable('modEnabled')
	---})

	controls:createSlider({
		label = 'Camera switch distance: %s',
		description = getDescription([[Default: %s game units.
3rd Person Camera distance from player head to trigger going from 3rd to 1st person view.
You may need to tweak this according to your MGE XE settings,
in any case I suggest some MGE-XE settings so 3rd Person camera is horizontally (X axis) centered over player head.
e.g. I'm using these MGE-XE 3rd Person Camera settings:
Customize 3rd Person Camera=True
Initial 3rd Person Camera X=0.00
Initial 3rd Person Camera Y=-209
Initial 3rd Person Camera Z=16.00]], 'minCameraDist'),
		variable = createConfigVariable('minCameraDist'),
		min = 32, max = 512, step = 1, jump = 4
	})


	controls:createSlider({
		label = 'Wheel steps to trigger zoom in: %s',
		description = getDescription([[Default: %s.
Mouse wheel scroll up/forward steps to trigger zoom in when zoomed out in 1st person view.
A value lower than "Wheel steps to trigger zoom out" is suggested.
You may need to tweak this according to your mouse settings/sensitivity.]], 'zoomInWheelSteps'),
		variable = createConfigVariable('zoomInWheelSteps'),
		min = 1, max = 5, step = 1, jump = 1
	})

	controls:createSlider({
		label = 'Wheel steps to trigger zoom out/3rd person view: %s',
		description = getDescription([[Default: %s.
Mouse wheel scroll down/backward steps to trigger zoom out/3rd person view when zoomed in/in 1st person view.
A value higher than "Wheel steps to trigger zoom in" is suggested.
You may need to tweak this according to your mouse settings/sensitivity.]], 'zoomOutWheelSteps'),
		variable = createConfigVariable('zoomOutWheelSteps'),
		min = 1, max = 8, step = 1, jump = 1
	})

    controls:createSlider({
		label = 'Zoom in start rate: %s',
		description = getDescription([[Default: %.02f.
Zoom in starting rate.
Affects starting speed of zoom-in when zoomed out/1st person view.
A value higher than "Zoom in end rate" is suggested.]], 'zoomStartRate'),
		variable = createConfigVariable('zoomStartRate'),
		decimalPlaces = 2, min = 1, max = 4, step = 0.25, jump = 0.5
	})

	controls:createSlider({
		label = 'Zoom in end rate: %s',
		description = getDescription([[Default: %.02f.
Zoom in ending rate.
Affects ending speed of zoom-in when zoomed out/in 1st person view.
A value lower than "Zoom in start rate" is suggested.c]], 'zoomEndRate'),
		variable = createConfigVariable('zoomEndRate'),
		decimalPlaces = 2, min = 0.25, max = 3, step = 0.25, jump = 0.5
	})

controls:createSlider({
		label = 'Zoom in amount: %s',
		description = getDescription([[Default: %.03f.
Zoom in amount.
Affects zoom-in intensity when zoomed out/3rd person view.]], 'zoomInAmount'),
		variable = createConfigVariable('zoomInAmount'),
		decimalPlaces = 3, min = 1, max = 4, step = 0.01, jump = 0.05
	})

	controls:createSlider({
		label = 'Zoom out amount: %s',
		description = getDescription([[Default: %.03f.
Zoom out amount.
Affects (constant) speed of zoom-out when zoomed in/1st person view.]], 'zoomOutAmount'),
		variable = createConfigVariable('zoomOutAmount'),
		decimalPlaces = 3, min = 0.03, max = 0.12, step = 0.001, jump = 0.003
	})

	--- controls:createSlider({
		--- label = '3rd person view mouse sensitivity: %s',
		--- description = getDescription([[Default: %.02f.
--- Mouse sensitivity in 3rd person view.]], 'mouse3rdsensitivity'),
		--- variable = createConfigVariable('mouse3rdsensitivity'),
		--- decimalPlaces = 2, min = 1, max = 4, step = 0.05, jump = 0.1
	--- })

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