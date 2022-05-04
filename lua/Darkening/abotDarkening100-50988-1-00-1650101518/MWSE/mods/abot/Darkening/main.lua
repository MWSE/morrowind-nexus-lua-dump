--[[
Simple Interiors Darkening /abot
on the fly darkening of any interior cell without per-cell customization/color storage

color conversion stolen from amazing Weather Adjuster mod by Hrnchamd
https://www.nexusmods.com/morrowind/mods/46816
]]

-- begin configurable parameters
local defaultConfig = {
darkening = true,
lightnessPerc = 45,
fixInteriorFogDensity = true,
mergeColors = 0, -- 0 = disabled, 1 = move/merge original sun color to ambient, 2 = move/merge original ambient color to sun
logLevel = 0,
}
-- end configurable parameters

local author = 'abot'
local modName = 'Darkening'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)


--begin color conversion stolen from weatheradjust mod by hrnchamd

-- Colour space conversions for picker. sRGB to CIE LCh perceptual.

local function sRGBToLCh(sRGB)
	-- sRGB with domain [0, 1] to linear RGB.
	local linRGB = {}
	for i = 1, 3 do
		if (sRGB[i] > 0.04045) then
			linRGB[i] = math.pow((sRGB[i] + 0.055) / 1.055, 2.4)
		else
			linRGB[i] = sRGB[i] / 12.91
		end
	end

	-- To XYZ with [0, 1] domain. Relative to D65/2deg.
	local xyz = {
		0.4123866 * linRGB[1] + 0.3575915 * linRGB[2] + 0.1804505 * linRGB[3],
		0.2126368 * linRGB[1] + 0.7151830 * linRGB[2] + 0.0721802 * linRGB[3],
		0.0193306 * linRGB[1] + 0.1191972 * linRGB[2] + 0.9503726 * linRGB[3]
	}

	-- To L*ab D65.
	xyz = { xyz[1] / 0.95047, xyz[2], xyz[3] / 1.08883 }
	for i = 1, 3 do
		if (xyz[i] > 0.008856) then
			xyz[i] = math.pow(xyz[i], 1/3)
		else
			xyz[i] = 7.787*xyz[i] + 16/116
		end
	end

	local Lab = {
		116 * xyz[2] - 16,
		500 * (xyz[1] - xyz[2]),
		200 * (xyz[2] - xyz[3])
	}

	-- To LCh.
	local h = math.atan2(Lab[3], Lab[2])
	if (h < 0) then
		h = h + 2*math.pi
	end

	local LCh = { Lab[1], math.sqrt(Lab[2]*Lab[2] + Lab[3]*Lab[3]), math.deg(h) }
	---print(string.format("XYZ %.5f %.5f %.5f", xyz[1], xyz[2], xyz[3]))
	---print(string.format("Lab %.5f %.5f %.5f", Lab[1], Lab[2], Lab[3]))
	---print(string.format("LCh %.5f %.5f %.5f", LCh[1], LCh[2], LCh[3]))
	return LCh
end

-- Colour space conversions for picker. CIE LCh perceptual to unclamped sRGB.
local function LChTosRGB(LCh)
	-- LCh to L*ab D65.
	local Lab = {
		LCh[1],
		LCh[2] * math.cos(math.rad(LCh[3])),
		LCh[2] * math.sin(math.rad(LCh[3]))
	}

	-- To XYZ with domain [0, 1]. Relative to D65/2deg.
	local xyz_pre = {}
	xyz_pre[2] = (Lab[1] + 16) / 116
	xyz_pre[1] = Lab[2] / 500 + xyz_pre[2]
	xyz_pre[3] = xyz_pre[2] - Lab[3] / 200

	local xyz = { math.pow(xyz_pre[1], 3), math.pow(xyz_pre[2], 3), math.pow(xyz_pre[3], 3) }
	for i = 1, 3 do
		if (xyz[i] <= 0.008856) then
			xyz[i] = (xyz_pre[i] - 16/116) / 7.787
		end
	end
	xyz = { xyz[1] * 0.95047, xyz[2], xyz[3] * 1.08883 }

	-- To sRGB with domain [0, 1]. Does not clamp.
	local rgb = {
		3.2410032 * xyz[1] + -1.5373990 * xyz[2] + -0.4986159 * xyz[3],
		-0.9692242 * xyz[1] + 1.8759300 * xyz[2] + 0.0415542 * xyz[3],
		0.0556394 * xyz[1] + -0.2040112 * xyz[2] + 1.0571490 * xyz[3]
	}

	for i = 1, 3 do
		if (rgb[i] > 0.0031307) then
			rgb[i] = 1.055 * math.pow(rgb[i], 1/2.4) - 0.055
		else
			rgb[i] = 12.92 * rgb[i]
		end
	end

	---print(string.format("Lab %.5f %.5f %.5f", Lab[1], Lab[2], Lab[3]))
	---print(string.format("XYZ %.5f %.5f %.5f", xyz[1], xyz[2], xyz[3]))
	---print(string.format("sRGB %.5f %.5f %.5f", rgb[1], rgb[2], rgb[3]))
	return rgb
