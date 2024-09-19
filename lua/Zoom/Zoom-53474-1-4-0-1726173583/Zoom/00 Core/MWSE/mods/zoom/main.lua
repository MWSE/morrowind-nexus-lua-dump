local logger = require("logging.logger")

local config = require("zoom.config").config
local log = logger.new({
	name = "zoom",
	logLevel = config.logLevel,
})

local faderController = require("zoom.util.faderController")
local util = require("zoom.util")
dofile("zoom.mcm")

local menuOptionsID = "MenuOptions"
local MCMButtonID = "MenuOptions_MCM_container"
local MCMID = "MWSE:ModConfigMenu"
local MGEXEoptionsMenuID = "MenuMGE-XE"

local fader = faderController:new()
--- @type tes3inputController
local IC


local function hold()
	if tes3.menuMode() then return end
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
	if tes3.isKeyEqual({ actual = actual, expected = key }) and util.hasTelescope() then
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
	if tes3.menuMode()
	or not tes3.isKeyEqual({ actual = e, expected = config.zoomKey }) then
		return
	end

	local timePassed = os.clock() - lastPress
	if timePassed < cooldown then return end
	lastPress = os.clock()

	local zoom = mge.camera.zoom
	local zoomIn = (zoom == util.noZoom)
	if zoomIn and util.hasTelescope() then
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
	-- Prevent zooming when changing the camera distance in the 3rd person view
	or IC:keybindTest(tes3.keybind.togglePOV)
	or tes3.getVanityMode()
	or not util.keyModifiersEqual(e, config.zoomKey) then
		return
	end

	local delta = e.delta
	local zoomIn = (delta > 0)
	local mult = math.exp(math.abs(delta / 120) * config.zoomStrength) - util.noZoom
	if zoomIn and util.hasTelescope() then
		fader:activate()
		mge.camera.zoomIn({
			amount = mult
		})
		util.updateDistantLandConfig(mge.camera.zoom)
	else
		if mge.camera.zoom == util.noZoom then
			fader:deactivate()
		end
		mge.camera.zoomOut({
			amount = mult
		})
		util.updateDistantLandConfig(mge.camera.zoom)
	end
end

local function endZoom()
	fader:deactivateInstant()
	mge.camera.zoom = util.noZoom
	util.updateDistantLandConfig(util.noZoom)
end

event.register(tes3.event.load, endZoom)
event.register(tes3.event.uiActivated, endZoom, { filter = menuOptionsID })

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
	-- Make sure to enable zoom, because mge.camera.zoomIn doesn't do that automatically
	mge.camera.zoomEnable = true
	IC = tes3.worldController.inputController
	register()
end)

local function onMGEXEOptions()
	local mgexeMenu = tes3ui.findMenu(MGEXEoptionsMenuID)
	if not mgexeMenu then
		return
	end
	mgexeMenu:registerAfter(tes3.uiEvent.destroy, function()
		event.trigger("Zoom:MGEXE-options")
	end)
end

-- Monitor if MGE XE distant land settings were changed
---@param e uiActivatedEventData
local function onOptionsCreated(e)
	e.element:findChild(MCMButtonID):registerAfter(tes3.uiEvent.mouseClick, function()
		local menu = tes3ui.findMenu(MCMID)
		if not menu then
			return
		end
		menu:registerAfter(tes3.uiEvent.destroy, function()
			timer.delayOneFrame(onMGEXEOptions, timer.real)
		end)
	end)
end
event.register(tes3.event.uiActivated, onOptionsCreated, { filter = menuOptionsID })
