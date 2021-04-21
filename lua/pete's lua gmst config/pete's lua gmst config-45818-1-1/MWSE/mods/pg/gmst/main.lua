local this = {}

-- This is registered only if the hotReloadKey key is set in the config.
local function onKey(e)
	if e.pressed then
		this.loadGMSTs(false)
		tes3.messageBox("GMSTs reloaded.")
	end
end

local function initialized(e)
	local count = this.loadGMSTs(true)
	mwse.log("[pg-gmst]: Initialized %d GMST(s).", count)
end
event.register("initialized", initialized)

function this.loadGMSTs(init)
	local count = 0
	local config = json.loadfile("pg_gmst_config")
	if config then
		-- Set all GMSTs defined in the config, and set the hot reload key if it's in there.
		for k, v in pairs(config) do
			if k == "pg_gmst_hotReloadKey" then
				if init then
					event.register("key", onKey, { filter = v } )
				end
			else
				tes3.getGMST(k).value = v
				count = count + 1
			end
		end
	end
	return count
end