local core    = require('openmw.core')
local menu    = require('openmw.menu')
local storage = require('openmw.storage')
local async   = require('openmw.async')

local ok, bypass = pcall(select, "sandbox.bypass")
if not ok then return end

local ipc = require('scripts.DiscordRPC.ipc')
local cfg = require('scripts.DiscordRPC.disc_config')

local os_real, get_pid
do
	if type(bypass) == "table" then
		os_real = bypass.os
		local ffi = bypass.ffi
		if ffi then
			pcall(function()
				if ipc.os == "Windows" then
					ffi.cdef[[ uint32_t GetCurrentProcessId(void); ]]
					get_pid = function() return tonumber(ffi.C.GetCurrentProcessId()) end
				else
					ffi.cdef[[ int getpid(void); ]]
					get_pid = function() return tonumber(ffi.C.getpid()) end
				end
			end)
		end
	end
end

-- ------------------------------ config ------------------------------

local MARKER   = "[DiscordRPC]"
local INTERVAL = 4
local PIPE     = "discord-ipc-0"
local SECTION  = "DiscordRPC"

local CLIENT_ID     = cfg.CLIENT_ID or ""
local APP_NAME      = cfg.APP_NAME or ""
local DEFAULT_IMAGE = cfg.DEFAULT_IMAGE or ""

local sessionStart = (os_real and os_real.time()) or 0
local pid          = (get_pid and get_pid()) or 0
local presence     = storage.playerSection(SECTION)

-- ------------------------------ state ------------------------------

local conn        = nil
local lastEmitted = ""
local nonceN      = 0
local lastTick    = -INTERVAL

-- ------------------------------ json ------------------------------

local function jsonEscape(s)
	return (s or ""):gsub('\\', '\\\\'):gsub('"', '\\"')
end

local function jsonStr(s)
	return '"' .. jsonEscape(s) .. '"'
end

local function jsonObj(pairs)
	local out = {}
	for _, p in ipairs(pairs) do
		out[#out + 1] = string.format('"%s":%s', p[1], p[2])
	end
	return "{" .. table.concat(out, ",") .. "}"
end

-- ------------------------------ activity ------------------------------

local function buildActivity(p)
	local activityPairs = {}
	if APP_NAME ~= "" then
		activityPairs[#activityPairs + 1] = {"name", jsonStr(APP_NAME)}
	end
	activityPairs[#activityPairs + 1] = {"details", jsonStr(p.details)}
	if p.state and p.state ~= "" then
		activityPairs[#activityPairs + 1] = {"state", jsonStr(p.state)}
	end

	if sessionStart > 0 then
		activityPairs[#activityPairs + 1] = {"timestamps",
			jsonObj({ {"start", tostring(sessionStart)} })}
	end

	if p.image and p.image ~= "" then
		local assetPairs = { {"large_image", jsonStr(p.image)} }
		local text = (p.tooltip and p.tooltip ~= "") and p.tooltip or APP_NAME
		if text ~= "" then
			assetPairs[#assetPairs + 1] = {"large_text", jsonStr(text)}
		end
		activityPairs[#activityPairs + 1] = {"assets", jsonObj(assetPairs)}
	end

	return jsonObj(activityPairs)
end

-- ------------------------------ discord ipc ------------------------------

local function le32(n)
	return string.char(n % 256, math.floor(n / 256) % 256,
		math.floor(n / 65536) % 256, math.floor(n / 16777216) % 256)
end

local function sendFrame(op, payload)
	return conn:write(le32(op) .. le32(#payload) .. payload)
end

-- read one frame, discard the opcode, return the body (or nil,err)
local function readFrame()
	local h, err = conn:read(8)
	if not h then return nil, err end
	local len = h:byte(5) + h:byte(6) * 256 + h:byte(7) * 65536 + h:byte(8) * 16777216
	if len == 0 then return "" end
	return conn:read(len)
end

local function disconnect()
	if conn then conn:close(); conn = nil end
end

-- connect to the pipe and handshake
local function connect()
	disconnect()
	local c, err = ipc.connect_pipe(PIPE, 1000)
	if not c then return false, err end
	conn = c
	-- handshake: opcode 0, v is numeric
	if not sendFrame(0, jsonObj({ {"v", "1"}, {"client_id", jsonStr(CLIENT_ID)} })) then
		disconnect(); return false, "handshake write failed"
	end
	local reply, rerr = readFrame() -- discord's READY dispatch
	if not reply then disconnect(); return false, rerr end
	print(MARKER .. " connected (client_id=" .. CLIENT_ID .. ")")
	return true
end

local function nextNonce()
	nonceN = nonceN + 1
	return tostring(sessionStart) .. "-" .. nonceN
end

-- ------------------------------ emit ------------------------------

local function currentPresence()
	if menu.getState() == menu.STATE.Running then
		return presence:get("activity")
	end
	return { details = "In Main Menu", state = "", image = DEFAULT_IMAGE, tooltip = "" }
end

local function emit()
	local p = currentPresence()
	if not p then return end

	-- (re)connect on demand
	if not conn then
		if not connect() then return end
		lastEmitted = ""
	end

	local activity = buildActivity(p)
	if activity == lastEmitted then return end

	local payload = jsonObj({
		{"cmd",   jsonStr("SET_ACTIVITY")},
		{"nonce", jsonStr(nextNonce())},
		{"args",  jsonObj({
			{"pid",      tostring(pid)},
			{"activity", activity},
		})},
	})

	if not sendFrame(1, payload) then disconnect(); return end
	if not readFrame()         then disconnect(); return end
	lastEmitted = activity
end

-- ------------------------------ events ------------------------------

local function onFrame()
	local now = core.getRealTime()
	if now - lastTick < INTERVAL then return end
	lastTick = now
	emit()
end

-- player bridge
presence:subscribe(async:callback(emit))

return {
	engineHandlers = {
		onFrame = onFrame,
		onStateChanged = emit,
	},
}
