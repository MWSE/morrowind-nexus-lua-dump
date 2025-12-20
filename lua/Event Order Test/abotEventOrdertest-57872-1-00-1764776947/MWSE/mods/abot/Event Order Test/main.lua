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

local author = 'abot'
local modName = 'Event Order Test'
local modPrefix = author .. '/' .. modName


local evDict = {}

local order = 0

local frmt3 = 'EVENT order: %05d calls %015d %s'
local frmt3nl = frmt3 .. '\n'


--[[
frmt4 is reserved for special fields you want to detect first availability event
e.g. to detect availability of tes3.game you would change
local frmt4 = frmt3 .. ' mwse.simulateTimers = %s'
to
local frmt4 = frmt3 .. ' tes3.game = %s'
and change
mwse.log(frmt4, order, calls, eventType, mwse.simulateTimers)
to
mwse.log(frmt4, order, calls, eventType, tes3.game)
]]
local frmt4 = frmt3 .. ' mwse.simulateTimers = %s'



local frmt5 = frmt3 .. ' tes3.player: "%s" ("%s")'
local checkPlayer = true
local checkfrmt4 = true

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
	---assert(ev_eventType)
	local calls = ev_eventType.c
	---assert(calls)
	calls = calls + 1
	ev_eventType.c = calls
	if not (ev_eventType.o == 0) then
		return
	end
	order = order + 1
	ev_eventType.o = order
	if (not checkPlayer)
	and (not checkfrmt4) then
		mwse.log(frmt3, order, calls, eventType)
		return
	end
	if checkPlayer then
		local player = tes3.player
		if player
		and tes3.isCharGenFinished() then
			local name = player.object.name
			mwse.log(frmt5, order, calls, eventType, player, name)
			checkPlayer = false
		end
	end
	if checkfrmt4 then
		mwse.log(frmt4, order, calls, eventType, mwse.simulateTimers)
		checkfrmt4 = false
	end
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
			table_insert(ev, {o = v.o, c = v.c, e = eventType})
		end
	end

	table.sort(ev, function (a, b) return a.o < b.o end)
	local t = {}
	local v
	for i = 1, #ev do
		v = ev[i]
		t[i] = frmt3nl:format(v.o, v.c, v.e)
	end
	local s = '\nEVENTS so far (by calling order, asc):\n' .. table.concat(t)
	mwse.log(s)

	table.sort(ev, function (a, b) return b.c < a.c end)
	table.clear(t)
	for i = 1, #ev do
		v = ev[i]
		t[i] = frmt3nl:format(v.o, v.c, v.e)
	end
	s = '\nEVENTS so far (by calls number, desc):\n' .. table.concat(t)
	mwse.log(s)

	table.sort(ev, function (a, b) return a.e < b.e end)
	table.clear(t)
	for i = 1, #ev do
		v = ev[i]
		t[i] = frmt3nl:format(v.o, v.c, v.e)
	end
	s = '\nEVENTS so far (by event name, asc):\n' .. table.concat(t)
	mwse.log(s)
end
event.register('keyUp', keyUp, {filter = tes3.scanCode.e})

event.register('initialized', function ()
	local s1 = modPrefix .. ':'
	local s2 = 'quickkey = Ctrl + Alt + E'
	mwse.log(s1 .. ' ' .. s2)
	tes3.messageBox(s1 .. '\n' .. s2)
end, {doOnce = true})