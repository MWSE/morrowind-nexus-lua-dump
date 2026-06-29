-- ╭────────────────────────────────────────────────────────────────────────╮
-- │  Classic Thermometer - custom temp skin                                │
-- ╰────────────────────────────────────────────────────────────────────────╯

-- fixed icon scale (1 = fills the square)
local SEVERITY_SCALE = 1

-- captured handles, borrowed art bits, and update gates
local bgEl, ghostEl, mainEl, arrowEl, wetEl
local artBase, artExt, artStages
local lastFrame, lastGhost, lastAlpha, lastWetness, wasPulsing

-- arrow asset, scale and tint from the temperature trend (nil in the dead zone)
local function arrowForDiff(diff)
	if diff > 17 then return "rising2", 1, util.color.rgb(0.8, 0.5, 0.1)
	elseif diff > 7 then return "rising1", 1, util.color.rgb(0.6, 0.5, 0.1)
	elseif diff > 0 then return "rising1", diff / 7, util.color.rgb(0.5, 0.5, 0)
	elseif diff < -17 then return "falling2", 1, util.color.rgb(0.5, 0.5, 1)
	elseif diff < -7 then return "falling1", 1, util.color.rgb(0.5, 0.5, 0.8)
	elseif diff < 0 then return "falling1", (-diff) / 7, util.color.rgb(0.3, 0.3, 0.5)
	end
	return nil
end

