--[[
	Plugin: Frostwind.esp
--]]
function onLoaded(e)
	-- set global to disable mwscripts
	tes3.setGlobal("a_lua_enabled", 1)
end

local lfs = require("lfs")

-- Ensure we don't have an old version installed.
if (lfs.attributes("Data Files/MWSE/lua/mer/Frostwind/")) then
    if (lfs.rmdir("Data Files/MWSE/lua/mer/Frostwind", true)) then
        mwse.log("[Frostwind INFO] Old install found and deleted.")

        -- Additional, probably not necessarily cleanup. It will only delete these if they are empty.
        lfs.rmdir("Data Files/MWSE/lua/mer")
    else	
        mwse.log("[Frostwind ERROR] Old install found but could not be deleted. Please remove the folder 'Data Files/MWSE/lua/mer/Frostwind' and restart Morrowind.")
        return
    end
end



local function initialized(e)
	if tes3.isModActive("Frostwind.ESP") then
		event.register("loaded", onLoaded)
		-- load modules
		local common = require("mer.Frostwind.common")
		local harvest_wood = require("mer.Frostwind.harvest_wood")
		print("[Frostwind INFO] Initialized Frostwind")
	end
end
event.register("initialized", initialized)
