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

local function hold()
	if tes3.menuMode() then	return end

	local IC = tes3.worldController.inputController
	local keyDown = IC:isKeyDown(config.zoomKey.keyCode)
	local e = {
		isAltDown = IC:isKeyDown(tes3.scanCode.lAlt) or IC:isKeyDown(tes3.scanCode.rAlt),
		isControlDown = IC:isKeyDown(tes3.scanCode.lCtrl) or IC:isKeyDown(tes3.scanCode.rCtrl),
		isShiftDown = IC:isKeyDown(tes3.scanCode.lShift) or IC:isKeyDown(tes3.scanCode.rShift)
	}
	local keyComboDown = keyDown and util.keyModifiersEqual(e, config.zoomKey)

	if keyComboDown then
		if mge.camera.zoom < config.maxZoom then
			fader:activate()
			mge.camera.zoomIn({ amount = config.zoomStrength })
		end
		return
	else
		if mge.camera.zoom > util.noZoom then
			mge.camera.zoomOut({ amount = config.zoomStrength * 1.5 })
		elseif math.isclose(mge.camera.zoom, util.noZoom) then
			fader:deactivate()
		end
	end
end

local lastPress = os.clock()
local cooldown = fader.fadeTime + 0.01

---@param e keyDownEventData
local function press(e)
	if tes3.menuMode()
	or not util.keyModifiersEqual(e, config.zoomKey) then
		return
	end

	local timePassed = os.clock() - lastPress
	if timePassed < cooldown then return end
	lastPress = os.clock()

	local zoomIn = (mge.camera.zoom == util.noZoom)
	if zoomIn then
		fader:activate()
		util.zoomIn()
	else
		fader:deactivate()
		util.zoomOut()
	end
end

---@param e mouseWheelEventData
local function mouse(e)
	if tes3.menuMode()
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
	else
		if mge.camera.zoom == util.noZoom then
			fader:deactivate()
		end
		mge.camera.zoomOut({
			amount = config.zoomStrength * mult
		})
	end
end

local function register()
	if config.zoomType == "hold" then
		event.register(tes3.event.simulate, hold)
	elseif config.zoomType == "press" then
		event.register(tes3.event.keyDown, press, { filter = config.zoomKey.keyCode })
	elseif config.zoomType == "scroll" then
		event.register(tes3.event.mouseWheel, mouse)
	end
end


event.register(tes3.event.initialized, function()
	-- BUG: camera's zoom level isn't changed if not
	-- calling mge.macros.increaseZoom() before.
	mge.macros.increaseZoom()
	mge.macros.decreaseZoom()
	register()
end)