return {
	need = "temp",
	name = "Thermometer",
	stages = 120,
	extension = ".png",

	-- comfort-fade: hide when the setting is on and nothing buffs or wets
	alpha = function(ctx)
		if TEMP_HIDE_NO_BUFF and TEMP_BUFFS_DEBUFFS == "Buffs and debuffs" and not ctx.tempBuff and not ctx.wetnessDebuff then
			return 0
		end
		return 1
	end,

	-- build once, capture handles
	content = function(ctx)
		-- own frames and arrow assets, shipped in this skin folder
		artBase = ctx.base
		artExt = ctx.extension
		artStages = ctx.stages

		-- cooler frame solid, warmer frame a faint ghost behind it
		local lower = math.min(ctx.normalizedCurrent, ctx.normalizedTarget)
		local higher = math.max(ctx.normalizedCurrent, ctx.normalizedTarget)
		local frame = math.max(0, math.floor(lower * artStages - 0.00001))
		local ghost = math.max(0, math.floor(higher * artStages - 0.00001))
		local frameTex = getTexture(artBase .. "temp_" .. frame .. artExt)
		local ghostTex = getTexture(artBase .. "temp_" .. ghost .. artExt)

		-- static placement; severityScale is 1 so the icon fills the square
		local iconPos = v2(1 - SEVERITY_SCALE, (1 - SEVERITY_SCALE) / 2)
		local iconSize = v2(SEVERITY_SCALE, SEVERITY_SCALE)
		local a = ctx.alpha

		-- drop shadow, the current frame tinted black and nudged down-right
		bgEl = {
			name = "temp_background",
			type = ui.TYPE.Image,
			props = {
				resource = frameTex,
				color = util.color.rgb(0, 0, 0),
				tileH = false,
				tileV = false,
				relativeSize = iconSize,
				relativePosition = iconPos + v2(0.04, 0.027),
				alpha = a > 0 and 0.5 or 0,
			},
		}
		-- ghost of the further frame
		ghostEl = {
			name = "target_icon",
			type = ui.TYPE.Image,
			props = {
				resource = ghostTex,
				color = TEMP_COLOR,
				tileH = false,
				tileV = false,
				relativeSize = iconSize,
				relativePosition = iconPos,
				alpha = a * 0.2,
			},
		}
		-- solid current frame
		mainEl = {
			name = "temp_icon",
			type = ui.TYPE.Image,
			props = {
				resource = frameTex,
				color = TEMP_COLOR,
				tileH = false,
				tileV = false,
				relativeSize = iconSize,
				relativePosition = iconPos,
				alpha = a,
			},
		}
		-- direction arrow, hidden until update fills it in
		arrowEl = {
			name = "temp_arrow",
			type = ui.TYPE.Image,
			props = {
				resource = getTexture(artBase .. "rising1" .. artExt),
				tileH = false,
				tileV = false,
				relativeSize = v2(0.4, 0.4),
				relativePosition = v2(0.4, 0.5),
				anchor = v2(1, 0.5),
				alpha = 0,
			},
		}
		-- vertical wetness bar, lower-right, grows from the bottom
		wetEl = {
			name = "wetness",
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("white"),
				color = util.color.hex("0a5e8f"),
				relativeSize = v2(0.15, ctx.wetness * 0.82),
				relativePosition = v2(0.8, 0.91),
				anchor = v2(0, 1),
				tileH = true,
				tileV = false,
				alpha = (TEMP_WETNESS_BAR and a > 0) and 0.8 or 0,
			},
		}

		-- reset gates so the first update paints from scratch
		lastFrame = frame
		lastGhost = ghost
		lastAlpha = a
		lastWetness = ctx.wetness
		wasPulsing = false

		return ui.content { bgEl, ghostEl, mainEl, arrowEl, wetEl }
	end,

	-- poke only what changed, report whether anything did
	update = function(ctx)
		local dirty = false
		local a = ctx.alpha

		-- frames track the cooler/warmer of current and target
		local lower = math.min(ctx.normalizedCurrent, ctx.normalizedTarget)
		local higher = math.max(ctx.normalizedCurrent, ctx.normalizedTarget)
		local frame = math.max(0, math.floor(lower * artStages - 0.00001))
		local ghost = math.max(0, math.floor(higher * artStages - 0.00001))
		if frame ~= lastFrame then
			lastFrame = frame
			local tex = getTexture(artBase .. "temp_" .. frame .. artExt)
			mainEl.props.resource = tex
			bgEl.props.resource = tex
			dirty = true
		end
		if ghost ~= lastGhost then
			lastGhost = ghost
			ghostEl.props.resource = getTexture(artBase .. "temp_" .. ghost .. artExt)
			dirty = true
		end

		-- comfort-fade flips every layer's alpha at once
		if a ~= lastAlpha then
			lastAlpha = a
			bgEl.props.alpha = a > 0 and 0.5 or 0
			ghostEl.props.alpha = a * 0.2
			mainEl.props.alpha = a
			wetEl.props.alpha = (TEMP_WETNESS_BAR and a > 0) and 0.8 or 0
			dirty = true
		end

		-- arrow follows the trend, scaling up with the gap
		local name, scale, color = arrowForDiff(ctx.diff)
		if name then
			arrowEl.props.resource = getTexture(artBase .. name .. artExt)
			arrowEl.props.color = color
			arrowEl.props.relativeSize = v2(0.4 * scale, 0.4 * scale)
			arrowEl.props.alpha = a
			dirty = true
		elseif arrowEl.props.alpha ~= 0 then
			arrowEl.props.alpha = 0
			dirty = true
		end

		-- wetness bar height tracks wetness, water pulses in rain
		if TEMP_WETNESS_BAR then
			if math.abs(ctx.wetness - lastWetness) > 0.01 then
				lastWetness = ctx.wetness
				wetEl.props.relativeSize = v2(0.15, ctx.wetness * 0.82)
				dirty = true
			end
			if ctx.isInRain then
				local intensity = math.max(0.2, math.sin(ctx.time * 2) + 1) / 2
				wetEl.props.color = util.color.rgb(0.055 + 0.745 * intensity, 0.529 + 0.371 * intensity, 0.8 + 0.2 * intensity)
				wasPulsing = true
				dirty = true
			elseif wasPulsing then
				wetEl.props.color = util.color.hex("0a5e8f")
				wasPulsing = false
				dirty = true
			end
		end

		return dirty
	end,
}