end

-- Colour space conversions for picker. CIE LCh to in-gamut sRGB, using chroma reduction to move colours into gamut.
local function LChTosRGBContainChroma(LCh)
	local LCh_adj = { LCh[1], LCh[2], LCh[3] }
	local validChroma = 0
	local upperChroma = LCh[2]
	local sRGB = LChTosRGB(LCh_adj)

	-- Binary search for chroma that produces an in-gamut sRGB result.
	for _ = 1,16 do
		-- Check result is within sRGB, with a little leeway for rounding error.
		local withinGamut = true
		for i = 1, 3 do
			if (sRGB[i] < -0.5/255 or sRGB[i] > 255.5/255) then
				withinGamut = false
				break
			end
		end

		-- Terminate on acceptable convergence.
		if (math.abs(LCh_adj[2] - validChroma) < 0.1) then
			break
		end

		-- Calculate new LCh and sRGB.
		if (withinGamut) then
			validChroma = LCh_adj[2]
		else
			upperChroma = LCh_adj[2]
		end
		LCh_adj[2] = 0.5 * (validChroma + upperChroma)
		sRGB = LChTosRGB(LCh_adj)
	end

	-- Clamp sRGB.
	for i = 1, 3 do
		sRGB[i] = math.max(0, math.min(1, sRGB[i]))
	end
	return sRGB
end

--end color conversion stolen from weatheradjust mod by hrnchamd



local function rgb_to_sRGB(rgb)
	return {[1] = rgb.r / 255, [2] = rgb.g / 255, [3] = rgb.b / 255}
end

local function sRGB_to_rgb(sRGB)
	return {
		r = math.min(  math.floor( (sRGB[1] * 255) + 0.5 ), 255  ),
		g = math.min(  math.floor( (sRGB[2] * 255) + 0.5 ), 255  ),
		b = math.min(  math.floor( (sRGB[3] * 255) + 0.5 ), 255  )
	}
end

local function rgbDarken(rgb, luminanceMul)
	local sRGB = rgb_to_sRGB(rgb)
	local LCh = sRGBToLCh(sRGB)
	LCh[1] = LCh[1] * luminanceMul
	sRGB = LChTosRGBContainChroma(LCh)
	return sRGB_to_rgb(sRGB)
end

local function getLuma(rgb)
	local sRGB = rgb_to_sRGB(rgb)
	local LCh = sRGBToLCh(sRGB)
	sRGB = LChTosRGBContainChroma(LCh)
	LCh = sRGBToLCh(sRGB)
	return LCh[1]
end

local cells = {}

local function cellChanged(e)
	local cell = e.cell
	if cell.isOrBehavesAsExterior then
		return
	end

	if cell.fogDensity < 0.02 then
		if config.fixInteriorFogDensity then
			cell.fogDensity = 0.02
			if config.logLevel > 0 then
				mwse.log('%s: cell "%s" fog density fixed', modPrefix, cell.id)
			end
		elseif config.logLevel > 0 then
			mwse.log('%s: WARNING: cell "%s" fog density < 0.02', modPrefix, cell.id)
		end
	end

	if not config.darkening then
		return
	end
	if cells[cell.id] then
		return
	end
	cells[cell.id] = true

	if config.logLevel > 0 then
		mwse.log('%s: cell "%s" ambient before {r = %s, g = %s, b = %s}', modPrefix, cell.id, cell.ambientColor.r, cell.ambientColor.g, cell.ambientColor.b)
		mwse.log('%s: cell "%s" sun before {r = %s, g = %s, b = %s}', modPrefix, cell.id, cell.sunColor.r, cell.sunColor.g, cell.sunColor.b)
		mwse.log('%s: cell "%s" fog before {r = %s, g = %s, b = %s}', modPrefix, cell.id, cell.fogColor.r, cell.fogColor.g, cell.fogColor.b)
	end

	if config.lightnessPerc < 100 then
		local luminanceMul = config.lightnessPerc / 100.0

		local darkened = rgbDarken(cell.ambientColor, luminanceMul)
		cell.ambientColor.r = darkened.r
		cell.ambientColor.g = darkened.g
		cell.ambientColor.b = darkened.b

		darkened = rgbDarken(cell.sunColor, luminanceMul)
		cell.sunColor.r = darkened.r
		cell.sunColor.g = darkened.g
		cell.sunColor.b = darkened.b

		darkened = rgbDarken(cell.fogColor, luminanceMul)
		cell.fogColor.r = darkened.r
		cell.fogColor.g = darkened.g
		cell.fogColor.b = darkened.b
	end

	if config.mergeColors > 0 then
		local mergeSun = config.mergeColors == 1

		local lumaBefore = (getLuma(cell.sunColor) + getLuma(cell.ambientColor)) / 2
		local c, delta

		if mergeSun then
			c = cell.sunColor.r
			delta = 255 - cell.ambientColor.r
		else
			c = cell.ambientColor.r
			delta = 255 - cell.sunColor.r
		end
		if delta > c then
			delta = c
		end
		if mergeSun then
			cell.sunColor.r = c - delta + 1
			cell.ambientColor.r = cell.ambientColor.r + delta - 1
		else
			cell.ambientColor.r = c - delta + 1
			cell.sunColor.r = cell.sunColor.r + delta - 1
		end

		if mergeSun then
			c = cell.sunColor.g
			delta = 255 - cell.ambientColor.g
		else
			c = cell.ambientColor.g
			delta = 255 - cell.sunColor.g
		end
		if delta > c then
			delta = c
		end
		if mergeSun then
			cell.sunColor.g = c - delta + 1
			cell.ambientColor.g = cell.ambientColor.g + delta - 1
		else
			cell.ambientColor.g = c - delta + 1
			cell.sunColor.g = cell.sunColor.g + delta - 1
		end

		if mergeSun then
			c = cell.sunColor.b
			delta = 255 - cell.ambientColor.b
		else
			c = cell.ambientColor.b
			delta = 255 - cell.sunColor.b
		end
		if delta > c then
			delta = c
		end
		if mergeSun then
			cell.sunColor.b = c - delta + 1
			cell.ambientColor.b = cell.ambientColor.b + delta - 1
		else
			cell.ambientColor.b = c - delta + 1
			cell.sunColor.b = cell.sunColor.b + delta - 1
		end

		local lumaAfter = (getLuma(cell.sunColor) + getLuma(cell.ambientColor)) / 2

		if config.logLevel > 0 then
			local colorType = {[false] = 'ambient', [true] = 'sun'}
			mwse.log('%s cell "%s" %s color packing: Luma before %s, after %s}', modPrefix, cell.id, colorType[mergeSun], lumaBefore, lumaAfter)
		end

	end

	if config.logLevel > 0 then
		mwse.log('%s: cell "%s" ambient after {r = %s, g = %s, b = %s}', modPrefix, cell.id, cell.ambientColor.r, cell.ambientColor.g, cell.ambientColor.b)
		mwse.log('%s: cell "%s" sun after {r = %s, g = %s, b = %s}', modPrefix, cell.id, cell.sunColor.r, cell.sunColor.g, cell.sunColor.b)
		mwse.log('%s: cell "%s" fog after {r = %s, g = %s, b = %s}', modPrefix, cell.id, cell.fogColor.r, cell.fogColor.g, cell.fogColor.b)
	end
