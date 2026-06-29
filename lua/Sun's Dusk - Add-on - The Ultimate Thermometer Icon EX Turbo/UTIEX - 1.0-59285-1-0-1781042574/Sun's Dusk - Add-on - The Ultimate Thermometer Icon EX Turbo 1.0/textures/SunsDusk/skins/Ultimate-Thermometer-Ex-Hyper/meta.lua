-- ╭────────────────────────────────────────────────────────────────────────╮
-- │  The Ultimate Thermometer Icon EX Turbo - custom temp skin             │
-- ╰────────────────────────────────────────────────────────────────────────╯
-- room past the square for the wetness bar, as a fraction of the icon
local EXTRA = 0.15
local GAP   = 0.04

-- relative geometry, baked once so the layout survives icon resize untouched
local denom        = 1 + EXTRA
local squareRel    = 1 / denom            -- square's share of the long axis
local squareFarRel = EXTRA / denom        -- square offset when pinned to far edge
local thickRel     = (EXTRA - GAP) / denom -- wetness bar thickness
local barFarRel    = (1 + GAP) / denom      -- bar's far-edge start

-- captured element handles and update gates
local plaque, wetBar
local lastFrame, lastWetness, wasPulsing

return {
	need = "temp",
	name = "UTIEX Hyper",
	stages = 120,
	extension = ".png",

	-- protrusion room: extra height in a horizontal hud, extra width in a vertical one
	heightMult  = function(ctx) return ctx.hudOrientation == "Horizontal" and denom or 1 end,
	aspectRatio = function(ctx) return ctx.hudOrientation == "Horizontal" and 1 or denom end,

	-- build once, capture handles
	content = function(ctx)
		local horizontal = ctx.hudOrientation == "Horizontal"
		local frame = math.max(0, math.floor(ctx.normalizedCurrent * ctx.stages - 0.00001))

		-- hue plaque, a square filling the icon end of the shell
		plaque = {
			name = "temp_icon",
			type = ui.TYPE.Image,
			props = {
				resource = getTexture(ctx.base .. "temp_" .. frame .. ctx.extension),
				tileH = false,
				tileV = false,
			},
		}
		if horizontal then
			plaque.props.relativeSize = v2(1, squareRel)
			plaque.props.relativePosition = v2(0, 0)
		elseif ctx.dockedRight then
			plaque.props.relativeSize = v2(squareRel, 1)
			plaque.props.relativePosition = v2(squareFarRel, 0)
		else
			plaque.props.relativeSize = v2(squareRel, 1)
			plaque.props.relativePosition = v2(0, 0)
		end

		-- wetness bar, tucked against the square's outer edge, length is the fill
		wetBar = {
			name = "wetness",
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("white"),
				color = util.color.hex("0a5e8f"),
				tileH = true,
				tileV = false,
				alpha = 0,
			},
		}
		if horizontal then
			-- below the square, fills left to right
			wetBar.props.relativeSize = v2(0, thickRel)
			wetBar.props.relativePosition = v2(0, barFarRel)
			wetBar.props.anchor = v2(0, 0)
		elseif ctx.dockedRight then
			-- left of the square, fills bottom to top
			wetBar.props.relativeSize = v2(thickRel, 0)
			wetBar.props.relativePosition = v2(0, 1)
			wetBar.props.anchor = v2(0, 1)
		else
			-- right of the square, fills bottom to top
			wetBar.props.relativeSize = v2(thickRel, 0)
			wetBar.props.relativePosition = v2(barFarRel, 1)
			wetBar.props.anchor = v2(0, 1)
		end

		-- reset gates so the first update paints from scratch
		lastFrame = frame
		lastWetness = -1
		wasPulsing = false

		return ui.content { plaque, wetBar }
	end,

	-- poke only what changed, report whether anything did
	update = function(ctx)
		local dirty = false
		local horizontal = ctx.hudOrientation == "Horizontal"

		-- frame follows current temp
		local frame = math.max(0, math.floor(ctx.normalizedCurrent * ctx.stages - 0.00001))
		if frame ~= lastFrame then
			lastFrame = frame
			plaque.props.resource = getTexture(ctx.base .. "temp_" .. frame .. ctx.extension)
			dirty = true
		end

		-- wetness bar only shows when wet and enabled
		local show = TEMP_WETNESS_BAR and ctx.wetness > 0
		local targetAlpha = show and 0.8 or 0
		if wetBar.props.alpha ~= targetAlpha then
			wetBar.props.alpha = targetAlpha
			if not show then lastWetness = -1 end
			dirty = true
		end
		if show then
			-- fill length tracks wetness
			if math.abs(ctx.wetness - lastWetness) > 0.01 then
				lastWetness = ctx.wetness
				local fill = math.min(1, ctx.wetness)
				wetBar.props.relativeSize = horizontal and v2(fill, thickRel) or v2(thickRel, fill)
				dirty = true
			end
			-- rain pulses the water, otherwise it sits still and blue
			if ctx.isInRain then
				local intensity = math.max(0.2, math.sin(ctx.time * 2) + 1) / 2
				wetBar.props.color = util.color.rgb(0.055 + 0.745 * intensity, 0.529 + 0.371 * intensity, 0.8 + 0.2 * intensity)
				wasPulsing = true
				dirty = true
			elseif wasPulsing then
				wetBar.props.color = util.color.hex("0a5e8f")
				wasPulsing = false
				dirty = true
			end
		end

		return dirty
	end,
}
