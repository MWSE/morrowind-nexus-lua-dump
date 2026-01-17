--[[
- sets Take window default quantity to half the total amount
- sets the scrollbar jump to a sensible value
- adds buttons to increment/decrement by 1 or 5, halve, double, max the quantity
]]

local defaultConfig = {
minWidth = 360, -- min. window width, you can tweak the integernumber according to font size/resolution/language
halveQty = true, -- set it = false to skip halving quantity by default
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium, 3 = High
}

local author = 'abot'
local modName = 'Smart Take'
---local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = configName:gsub(' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

local minWidth, halveQty
local logLevel, logLevel1

local function updateFromConfig()
	minWidth = config.minWidth
	halveQty = config.halveQty
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
end
updateFromConfig()

---@param el tes3uiElement
---@param value integer
local function setSliderValue(el, value)
	el:setPropertyInt('PartScrollBar_current', value - 1)
	el:triggerEvent('PartScrollBar_changed')
end

---@param uiSlider tes3uiSlider
---@param addValue integer
local function addToSlider(uiSlider, addValue)
	local current = uiSlider.current + 1
	local new = current + addValue
	new = math.min(new, uiSlider.max + 1)
	new = math.max(new, 1)
	setSliderValue(uiSlider.element, new)
end

---@param uiSlider tes3uiSlider
local function setSliderHalf(uiSlider)
	local current = uiSlider.current + 1
	local half = math.floor(current * 0.5 + 0.5)
	half = math.max(half, 1)
	setSliderValue(uiSlider.element, half)
end

---@param uiSlider tes3uiSlider
local function setSliderMax(uiSlider)
	setSliderValue(uiSlider.element, uiSlider.max + 1)
end

---@param uiSlider tes3uiSlider
local function setSliderDouble(uiSlider)
	local current = uiSlider.current + 1
	local double = current * 2
	double = math.min(double, uiSlider.max + 1)
	setSliderValue(uiSlider.element, double)
end

--- @param e uiActivatedEventData
local function uiActivatedMenuQuantity(e)
	local menu = e.element
	local scrollbar = menu:findChild('MenuQuantity_scrollbar')
	if not scrollbar then
		return
	end
	local uiSlider = scrollbar.widget ---@type tes3uiSlider
	if not uiSlider then
		return
	end
	if e.newlyCreated then
		menu.minWidth = minWidth
		local mx = uiSlider.max + 1
		local jump = math.floor(mx * 0.05 + 0.5)
		jump = math.max(jump, uiSlider.step * 2)
		uiSlider.jump = math.min(jump, uiSlider.max)
		local menuMenuQuantity_title = menu:findChild('MenuQuantity_title')
		if not menuMenuQuantity_title then
			return
		end
		menuMenuQuantity_title.borderTop = 1
		local parent = menuMenuQuantity_title.parent

		local buttonMinus1 = parent:createButton({id = 'ab01MQminus1Btn', text = '-1'})
		buttonMinus1.borderAllSides = 0
		buttonMinus1:reorder({after = menuMenuQuantity_title})

		local buttonPlus1 = parent:createButton({id = 'ab01MQplus1Btn', text = '+1'})
		buttonPlus1.borderAllSides = 0
		buttonPlus1:reorder({after = buttonMinus1})

		local buttonMinus5 = parent:createButton({id = 'ab01MQminus5Btn', text = '-5'})
		buttonMinus5.borderAllSides = 0
		buttonMinus5:reorder({after = buttonPlus1})

		local buttonPlus5 = parent:createButton({id = 'ab01MQplus5Btn', text = '+5'})
		buttonPlus5.borderAllSides = 0
		buttonPlus5:reorder({after = buttonMinus5})

		local buttonHalf = parent:createButton({id = 'ab01MQhalfBtn', text = '/2'})
		buttonHalf.borderAllSides = 0
		buttonHalf:reorder({after = buttonPlus5})

		local buttonDouble = parent:createButton({id = 'ab01MQdoubleBtn', text = '*2'})
		buttonDouble.borderAllSides = 0
		buttonDouble:reorder({after = buttonHalf})

		local buttonAll = parent:createButton({id = 'ab01MQAllBtn', text = 'All'})
		buttonAll.borderAllSides = 0
		buttonAll:reorder({after = buttonDouble})

		buttonMinus1:register('mouseClick', function () addToSlider(uiSlider, -1) end)
		buttonPlus1:register('mouseClick', function () addToSlider(uiSlider, 1) end)
		buttonMinus5:register('mouseClick', function () addToSlider(uiSlider, -5) end)
		buttonPlus5:register('mouseClick', function () addToSlider(uiSlider, 5) end)
		buttonHalf:register('mouseClick', function () setSliderHalf(uiSlider) end)
		buttonDouble:register('mouseClick', function () setSliderDouble(uiSlider) end)
		buttonAll:register('mouseClick', function () setSliderMax(uiSlider) end)
	end
	if halveQty then
		setSliderHalf(uiSlider)
	end
end
event.register('uiActivated', uiActivatedMenuQuantity, {filter = 'MenuQuantity', priority = -100})


local function onClose()
	updateFromConfig()
	mwse.saveConfig(configName, config, {indent = false})
end

local function modConfigReady()

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local sideBarPage = template:createSideBarPage({
		label = modName,
		showReset = true,
		description = [[- sets Take window default quantity to half the total amount
- sets the scrollbar jump to a sensible value
- adds buttons to increment/decrement by 1 or 5, halve, double, max the quantity.]],
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	local optionList = {'Off', 'Low', 'Medium', 'High', 'Higher', 'Max'}

	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = ('%s. %s'):format(i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	sideBarPage:createYesNoButton({
		label = 'Halve Quantity',
		description = [[Toggle for setting the initial quantity slider to half by default.]],
		configKey = 'halveQty'
	})

	sideBarPage:createSlider({
		label = 'Min window width',
		description = [[Minimal window width. You can tweak it according to fomt size/screen resolution.]],
		configKey = 'minWidth',
		min = 290, max = 480, step = 1, jump = 4
	})

	sideBarPage:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		configKey = 'logLevel'
	})

	mwse.mcm.register(template)

end
event.register('modConfigReady', modConfigReady)