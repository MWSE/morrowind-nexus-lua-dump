local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')

-- =========================================================
-- =========================================================
SLIDER_RENDERER_ID = "SuperSlider2"

local leftArrow = ui.texture { path = 'textures/omw_menu_scroll_left.dds' }
local rightArrow = ui.texture { path = 'textures/omw_menu_scroll_right.dds' }
local trackTexture = ui.texture { path = 'textures/omw_menu_scroll_center_h.dds' }

-- =========================================================
-- Helper Functions
-- =========================================================

local defaultArgument = {
	disabled = false,
	min = 0,
	max = 100,
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
	argument = applyDefaults(argument, defaultArgument)
	local min = argument.min
	local max = argument.max
	local step = argument.step
	local default = argument.default or min
	local trackWidth = argument.width or 200
	local trackHeight = 14
	local handleWidth = 16
	local handleHeight = 10
	local arrowSize = util.vector2(14, 14)

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
		if e.button ~= 1 then return end
		local pos = util.clamp(e.offset.x - handleWidth / 2, 0, trackWidth - handleWidth)
		local newValue = positionToValue(pos)
		if newValue ~= value then set(newValue) end
	end)

	local lastInput = nil
	local onTextChanged = async:callback(function(text) lastInput = text end)
	local onFocusLoss = async:callback(function()
		if not lastInput then return end
		local num = tonumber(lastInput)
		if num then
			local clamped = util.clamp(num, min, max)
			if argument.stepAffectsTextInput then
				clamped = math.floor(clamped / step + 0.5) * step
				clamped = util.clamp(clamped, min, max)
			end
			if clamped ~= value then set(clamped) end
		else
			set(value)
		end
	end)

	local displayValue
	if step >= 1 then
		displayValue = string.format("%d", math.floor(value + 0.5))
	elseif step >= 0.1 then
		displayValue = string.format("%.1f", value)
	else
		displayValue = string.format("%.2f", value)
	end

	local trackContent = {}

	if argument.showDefaultMark and default ~= min then
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
						events = { mouseMove = updateFromMouse, mousePress = updateFromMouse },
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
	if not argument.showResetButton or not default then
		table.insert(sliderRow.content, {
			template = I.MWUI.templates.box,
			content = ui.content {
				{
					template = I.MWUI.templates.textEditLine,
					props = {
						size = util.vector2(50, trackHeight),
						textSize = trackHeight+1,
						text = displayValue,
						textAlignH = ui.ALIGNMENT.Center,
						autoSize = false,
					},
					events = { textChanged = onTextChanged, focusLoss = onFocusLoss },
				},
			},
		})
	end
	-- Bottom row: reset button (left) + number input (right)
	local bottomContent = {}
	local bottomRow
	if argument.showResetButton and default then
		local l10n = core.l10n('Interface')
		local resetLabel = argument.resetLabel or l10n('Reset')
		local resetToDefault = async:callback(function() set(default) end)
		table.insert(bottomContent, {
			template = I.MWUI.templates.box,
			content = ui.content {
				{
					template = I.MWUI.templates.padding,
					content = ui.content {
						{
							template = I.MWUI.templates.textNormal,
							props = { 
								text = resetLabel,
								size = util.vector2(50, 16),
								autoSize = false,
							},
						},
					},
				},
			},
			events = { mouseClick = resetToDefault },
		})
		table.insert(bottomContent, { template = I.MWUI.templates.interval })

		table.insert(bottomContent, {
			template = I.MWUI.templates.box,
			content = ui.content {
				{
					template = I.MWUI.templates.textEditLine,
					props = {
						size = util.vector2(50, 20),
						text = displayValue,
						textAlignH = ui.ALIGNMENT.Center,
						autoSize = false,
					},
					events = { textChanged = onTextChanged, focusLoss = onFocusLoss },
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
				size = util.vector2(trackWidth, 25),
			},
			external = { stretch = 1 },
			content = ui.content(bottomContent),
		}
	end

	-- Combine into vertical layout
	local rows = {}

	if argument.minLabel or argument.maxLabel then
		local sliderWidth = arrowSize.x + 4 + trackWidth + 4 + arrowSize.x + 4
		table.insert(rows, {
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				size = util.vector2(sliderWidth, 16),
			},
			content = ui.content {
				{
					template = I.MWUI.templates.textNormal,
					props = { text = argument.minLabel or '', textSize = 14 },
				},
				{ external = { grow = 1 } },
				{
					template = I.MWUI.templates.textNormal,
					props = { text = argument.maxLabel or '', textSize = 14 },
				},
			},
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
-- Engine Handlers
-- =========================================================

return {
	engineHandlers = {},
}