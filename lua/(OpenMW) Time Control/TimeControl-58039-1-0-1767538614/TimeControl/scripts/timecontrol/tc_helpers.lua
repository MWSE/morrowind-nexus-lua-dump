-- ────────────────────────────────────────────────────────────  Texture cache ──────────────────────────────────────────────────────────────────────
textureCache = {}							   
function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end

-- ╭──────────────────────────╮
-- │  Color helpers           │
-- ╰──────────────────────────╯

function getColorFromGameSettings(gmst)
	local result = core.getGMST(gmst)
	if not result then
		return util.color.rgb(1,1,1)
	end
	local rgb = {}
	for color in string.gmatch(result, '(%d+)') do
		table.insert(rgb, tonumber(color))
	end
	if #rgb ~= 3 then
		return util.color.rgb(1, 1, 1)
	end
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

function rgbToHsv(r, g, b, a)
	if type(r) == "table" or type(r) == "userdata" then
		g = r.g or r[2]
		b = r.b or r[3]
		a = r.a or r[4]
		r = r.r or r[1]
	end
	local maxc, minc = math.max(r, g, b), math.min(r, g, b)
	local h, s, v
	v = maxc

	local d = maxc - minc
	if maxc == 0 then s = 0 else s = d / maxc end

	if maxc == minc then
		h = 0
	else
		if maxc == r then
			h = (g - b) / d
			if g < b then h = h + 6 end
		elseif maxc == g then h = (b - r) / d + 2
		elseif maxc == b then h = (r - g) / d + 4
		end
		h = h / 6
	end
	return h, s, v, a
end

function hsvToRgb(h, s, v, a)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	i = i % 6
	local r, g, b
	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	else               r, g, b = v, p, q
	end
	return r, g, b, a
end

function darkenColor(color, mult)
	return util.color.rgb(math.min(1,color.r * mult), math.min(1,color.g * mult), math.min(1,color.b * mult))
end

function getHudLayerSize()
	local layerId = ui.layers.indexOf("Modal")
	return ui.layers[layerId].size
end