end
event.register('cellChanged', cellChanged)

--[[ nope as it keeps changed cell values on loaded
local function clearCells()
	for k, _ in pairs(cells) do
		cells[k] = nil
	end
	cells = {}
end
event.register('loaded', clearCells)
]]

--[[local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end]]

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end


local function modConfigReady()
	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		mwse.saveConfig(configName, config, {indent = false})
		--[[if not (darken == config.darken) then
			darken = config.darken
			setLumaVec()
		end]]
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label="Preferences",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo{text = [[Simple interior cells lightness tweaker.]]}

	local controls = preferences:createCategory{label = ""}

	controls:createYesNoButton{
		label = "Enable darkening",
		description = [[Enables changes to interior lightness. Default: Yes.
Note that this mod is meant to work well with mods increasing lights radius,
but will conflict with other mods changing cell stored ambient/sun/fog values.]],
		variable = createConfigVariable("darkening")
	}

	controls:createSlider{
		label = "Interior lightness (%%) %s",
		variable = createConfigVariable("lightnessPerc")
		,min = 1, max = 100,
		description = string.format("Interior lightness (%%) (default: %s).\n100 means no change from initial cell lightness value."
			,defaultConfig.lightnessPerc)
	}

	controls:createYesNoButton{
		label = "Fix interior fog density ",
		description = [[Default: yes.
Automatically fix interior fog density if needed. Some video cards need fog density > 0 to work correctly,
else they can display a black screen in near 0 fog density cells.
There are tools to fix this directly in the bugged mod (tes3cmd scripts) or generating a mod patch for the whole loading list (e.g. tes3cmd multipatch),
but this option can fix the fog density on the fly if needed when loading the cell in game.]],
		variable = createConfigVariable("fixInteriorFogDensity")
	}

	controls:createDropdown{
		label = "Merge colors:",
		options = {
			{ label = "0. Disabled", value = 0 },
			{ label = "1. Sun to Ambient", value = 1 },
			{ label = "2. Ambient to Sun", value = 2 },
		},
		variable = createConfigVariable("mergeColors"),
		description = [[Default: 0. Disabled. Meant to be only used with shaders requiring sun/ambient interior color to be near 0.
1. Sun to Ambient = when darkening is enabled, if possible decrease interior sun color to 1 and move/merge original sun color to ambient color instead.
2. Ambient to Sun = when darkening is enabled, if possible decrease interior ambient color to 1 and move/merge original ambient color to sun color instead.]],
	}

	controls:createDropdown{
		label = "Logging level:",
		options = {
			{ label = "0. Disabled", value = 0 },
			{ label = "1. Low", value = 1 },
			--[[{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },]]
		},
		variable = createConfigVariable("logLevel"),
		description = "Default: 0. Disabled."
	}

	mwse.mcm.register(template)
	---logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)