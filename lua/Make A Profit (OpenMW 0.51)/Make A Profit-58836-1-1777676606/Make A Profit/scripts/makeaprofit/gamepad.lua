local core = require('openmw.core')

local Gamepad = {}
local lastPress = nil
local handlers = {}
local heldButtons = {}
local INITIAL_DELAY   = 0.33
local REPEAT_INTERVAL = 0.05

local function dispatch(id, isRepeat)
	local snapshot = {}
	for i, fn in ipairs(handlers) do snapshot[i] = fn end
	for _, fn in ipairs(snapshot) do
		fn(id, isRepeat)
	end
end

function Gamepad.onButtonPress(id)
	local now = core.getRealTime()
	lastPress = now
	heldButtons[id] = now + INITIAL_DELAY
	dispatch(id, false)
end

function Gamepad.onButtonRelease(id)
	heldButtons[id] = nil
end

function Gamepad.tick()
	if not next(heldButtons) then return end
	local now = core.getRealTime()
	local ids = {}
	for id, nextRep in pairs(heldButtons) do
		if now >= nextRep then ids[#ids + 1] = id end
	end
	for _, id in ipairs(ids) do
		if heldButtons[id] then
			heldButtons[id] = now + REPEAT_INTERVAL
			lastPress = now
			dispatch(id, true)
		end
	end
end

function Gamepad.wasRecentlyActive(seconds)
	if not lastPress then return false end
	return (core.getRealTime() - lastPress) <= (seconds or 60)
end

function Gamepad.register(fn)
	table.insert(handlers, fn)
end

function Gamepad.unregister(fn)
	for i = #handlers, 1, -1 do
		if handlers[i] == fn then
			table.remove(handlers, i)
		end
	end
end

return Gamepad
