local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')

-- Example:
-- {
-- 	key = "VOLUME",
-- 	name = "Volume (%)",
-- 	description = "Makes stuff loudder and quieter\nValues above 100 only have an effect if the game's effective effect volume is below 100% (total volume times effect volume)",
-- 	renderer = "SuperSlider2",
-- 	default = 90,
-- 	argument = { -- NOTE: maybe argument can't be a reused table
-- 		min = 0, -- default: 0
-- 		max = 300, -- default: 100
-- 		step = 5, -- default: 1
-- 		default = 90, -- default: some features disabled // NOTE: default needs to be defined here too for the default mark and reset button to show up
-- 		showDefaultMark = true,  -- default: false
-- 		showResetButton = false, -- default: false
--		bottomRow = true, -- default: false // NOTE: Puts the textbox and the reset button below the slider (
-- 		minLabel = "Silent", -- default: hidden
-- 		maxLabel = "Loud", -- default: hidden
-- 		centerLabel = "Normal", -- default: hidden
-- 		labelSize = 12, -- default: max(thickness-2, 10)
-- 		width = 150, -- default: 200
-- 		thickness = 14, -- default: 15
-- 		unit = "%", -- default: none
-- 	},
-- },


-- =========================================================
-- =========================================================
SLIDER_RENDERER_ID = "SuperSlider3"

local leftArrow = ui.texture { path = 'textures/omw_menu_scroll_left.dds' }
local rightArrow = ui.texture { path = 'textures/omw_menu_scroll_right.dds' }
local trackTexture = ui.texture { path = 'textures/omw_menu_scroll_center_h.dds' }

local editingState = {}
local activeSlider = nil

-- =========================================================
-- Helper Functions
-- =========================================================

local defaultArgument = {
	disabled = false,
	min = 0,
	max = 100,
	step = 1,
	width = 200,
	thickness = 15,
	showDefaultMark = false,
	showResetButton = false,
	bottomRow = false,
	unit = '',
	minLabel = nil, 
	maxLabel = nil,
	centerLabel = nil,
	labelSize = nil,
}

local function applyDefaults(argument, defaults)
	if not argument then return defaults end
	if pairs(defaults) and pairs(argument) then
		local result = {}
		for k, v in pairs(defaults) do
			result[k] = v
		end
		for k, v in pairs(argument) do
			result[k] = v
		end
		return result
	end
	return argument
end

local function disable(disabled, layout)
	if disabled then
		return {
			template = I.MWUI.templates.disabled,
			content = ui.content {
				layout,
			},
		}
	else
		return layout
	end
end

-- =========================================================
-- Renderer Registration
-- =========================================================

