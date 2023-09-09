local log = require("logging.logger").getLogger("zoom") --[[@as mwseLogger]]
local config = require("zoom.config").config

---@alias zoommodType
---|  "hold"   # Zoom while the button is held. Zoom out when the button is released.
---|> "press"  # Zoom in when a button is pressed. Zoom out when the button is pressed again.
---|  "scroll" # Zoom on mouse scroll

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

return {
	keyModifiersEqual = keyModifiersEqual,
	zoomIn = zoomIn,
	zoomOut = zoomOut,
	noZoom = noZoom,
	unregisterIf = unregisterIf,
}
