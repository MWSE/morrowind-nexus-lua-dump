--[[ 
	Ministry of Clarity
	]]--
	
local function initialized(e)
--	if tes3.isModActive("*.ESP") then
		local radiant = require("MMM2018.radiant.radiant")

		local intervention = require("MMM2018.intervention")
		local cleanse = require("MMM2018.cleanse")
		local statueDebuff = require("MMM2018.statueDebuff")
		local clutter = require("MMM2018.clutter")
		print("[Ministry of Clarity INFO] Initialized Ministry of Clarity")
--	end
end
event.register("initialized", initialized)