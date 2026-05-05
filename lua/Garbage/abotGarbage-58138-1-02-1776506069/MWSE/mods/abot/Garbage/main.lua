--[[
my simple take at improving garbage collection:
collect MWSE-Lua garbage memory when it counts
and it does not cause much noticeable extra framerate hiccups,
because things are slow already (loading, saving, closing MCM menu options)
]]

local logOn = true -- change to false to skip logging



local total = 0 -- total garbace recovered since game start

local fmt = 'abot\\Garbage: %s collected Lua garbage memory = %s, total = %s'
local memBytesUsedByLua1, memBytesUsedByLua2, memBytesUsedByLua3, diff

---@param prefix string?
local function collectedGarbage(prefix, double)
	if not logOn then
		collectgarbage()
		if double then
			collectgarbage()
		end
		return
	end
	if not prefix then
		prefix = ''
	end
	memBytesUsedByLua1 = collectgarbage('count')
	collectgarbage()
	memBytesUsedByLua2 = collectgarbage('count')
	diff = (memBytesUsedByLua1 - memBytesUsedByLua2) * 1024
	total = total + diff
	mwse.log(fmt, prefix, diff, total)
	if not double then
		return
	end
	collectgarbage() -- 2nd call is not as good as 1st one, but still worth
	memBytesUsedByLua3 = collectgarbage('count')
	diff = (memBytesUsedByLua2 - memBytesUsedByLua3) * 1024
	total = total + diff
	mwse.log(fmt, prefix, diff, total)
end

-- should help with MCM panel memory hogs out there
---@param e modConfigEntryClosedEventData
local function modConfigEntryClosed(e)
-- here we want double = true
	collectedGarbage(e.modName, true)
end
event.register('modConfigEntryClosed', modConfigEntryClosed, {priority = -2^53})


local function collectedGarbagePrefixed(e, double)
---@diagnostic disable-next-line: undefined-field
	local prefix = e.eventType
	if prefix then
		prefix = prefix..'()'
	end
	collectedGarbage(prefix, double)
end

---@param e loadEventData
local function onLoad(e)
	if e.block then
		return
	end
	-- if loading is confirmed, try to make space before loading the next crashing Balmora
	collectedGarbagePrefixed(e)
end
event.register('load', onLoad, {priority = -2^53}) -- try to run it last


---@param e loadedEventData
local function loaded(e)
	-- just loaded, can't hurt and player is not going to notice much
	collectedGarbagePrefixed(e)
end
event.register('loaded', loaded, {priority = -2^53})


---@param e saveEventData
local function save(e)
	---if e.block then
		---return
	---end
-- can't hurt even if save is blocked
-- as periodically doing it on blocked autosaves tries
-- is probably still worth
---@diagnostic disable-next-line: undefined-field
	collectedGarbagePrefixed(e)
end
event.register('save', save, {priority = 2^53}) -- try to run it first before being possibly blocked