I.Settings.registerRenderer(SLIDER_RENDERER_ID, function(value, set, argument)
	local originalArgument = argument
	argument = applyDefaults(argument, defaultArgument)
	local min = argument.min
	local max = argument.max
	local step = argument.step
	local default = argument.default or min
	local trackWidth = argument.width
	local trackHeight = argument.thickness
	local handleWidth = trackHeight + 2
	local handleHeight = math.max(trackHeight - 4, 4)
	local arrowSize = util.vector2(trackHeight, trackHeight)
	local thicknessScale = trackHeight / 14

	local function valueToPosition(val)
		local range = max - min
		if range == 0 then return 0 end
		return math.floor((val - min) / range * (trackWidth - handleWidth) + 0.5)
	end

	local function positionToValue(pos)
		local normalized = pos / (trackWidth - handleWidth)
		local rawValue = min + (normalized * (max - min))
		local snapped = math.floor(rawValue / step + 0.5) * step
		return util.clamp(snapped, min, max)
	end

	local handlePos = valueToPosition(value)

	local decrementValue = async:callback(function()
		local newValue = util.clamp(value - step, min, max)
		if newValue ~= value then set(newValue) end
	end)

	local incrementValue = async:callback(function()
		local newValue = util.clamp(value + step, min, max)
		if newValue ~= value then set(newValue) end
	end)

	local updateFromMouse = async:callback(function(e)
		activeSlider = { set = set, value = value, step = step, min = min, max = max }
		if e.button ~= 1 then return end
		local pos = util.clamp(e.offset.x - handleWidth / 2, 0, trackWidth - handleWidth)
		local newValue = positionToValue(pos)
		if newValue ~= value then set(newValue) end
	end)

	local lastInput = nil
	local onTextChanged = async:callback(function(text) lastInput = text end)
	local onFocusGain = async:callback(function()
		editingState[originalArgument] = true
		lastInput = nil
		set(value)
	end)
	local onFocusLoss = async:callback(function()
		editingState[originalArgument] = false
		if not lastInput then
			set(value)
			return
		end
		local num = tonumber(lastInput)
		if num then
			local clamped = util.clamp(num, min, max)
			if argument.stepAffectsTextInput then
				clamped = math.floor(clamped / step + 0.5) * step
				clamped = util.clamp(clamped, min, max)
			end
			if clamped ~= value then set(clamped) else set(value) end
		else
			set(value)
		end
	end)

	local displayValue
	if step >= 1 and math.abs(value%1) < 0.01 then
		displayValue = string.format("%d", math.floor(value + 0.5))
	elseif step >= 0.1 then
		displayValue = string.format("%.1f", value)
	elseif step >= 0.01 then
		displayValue = string.format("%.2f", value)
	else
		displayValue = string.format("%.3f", value)
	end
	
	-- Units
	local displayText = editingState[originalArgument] and displayValue or (displayValue .. argument.unit)
	local unitLength = #argument.unit
	
	-- 1000 = +1, 10000 = +2, etc...
	unitLength = unitLength + math.max(0, math.floor(math.log10(max)) - 2)
	if min < 0 then
		unitLength = unitLength + 1
	end
	if step < 0.01 then
		unitLength = unitLength + 1
	end
	
	local trackContent = {}
	if argument.showDefaultMark and default ~= min and math.abs(value - default) > 0.00001 then
		local markPos = valueToPosition(default)
		table.insert(trackContent, {
			type = ui.TYPE.Widget,
			props = {
				position = util.vector2(markPos + handleWidth / 2 - 1, 0),
				size = util.vector2(2, trackHeight),
			},
			content = ui.content {
				{
					type = ui.TYPE.Image,
					props = {
						resource = trackTexture,
						relativeSize = util.vector2(1, 1),
					},
				},
			},
		})
	end

	local handleYOffset = (trackHeight - handleHeight) / 2
	table.insert(trackContent, {
		type = ui.TYPE.Widget,
		props = {
			position = util.vector2(handlePos, handleYOffset),
			size = util.vector2(handleWidth, handleHeight),
		},
		content = ui.content {
			{
				type = ui.TYPE.Image,
				props = {
					resource = trackTexture,
					size = util.vector2(handleWidth, handleHeight),
				},
			},
		},
	})

	-- Top row: arrows + track
	local sliderRow = {
		type = ui.TYPE.Flex,
		props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
		content = ui.content {
			{
				template = I.MWUI.templates.box,
				content = ui.content {
					{
						type = ui.TYPE.Image,
						props = { resource = leftArrow, size = arrowSize },
						events = { mouseClick = decrementValue },
					},
				},
			},
			{
				template = I.MWUI.templates.box,
				content = ui.content {
					{
						type = ui.TYPE.Widget,
						props = { size = util.vector2(trackWidth, trackHeight) },
						content = ui.content(trackContent),
						events = { mouseMove = updateFromMouse, mousePress = updateFromMouse, focusLoss = async:callback(function() activeSlider = nil end) },
					},
				},
			},
			{
				template = I.MWUI.templates.box,
				content = ui.content {
					{
						type = ui.TYPE.Image,
						props = { resource = rightArrow, size = arrowSize },
						events = { mouseClick = incrementValue },
					},
				},
			},
		},
	}
	-- Build reset button if needed
	local resetButton
	if argument.showResetButton and default then
		local l10n = core.l10n('Interface')
		local resetLabel = argument.resetLabel or l10n('Reset')
		local resetToDefault = async:callback(function() set(default) end)
		resetButton = {
			template = I.MWUI.templates.box,
			props = {
				text = resetLabel,
				size = not argument.bottomRow and util.vector2(math.floor(40 * thicknessScale + 0.5), trackHeight) or util.vector2(50, 14),
				autoSize = false,
				textSize = not argument.bottomRow and trackHeight+1 or nil
			},
			content = ui.content {
						{
							template = I.MWUI.templates.textNormal,
							props = {
								text = resetLabel,
								size = not argument.bottomRow and util.vector2(math.floor(40 * thicknessScale + 0.5), trackHeight) or util.vector2(50, 18),
								autoSize = false,
								textSize = not argument.bottomRow and trackHeight+1 or 18,
								textAlignH = ui.ALIGNMENT.Center,
							},
						},
			},
			events = { mouseClick = resetToDefault },
		}
	end

	-- Place text input + reset button either inline or in a second row
	local bottomRow
	if argument.bottomRow then
		local bottomContent = {}
		if resetButton then
			table.insert(bottomContent, resetButton)
			table.insert(bottomContent, { template = I.MWUI.templates.interval })
		end
		table.insert(bottomContent, {
			template = I.MWUI.templates.box,
			content = ui.content {
				{
					template = I.MWUI.templates.textEditLine,
					props = {
						size = util.vector2(50+unitLength*5, 18),
						text = displayText,
						textSize = 18,
						textAlignH = ui.ALIGNMENT.Center,
						autoSize = false,
					},
					events = { textChanged = onTextChanged, focusGain = onFocusGain, focusLoss = onFocusLoss },
				},
			},
		})
		bottomRow = {
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				autoSize = false,
				align = ui.ALIGNMENT.End,
				arrange = ui.ALIGNMENT.End,
				size = util.vector2(trackWidth, 23),
			},
			external = { stretch = 1 },
			content = ui.content(bottomContent),
		}
	else
		table.insert(sliderRow.content, {
			template = I.MWUI.templates.box,
			content = ui.content {
				{
					template = I.MWUI.templates.textEditLine,
					props = {
						size = util.vector2(math.floor((37 + unitLength * 4) * thicknessScale + 0.5), trackHeight),
						textSize = trackHeight+1,
						text = displayText,
						textAlignH = ui.ALIGNMENT.Center,
						autoSize = false,
					},
					events = { textChanged = onTextChanged, focusGain = onFocusGain, focusLoss = onFocusLoss },
				},
			},
		})
		if resetButton then
			table.insert(sliderRow.content, resetButton)
		end
	end

	-- Combine into vertical layout
	local rows = {}

	if argument.minLabel or argument.maxLabel or argument.centerLabel then
		local sliderWidth = arrowSize.x + 4 + trackWidth + 4 + arrowSize.x + 4
		local labelSize = argument.labelSize or math.max(trackHeight - 2, 10)
		local labelContent = {
			{
				template = I.MWUI.templates.textNormal,
				props = { text = argument.minLabel or '', textSize = labelSize },
			},
			{ external = { grow = 1 } },
		}
		if argument.centerLabel then
			table.insert(labelContent, {
				template = I.MWUI.templates.textNormal,
				props = { text = argument.centerLabel, textSize = labelSize + 2 },
			})
			table.insert(labelContent, { external = { grow = 1 } })
		end
		table.insert(labelContent, {
			template = I.MWUI.templates.textNormal,
			props = { text = argument.maxLabel or '', textSize = labelSize },
		})
		table.insert(rows, {
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				size = util.vector2(sliderWidth, labelSize + 2),
			},
			content = ui.content(labelContent),
		})
	end

	table.insert(rows, sliderRow)
	if bottomRow then
		table.insert(rows, bottomRow)
	end

	return disable(argument.disabled, {
		type = ui.TYPE.Flex,
		props = { horizontal = false },
		content = ui.content(rows),
	})
end)

-- =========================================================
-- Mousewheel Support
-- =========================================================

local mouseWheelBonusFunction = false
if not input.triggers["MenuMouseWheelUp"] then
	input.registerTrigger({
		key = "MenuMouseWheelUp",
		l10n = "none",
		name = "MenuMouseWheelUp",
		description = "",
	})
	input.registerTrigger({
		key = "MenuMouseWheelDown",
		l10n = "none",
		name = "MenuMouseWheelDown",
		description = "",
	})
	mouseWheelBonusFunction = true
end

local function scrollActiveSlider(direction)
	if not activeSlider then return end
	local s = activeSlider
	local newValue = util.clamp(s.value + direction * s.step, s.min, s.max)
	if newValue ~= s.value then s.set(newValue) end
end

local function onMouseWheel(direction)
	if mouseWheelBonusFunction then
		if direction > 0 then
			input.activateTrigger("MenuMouseWheelUp")
		else
			input.activateTrigger("MenuMouseWheelDown")
		end
	end
	scrollActiveSlider(direction)
end

-- =========================================================
-- Engine Handlers
-- =========================================================

return {
	engineHandlers = {
		onMouseWheel = onMouseWheel,
	},
}