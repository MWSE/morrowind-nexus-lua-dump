local ui          = require("openmw.ui")
local util        = require("openmw.util")
local Options     = require("scripts.MD_HitAndMissIndicators.lib.options")

local Indicators  = {
	active = {}
}
Indicators.create = function(text, offsetRange, options)
	if options.ENABLED then
		local offset_x = (math.random() * offsetRange.x) - (offsetRange.x / 2.0)
		local offset_y = (math.random() * offsetRange.y) - (offsetRange.y / 2.0)
		local element = ui.create({
			layer = "HUD",
			type = ui.TYPE.Text,
			props = {
				text = text,
				textColor = util.color.rgba(
					options.COLOR.r,
					options.COLOR.g,
					options.COLOR.b,
					1.0
				),
				textSize = options.TEXT_SIZE,
				relativePosition = util.vector2(0.5 + offset_x, 0.5 + offset_y),
				anchor = util.vector2(0.5, 0.5),
				visible = true,
			},
		})
		table.insert(Indicators.active, {
			element = element,
			timer = options.DURATION,
			duration = options.DURATION,
			speed = options.FLOAT_SPEED
		})
	end
end

Indicators.update = function(dt)
	local removeIndices = {}
	for index, indicator in ipairs(Indicators.active) do
		if indicator.timer <= 0.0 then
			indicator.element:destroy()
			table.insert(removeIndices, index)
		else
			local currentTextColor = indicator.element.layout.props.textColor
			local currentRelativePosition = indicator.element.layout.props.relativePosition

			indicator.element.layout.props.textColor = util.color.rgba(
				currentTextColor.r,
				currentTextColor.g,
				currentTextColor.b,
				math.min(1.0, math.max(0.0, indicator.timer / indicator.duration))
			)
			indicator.element.layout.props.relativePosition = util.vector2(
				currentRelativePosition.x,
				currentRelativePosition.y - indicator.speed * dt
			)
			indicator.timer = indicator.timer - dt
			indicator.element:update()
		end
	end

	local index = #removeIndices
	while index > 0 do
		table.remove(Indicators.active, removeIndices[index])
		index = index - 1
	end
end

return {
	engineHandlers = {
		onUpdate = Indicators.update
	},
	eventHandlers = {
		MD_OnAttackMiss = function(data)
			Indicators.create(
				string.format("Miss (%0.0f%%)", data.chanceToHit),
				Options.OFFSET_RANGE,
				Options.missIndicator()
			)
		end,

		MD_OnAttackHit = function(data)
			Indicators.create(
				string.format("%0.0f", data.damage),
				Options.OFFSET_RANGE,
				Options.hitIndicator()
			)
		end,

		MD_OnPunchHit = function(data)
			Indicators.create(
				string.format("%0.0f", data.damage),
				Options.OFFSET_RANGE,
				Options.punchIndicator()
			)
		end
	}
}
