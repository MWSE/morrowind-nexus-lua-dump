local logger = require("logging.logger")
local inspect = require("inspect")

local config = require("zoom.config").config
local log = logger.new({
	name = "zoom",
	logLevel = config.logLevel,
})

local faderController = require("zoom.util.faderController")
local util = require("zoom.util")
dofile("zoom.mcm")

local fader = faderController:new()
--- @type tes3inputController
local IC

local function hold()
	if tes3.menuMode() then	return end
	local key = config.zoomKey
	---@type mwseKeyMouseCombo
	local actual = {
		keyCode = IC:isKeyDown(key.keyCode) and key.keyCode,
		mouseButton = IC:isMouseButtonDown(key.mouseButton) and key.mouseButton,
		isAltDown = IC:isAltDown(),
		isControlDown = IC:isControlDown(),
		isShiftDown = IC:isShiftDown()
	}

	local zoom = mge.camera.zoom
	if tes3.isKeyEqual({ actual = actual, expected = key }) then
		if zoom < config.maxZoom then
			fader:activate()
			mge.camera.zoomIn({ amount = config.zoomStrength })
			util.updateDistantLandConfig(zoom)
		end
		return
	else
		if zoom > util.noZoom then
			mge.camera.zoomOut({ amount = config.zoomStrength * 1.5 })
		elseif math.isclose(mge.camera.zoom, util.noZoom) then
			fader:deactivate()
		end
		util.updateDistantLandConfig(zoom)
	end
end

local lastPress = os.clock()
local cooldown = fader.fadeTime + 0.01

---@param e keyDownEventData|mouseButtonDownEventData|mouseWheelEventData
local function press(e)
	if tes3.menuMode() then return end
	---@type mwseKeyMouseCombo
	local actual = {
		keyCode = e.keyCode,
		mouseButton = e.button,
		delta = e.delta,
		isAltDown = IC:isAltDown(),
		isShiftDown = IC:isShiftDown(),
		isControlDown = IC:isControlDown()
	}
	if not tes3.isKeyEqual({ actual = actual, expected = config.zoomKey }) then	return end

	local timePassed = os.clock() - lastPress
	if timePassed < cooldown then return end
	lastPress = os.clock()

	local zoom = mge.camera.zoom
	local zoomIn = (zoom == util.noZoom)
	if zoomIn then
		fader:activate()
		util.zoomIn()
		return
	end

	fader:deactivate()
	util.zoomOut()
end

---@param e mouseWheelEventData
local function mouse(e)
	if tes3.menuMode()
	or IC:keybindTest(tes3.keybind.togglePOV)
	or tes3.getVanityMode()
	or not util.keyModifiersEqual(e, config.zoomKey) then
		return
	end

	local delta = e.delta
	local zoomIn = (delta > 0)
	local mult = math.abs(delta / 120)
	if zoomIn then
		fader:activate()
		mge.camera.zoomIn({
			amount = config.zoomStrength * mult
		})
		util.updateDistantLandConfig(mge.camera.zoom)
	else
		if mge.camera.zoom == util.noZoom then
			fader:deactivate()
		end
		mge.camera.zoomOut({
			amount = config.zoomStrength * mult
		})
		util.updateDistantLandConfig(mge.camera.zoom)
	end
end

local function register()
	if config.zoomType == "hold" then
		event.register(tes3.event.simulate, hold)
	elseif config.zoomType == "press" then
		event.register(tes3.event.keyDown, press)
		event.register(tes3.event.mouseButtonDown, press)
		event.register(tes3.event.mouseWheel, press)
	elseif config.zoomType == "scroll" then
		event.register(tes3.event.mouseWheel, mouse)
	end
end


event.register(tes3.event.initialized, function()
	-- BUG: camera's zoom level isn't changed if not
	-- calling mge.macros.increaseZoom() before.
	-- Maybe need to set mge.camera.zoomEnable = true ?
	mge.macros.increaseZoom()
	mge.macros.decreaseZoom()
	IC = tes3.worldController.inputController
	register()
end)
