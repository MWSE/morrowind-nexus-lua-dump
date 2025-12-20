--[[
- sets Take window default quantity to half the total amount
- sets the scrollbar jump to a sensible value
- adds buttons to increment/decrement by 1 or 5, halve, double, max the quantity
]]

-- local author = 'abot'
-- local modName = 'Smart Take'
-- local modPrefix = author .. '/' .. modName


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
	setSliderHalf(uiSlider)
end
event.register('uiActivated', uiActivatedMenuQuantity, {filter = 'MenuQuantity', priority = -100})
