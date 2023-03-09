-- Util module
-->>>---------------------------------------------------------------------------------------------<<<--

local util = {}

local config = require("tew.Vapourmist.config")
local modversion = require("tew.Vapourmist.version")
local VERSION = modversion.version

-- Print debug messages --
function util.debugLog(message)
	if config.debugLogOn then
		if not message then message = "n/a" end
		message = tostring(message)
		local info = debug.getinfo(2, "Sl")
		local module = info.short_src:match("^.+\\(.+).lua$")
		local prepend = ("[Vapourmist.%s.%s:%s]:"):format(VERSION, module, info.currentline)
		local aligned = ("%-36s"):format(prepend)
		mwse.log(aligned .. " -- " .. string.format("%s", message))
	end
end

return util