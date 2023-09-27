local log = require("logging.logger").getLogger("zoom") --[[@as mwseLogger]]
local config = require("zoom.config").config

---@alias zoommodType
---|  "hold"   # Zoom while the button is held. Zoom out when the button is released.
---|> "press"  # Zoom in when a button is pressed. Zoom out when the button is pressed again.
---|  "scroll" # Zoom on mouse scroll

local distantConfig = {
	default = {},
	multiplier = {
		drawDistance = 1.00,
		aboveWaterFogEnd = 1.00,
		aboveWaterFogStart = 0.60,
		veryFarStaticEnd = 0.95,
		farStaticEnd = 2 / 3,
	},
}

event.register(tes3.event.initialized, function()
	local dlcfg = mge.distantLandRenderConfig
	distantConfig.default = {
		drawDistance = dlcfg.drawDistance,
		aboveWaterFogEnd = dlcfg.aboveWaterFogEnd,
		aboveWaterFogStart = dlcfg.aboveWaterFogStart,
		veryFarStaticEnd = dlcfg.veryFarStaticEnd,
		farStaticEnd = dlcfg.farStaticEnd
	}
end)

--- @param currentZoom number In range of [0 - 1]
local function updateDistantLandConfig(currentZoom)
	if not config.changeDrawDistance then return end
	local max = config.maxDrawDistance
	if distantConfig.default.drawDistance >= max then return end

	local zoomNormalized = (currentZoom - 1) / (config.maxZoom - 1)

	for setting, x in pairs(distantConfig.multiplier) do
		local default = distantConfig.default[setting]
		local r = math.lerp(default, max * x, zoomNormalized)
		mge.distantLandRenderConfig[setting] = r
	end
end

local noZoom = 1.0

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

return {
	keyModifiersEqual = keyModifiersEqual,
	zoomIn = zoomIn,
	zoomOut = zoomOut,
	noZoom = noZoom,
	unregisterIf = unregisterIf,
	reduceFraction = irreducibleFraction,
	updateDistantLandConfig = updateDistantLandConfig,
	distantConfig = distantConfig,
}
