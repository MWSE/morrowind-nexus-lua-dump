--[[
logs to MWSE.log the events order/calls
Probably useful mostly for MWSE-Lua mod-makers/advanced users.

By default this example prints when tes3.player / mwse.simulateTimers are available/not nil
if insterested in something else safe availability, replace e.g. mwse.simulateTimers with your "something else"
as detailed in the frmt4 comments

Ctrl + Alt + E will print all event order/calls so far ordered by:
- calling order
- number of calls
- event name
]]

-- to check for something else availability, replace e.g tes3.worldController with mwse.simulateTimers


local author = 'abot'
local modName = 'Event Order Test'
local modPrefix = author .. '/' .. modName

local evDict = {}

local order = 0

local frmt3 = 'EVENT order: %05d %s calls %015d %s'
local frmt3nl = frmt3 .. '\n'

local frmt4 = frmt3 .. ' tes3.worldController = %s'

local frmt5 = frmt3 .. ' tes3.player: "%s" ("%s")'
local checkPlayer = true
local checkfrmt4 = true

local math_fmod, os_date, os_time = math.fmod, os.date, os.time

local worldController

local function getTimeStr()
	local ms
	if worldController then
		ms = worldController.systemTime
	else
		worldController = tes3.worldController
		if worldController then
			ms = worldController.systemTime
		end
	end
	if ms then
		ms = math_fmod(ms, 1000)
	else
		ms = 0
	end
	return os_date( '%c', os_time() ):sub(12, 19) .. ('.%03d'):format(ms)
end

---@class eventData
---@field eventType string
---@param e eventData
local function evfunc(e)
	local eventType = e.eventType
	---assert(eventType)
	local ev_eventType = evDict[eventType]
	if not ev_eventType then
		mwse.log('%s: evfunc(e) unknown "%s" eventType', modPrefix, eventType)
		return
	end
	local calls = ev_eventType.c
	assert(calls)
	calls = calls + 1
	ev_eventType.c = calls
	local ordr = ev_eventType.o
	assert(ordr)
	if not (ordr == 0) then
		return
	end
	order = order + 1
	ev_eventType.o = order
	local timeStr = getTimeStr()
	ev_eventType.t = timeStr
	if checkPlayer then
		local player = tes3.player
		if player
		and tes3.isCharGenFinished() then
			local name = player.object.name
			checkPlayer = false
			mwse.log(frmt5, order, timeStr, calls, eventType, player, name)
			return
		end
	end
	if checkfrmt4 then
		if tes3.worldController then
			checkfrmt4 = false
			mwse.log(frmt4, order, timeStr, calls, eventType, tes3.worldController)
			return
		end
	end
	mwse.log(frmt3, order, timeStr, calls, eventType)
end

for _, eventType in pairs(tes3.event) do
	evDict[eventType] = {o = 0, c = 0}
	event.register(eventType, evfunc)
end

local table_insert = table.insert

--- @param e keyUpEventData
local function keyUp(e)
	if not e.isAltDown then
		return
	end
	if not e.isControlDown then
		return
	end

	local ev = {}
	for eventType, v in pairs(evDict) do
		if v.c > 0 then
			table_insert(ev, {o = v.o, t = v.t, c = v.c, e = eventType})
		end
	end

	table.sort(ev, function (a, b) return a.o < b.o end)
	local t = {}
	local v
	for i = 1, #ev do
		v = ev[i]
		t[i] = frmt3nl:format(v.o, v.t, v.c, v.e)
	end
	local s = '\nEVENTS so far (by calling order, asc):\n' .. table.concat(t)
	print(s)

	table.sort(ev, function (a, b) return b.c < a.c end)
	table.clear(t)
	for i = 1, #ev do
		v = ev[i]
		t[i] = frmt3nl:format(v.o, v.t, v.c, v.e)
	end
	s = '\nEVENTS so far (by calls number, desc):\n' .. table.concat(t)
	print(s)

	table.sort(ev, function (a, b) return a.e < b.e end)
	table.clear(t)
	for i = 1, #ev do
		v = ev[i]
		t[i] = frmt3nl:format(v.o, v.t, v.c, v.e)
	end
	s = '\nEVENTS so far (by event name, asc):\n' .. table.concat(t)
	print(s)
end
event.register('keyUp', keyUp, {filter = tes3.scanCode.e})

event.register('initialized', function ()
	local s1 = modPrefix .. ':'
	local s2 = 'quickkey = Ctrl + Alt + E'
	mwse.log(s1 .. ' ' .. s2)
	tes3.messageBox(s1 .. '\n' .. s2)
end, {doOnce = true})