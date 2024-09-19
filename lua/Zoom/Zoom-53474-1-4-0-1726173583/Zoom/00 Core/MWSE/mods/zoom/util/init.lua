local log = require("logging.logger").getLogger("zoom") --[[@as mwseLogger]]
local config = require("zoom.config").config

---@alias zoommodType
---|  "hold"   # Zoom while the button is held. Zoom out when the button is released.
---|> "press"  # Zoom in when a button is pressed. Zoom out when the button is pressed again.
---|  "scroll" # Zoom on mouse scroll

-- The zoom level when there is no zooming
local noZoom = 1.0

local settings = {
	sensitivity = {},
	-- Distant land
	dl = {
		default = {},
		multiplier = {
			drawDistance = 1.00,
			aboveWaterFogEnd = 1.00,
			aboveWaterFogStart = 0.60,
			veryFarStaticEnd = 0.95,
			farStaticEnd = 2 / 3,
		},
	}
}

local menuControlsID = "MenuCtrls"

local function saveMouseSensitivity()
	settings.sensitivity.x = tes3.worldController.mouseSensitivityX
	settings.sensitivity.y = tes3.worldController.mouseSensitivityY
end

local function saveDistantLandConfig()
	local dlcfg = mge.distantLandRenderConfig
	settings.dl.default = {
		drawDistance = dlcfg.drawDistance,
		aboveWaterFogEnd = dlcfg.aboveWaterFogEnd,
		aboveWaterFogStart = dlcfg.aboveWaterFogStart,
		veryFarStaticEnd = dlcfg.veryFarStaticEnd,
		farStaticEnd = dlcfg.farStaticEnd
	}
end

event.register(tes3.event.uiActivated, function(e)
	e.element:registerAfter(tes3.uiEvent.destroy, saveMouseSensitivity)
end, { filter = menuControlsID })

event.register(tes3.event.initialized, function()
	saveDistantLandConfig()
	saveMouseSensitivity()
end)

event.register("Zoom:MGEXE-options", function ()
	saveDistantLandConfig()
end)

local function getDefaultDrawDistance()
	return settings.dl.default.drawDistance
end

local function undoMouseSensitivityScale()
	tes3.worldController.mouseSensitivityX = settings.sensitivity.x * mge.camera.zoom
	tes3.worldController.mouseSensitivityY = settings.sensitivity.y * mge.camera.zoom
end

--- @param currentZoom number
local function updateDistantLandConfig(currentZoom)
	if not config.changeDrawDistance then return end
	local max = config.maxDrawDistance + settings.dl.default.drawDistance
	if settings.dl.default.drawDistance >= max then return end

	local zoomNormalized = (currentZoom - 1) / (config.maxZoom - 1)

	for setting, x in pairs(settings.dl.multiplier) do
		local default = settings.dl.default[setting]
		local r = math.lerp(default, max * x, zoomNormalized)
		mge.distantLandRenderConfig[setting] = r
	end

	-- undoMouseSensitivityScale()
end

--- Starts a timer for zooming with given callback.
---@param callback fun(e: mwseTimerCallbackData)
local function startZoomTimer(callback)
	timer.start({
		type = timer.simulate,
		duration = 0.02,
		iterations = -1,
		callback = callback,
	})
end

--- Smoothly zooms in up to `maxZoom` setting amount.
local function zoomIn()
	startZoomTimer(function(e)
		if mge.camera.zoom >= config.maxZoom then
			e.timer:cancel()
			return
		end
		mge.camera.zoomIn({ amount = config.zoomStrength })
		updateDistantLandConfig(mge.camera.zoom)
	end)
end

--- Smoothly zooms out completely.
local function zoomOut()
	mge.camera.stopZoom()
	startZoomTimer(function(e)
		if mge.camera.zoom == noZoom then
			e.timer:cancel()
			return
		end
		mge.camera.zoomOut({ amount = config.zoomStrength * 1.5 })
		updateDistantLandConfig(mge.camera.zoom)
	end)
end

--- Returns true if the two given key combos have equal alt, control and shift states.
---@param e mouseWheelEventData|keyDownEventData
---@param key table
---@return boolean equal
local function keyModifiersEqual(e, key)
	if e.isAltDown == key.isAltDown
	and e.isControlDown == key.isControlDown
	and e.isShiftDown == key.isShiftDown then
		return true
	end
	return false
end

--- This function unregisters an event callback if it was registered.
---@param eventId string The event id. Maps to tes3.event table.
---@param callback function
---@param options table?
local function unregisterIf(eventId, callback, options)
	if event.isRegistered(eventId, callback, options) then
		event.unregister(eventId, callback, options)
	end
end

-- Euclidean algorithm
local function gcd(a, b)
	while b ~= 0 do
		local c = b
		b = a % b
		a = c
	end
	return a
end

local function irreducibleFraction(a, b)
	local gcd = gcd(a, b)
	return a / gcd, b / gcd
end

local data = {
	telescopeRequired = false,
	---@type table<string, Zoom.telescopeData>
	telescopes = {}
}

--- @class Zoom.telescopeData
--- @field id string

--- @param telescopeData Zoom.telescopeData
local function registerTelescope(telescopeData)
	local id = string.lower(telescopeData.id)
	-- Check if we have it registered already
	for _, telescope in ipairs(data.telescopes) do
		if telescope.id == id then
			log:warn("Attempting to register already registered telescope %q. Traceback: %s",
				telescopeData.id, debug.traceback())
			return
		end
	end
	data.telescopes[id] = table.copy(telescopeData)
end

--- @param telescopesData Zoom.telescopeData[]
local function registerTelescopes(telescopesData)
	assert(type(telescopesData) == "table", "telescopesData needs to be an array")
	for _, telescope in ipairs(telescopesData) do
		registerTelescope(telescope)
	end
end

--- @param required boolean
local function setTelescopeRequired(required)
	data.telescopeRequired = required
end

local function getTelescopeRequired()
	return data.telescopeRequired
end

local function hasTelescope()
	if not data.telescopeRequired then
		return true
	end
	for _, stack in ipairs(tes3.mobilePlayer.inventory) do
		local id = string.lower(stack.object.id)
		if data.telescopes[id] then
			return true
		end
	end
	return false
end

return {
	keyModifiersEqual = keyModifiersEqual,
	zoomIn = zoomIn,
	zoomOut = zoomOut,
	noZoom = noZoom,
	unregisterIf = unregisterIf,
	reduceFraction = irreducibleFraction,
	updateDistantLandConfig = updateDistantLandConfig,
	getDefaultDrawDistance = getDefaultDrawDistance,
	hasTelescope = hasTelescope,
	getTelescopeRequired = getTelescopeRequired,
	setTelescopeRequired = setTelescopeRequired,
	registerTelescope = registerTelescope,
	registerTelescopes = registerTelescopes,
}
