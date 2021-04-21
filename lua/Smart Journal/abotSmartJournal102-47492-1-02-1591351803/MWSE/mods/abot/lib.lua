--[[ usage:
local lib = require('abot.lib')

function call e.g. lib.isPlayerScenicTraveling()

--]]
local this = {}

this.scenicTravelAvailable = nil

if tes3.getGlobal('ab01boDest') then
	this.scenicTravelAvailable = true
elseif tes3.getGlobal('ab01ssDest') then
	this.scenicTravelAvailable = true
elseif tes3.getGlobal('ab01goDest') then
	this.scenicTravelAvailable = true
elseif tes3.getGlobal('ab01compMounted') then
	this.scenicTravelAvailable = true
else
	this.scenicTravelAvailable = false
end

-- functions to e.g. avoid heavy/crashy loops on CellChange when player is moving too fast e.g. superjumping
function this.isPlayerScenicTraveling()
	if this.scenicTravelAvailable then
		local v = tes3.getGlobal('ab01boDest')
		if v then
			if v > 0 then
				---mwse.log("%s isPlayerScenicTraveling ab01boDest > 0", modPrefix)
				return true -- if scenic boat traveling
			end
		end
		v = tes3.getGlobal('ab01ssDest')
		if v > 0 then
			if v > 0 then
				---mwse.log("%s isPlayerScenicTraveling ab01ssDest > 0", modPrefix)
				return true -- if scenic strider traveling
			end
		end
		v = tes3.getGlobal('ab01goDest')
		if v then
			if v > 0 then
				---mwse.log("%s isPlayerScenicTraveling ab01goDest > 0", modPrefix)
				return true -- if scenic gondola traveling
			end
		end
		v = tes3.getGlobal('ab01compMounted')
		if v > 0 then
			if v > 0 then
				---mwse.log("%s isPlayerScenicTraveling ab01compMounted > 0", modPrefix)
				return true -- if guar riding
			end
		end
	end
	return false
end

function this.isPlayerMovingFast()
	local mobilePlayer = tes3.mobilePlayer
	if mobilePlayer then
		local velocity = mobilePlayer.velocity
		if velocity then
			if #velocity >= 300 then
				return true
			end
		end
	end
	return false
end

-- MCM functions, a lot stolen from Nullcascade's examples
function this.createBooleanConfig(params)
	local sYes = tes3.findGMST(tes3.gmst.sYes).value
	local sNo = tes3.findGMST(tes3.gmst.sNo).value

	local block = params.parent:createBlock({})
	--block.flowDirection = "left_to_right"
	block.layoutWidthFraction = 1.0
	block.height = 48
	block.childAlignY = 0.5 -- Y centered
	block.paddingAllSides = 4

	local label = block:createLabel({text = params.label})

	local button = block:createButton({text = (params.config[params.key] and sYes or sNo)})
	button.borderTop = 7
	button:register(
		'mouseClick',
		function(e)
			params.config[params.key] = not params.config[params.key]
			button.text = params.config[params.key] and sYes or sNo
			if (params.onUpdate) then
				params.onUpdate(e)
			end
		end
	)
	local info = block:createLabel({text = params.info or ''})

	return {block = block, label = label, button = button, info = info}
end

function this.createSliderConfig(params)
	local block = params.parent:createBlock({})
	block.flowDirection = 'top_to_bottom'
	block.layoutWidthFraction = 1.0
	block.height = 80
	block.childAlignY = 0.5 -- Y centered
	block.paddingAllSides = 4

	local config = params.config
	local key = params.key
	local value = config[key] or params.default or 0

	local label = block:createLabel({text = params.label})

	local sliderLabel = block:createLabel({text = tostring(value)})

	local range = params.max - params.min

	-- NOTE: only integer parameters!
	local slider = block:createSlider({current = value - params.min, max = range, step = params.step, jump = params.jump})
	slider.width = 400
	slider:register(
		'PartScrollBar_changed',
		function(e)
			config[key] = slider:getPropertyInt('PartScrollBar_current') + params.min
			sliderLabel.text = config[key]
			if (params.onUpdate) then
				params.onUpdate(e)
			end
		end
	)
	local info = block:createLabel({text = params.info or ''})

	return {block = block, label = label, sliderLabel = sliderLabel, slider = slider, info = info}
end

function this.createLabelConfig(params)
	local block = params.parent:createBlock({})
	block.flowDirection = 'top_to_bottom'
	block.paddingAllSides = 4
	block.layoutWidthFraction = 1.0
	block.height = 48
	local label = block:createLabel({text = params.label})
	return {block = block, label = label}
end

function this.createMainPane(container)
	-- Create the main pane for a uniform look.
	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = 'top_to_bottom'
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
	mainPane.paddingAllSides = 6
	mainPane.widthProportional = 1.0
	mainPane.heightProportional = 1.0
	return mainPane
end

--[[ trying to make a button to reset configuration work gave me headache... I'll pass for now

function this.resetConfig()
	-- to be overriden as lib.resetConfig()
end

function this.createResetConfig(params)
	local block = params.parent:createBlock({})
	block.flowDirection = "left_to_right"
	block.layoutWidthFraction = 1.0
	block.height = 54
	block.childAlignY = 0.5 -- Y centered
	block.paddingAllSides = 4
	local button = block:createButton({ text = 'Reset to Default' })
	button:register("mouseClick", function(e)
		this.resetConfig()
	end)
	return { block = block, button = button }
end
--]]
-- pattern special characters: ( ) . % + - * ? [ ^ $
local URL_PATTERN = 'https?://[_~a-zA-Z0-9/#\\=&;%.%%%+%-%?]+'

-- return first found URL string in text, or nil
function this.getFirstURL(text_with_URLs)
	local s = string.match(text_with_URLs, URL_PATTERN)
	---mwse.log("abot/lib.lua GetFirstURL = %s", s)
	return s
end

function this.getURLs(text_with_URLs)
	local t = string.gmatch(text_with_URLs, URL_PATTERN)
	--[[
	for k, v in ipairs(t) do
		mwse.log("URLs[%s] = %s", k, v)
	end
	--]]
	return t
end

-- http://dkolf.de/src/dkjson-lua.fsl/wiki?name=Documentation
-- e.g. options = { indent = false, sort = false, keyorder = { '1' = 'alfa', '2' = 'beta' } }

local function getState(options)
	if not options then
		options = {indent = false}
	end
	if options.keyorder then
		if options.sort then
			table.sort(options.keyorder)
		end
		return {indent = options.indent, keyorder = options.keyorder}
	end
	return {indent = options.indent}
end

function this.logConfig(config, options)
	mwse.log(json.encode(config, getState(options)))
end

function this.saveConfig(configName, config, options)
	mwse.saveConfig(configName, config, getState(options))
end
--[[
usage example to try maintaining fucking config tables fields order (or sort them) in fucking json:

local author = 'abot'
local lib = require(author .. '.lib')
-- http://dkolf.de/src/dkjson-lua.fsl/wiki?name=Documentation
local config = {
autoEquipBows = true,
autoEquipBolts = true,
autoEquipThrown = true,
}
local tk = {} -- needed to be able to keep fields order/sort them
tk[1] = 'autoEquipBows'
tk[2] = 'autoEquipBolts'
tk[3] = 'autoEquipThrown'

mwse.log(
	json.encode( config, { indent = true, keyorder = tk })
)
lib.logConfig(config, {indent = true, keyorder = tk, sort = true})
lib.logConfig(config)
lib.saveConfig(configName, config)
lib.saveConfig(configName, config, {keyorder = tk})
--]]
return this
